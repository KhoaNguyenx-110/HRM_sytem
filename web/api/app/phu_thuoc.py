"""Phụ thuộc FastAPI dùng chung: kết nối theo người dùng và hàm đọc/gọi CSDL."""
from collections.abc import AsyncIterator
from typing import Annotated, Any

import oracledb
from fastapi import Depends, Request

from .bao_mat import doc_token
from .cau_hinh import SCHEMA
from .csdl import ket_noi_nguoi_dung

# CLOB/JSON trả thẳng về str/dict thay vì đối tượng LOB
oracledb.defaults.fetch_lobs = False

# Kiểu biến OUT dùng trong goi_tra_ve
SO, CHUOI, CLOB, CON_TRO = int, str, oracledb.DB_TYPE_CLOB, oracledb.DB_TYPE_CURSOR


async def phien_csdl(request: Request) -> AsyncIterator[oracledb.AsyncConnection]:
    """Token hợp lệ -> kết nối đã gắn danh tính; kết thúc request luôn xóa danh tính."""
    tai_khoan_id, _ = doc_token(request)
    async with ket_noi_nguoi_dung(tai_khoan_id) as conn:
        yield conn


PhienCSDL = Annotated[oracledb.AsyncConnection, Depends(phien_csdl)]


async def doc_dong(conn: oracledb.AsyncConnection, sql: str, tham_so: dict | None = None) -> list[dict[str, Any]]:
    """Chạy SELECT, trả danh sách dict với tên cột viết thường."""
    async with conn.cursor() as cur:
        await cur.execute(sql, tham_so or {})
        cot = [d[0].lower() for d in cur.description]
        return [dict(zip(cot, dong)) for dong in await cur.fetchall()]


async def doc_view(conn, view: str, dieu_kien: str = "", tham_so: dict | None = None,
                   sap_xep: str = "", gioi_han: int = 1000) -> list[dict[str, Any]]:
    """Đọc một view VW-xx. Phạm vi dòng do chính view quyết định (HRM_CTX);
    dieu_kien chỉ là bộ lọc người dùng chọn, luôn dùng biến bind."""
    sql = f"select * from {SCHEMA}.{view}"
    if dieu_kien:
        sql += f" where {dieu_kien}"
    if sap_xep:
        sql += f" order by {sap_xep}"
    sql += f" fetch first {int(gioi_han)} rows only"
    return await doc_dong(conn, sql, tham_so)


async def goi_tra_ve(conn, ten: str, vao: list, ra: list) -> list:
    """Gọi HRM_OWNER.<ten>(vao..., ra...) và trả giá trị các tham số OUT.
    ra = danh sách kiểu (SO, CHUOI, CLOB, CON_TRO); CLOB đọc thành str,
    con trỏ đọc thành danh sách dict."""
    async with conn.cursor() as cur:
        bien = [cur.var(k) for k in ra]
        await cur.callproc(f"{SCHEMA}.{ten}", list(vao) + bien)
        kq = []
        for k, b in zip(ra, bien):
            v = b.getvalue()
            if k is CLOB and v is not None:
                v = await v.read()
            elif k is CON_TRO and v is not None:
                cot = [d[0].lower() for d in v.description]
                v = [dict(zip(cot, d)) for d in await v.fetchall()]
            kq.append(v)
        return kq
