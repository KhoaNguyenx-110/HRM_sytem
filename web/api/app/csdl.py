"""Pool kết nối HRM_APP và vòng đời danh tính phiên (đặc tả mục 8.1, kênh 1).

Mỗi request có người dùng đi theo đúng trình tự:
    lấy kết nối từ pool
    -> pkg_ctx.dat_phien(tai_khoan_id)   CSDL đọc lại trạng thái + vai trò từ bảng
    -> xử lý (gọi package / đọc view)
    -> commit (endpoint ghi tự gọi) hoặc rollback
    -> FINALLY: rollback phần chưa commit, pkg_ctx.xoa_phien, trả kết nối về pool
Bước finally là điều kiện để người dùng sau không "thừa hưởng" danh tính người
trước khi dùng lại cùng một kết nối (kiểm thử: tests/test_pool.py).

Quyền thật sự nằm trong CSDL: backend không tự kiểm tra vai trò.
"""
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import oracledb

from .cau_hinh import SCHEMA, CauHinh

_pool: oracledb.AsyncConnectionPool | None = None


def tao_pool(ch: CauHinh) -> oracledb.AsyncConnectionPool:
    global _pool
    # Chế độ thin: không cần cài Oracle Client trên máy chạy backend
    _pool = oracledb.create_pool_async(
        user="hrm_app", password=ch.hrm_app_password, dsn=ch.dsn,
        min=ch.pool_min, max=ch.pool_max, increment=1,
    )
    return _pool


async def dong_pool() -> None:
    global _pool
    if _pool is not None:
        await _pool.close(force=True)
        _pool = None


def pool() -> oracledb.AsyncConnectionPool:
    if _pool is None:
        raise RuntimeError("Pool chưa được tạo")
    return _pool


async def goi(conn: oracledb.AsyncConnection, ten: str, tham_so: list | None = None) -> None:
    """Gọi procedure HRM_OWNER.<ten> (vd 'pkg_ctx.xoa_phien')."""
    async with conn.cursor() as cur:
        await cur.callproc(f"{SCHEMA}.{ten}", tham_so or [])


async def xoa_danh_tinh(conn: oracledb.AsyncConnection) -> None:
    """Hủy giao dịch dở dang và xóa HRM_CTX trước khi trả kết nối về pool."""
    await conn.rollback()
    await goi(conn, "pkg_ctx.xoa_phien")


async def _tra_ve_pool(conn: oracledb.AsyncConnection) -> None:
    """Xóa danh tính rồi trả kết nối. Không xóa được (vd kết nối đứt) thì LOẠI
    kết nối khỏi pool: tuyệt đối không trả lại một kết nối còn danh tính cũ."""
    try:
        await xoa_danh_tinh(conn)
    except Exception:
        await pool().drop(conn)
        raise
    await pool().release(conn)


@asynccontextmanager
async def ket_noi_an_danh() -> AsyncIterator[oracledb.AsyncConnection]:
    """Kết nối KHÔNG có danh tính: chỉ dùng cho bước đăng nhập (pkg_auth)."""
    conn = await pool().acquire()
    try:
        yield conn
    finally:
        await _tra_ve_pool(conn)


@asynccontextmanager
async def ket_noi_nguoi_dung(tai_khoan_id: int) -> AsyncIterator[oracledb.AsyncConnection]:
    """Kết nối mang danh tính tài khoản đã xác thực bằng token."""
    conn = await pool().acquire()
    try:
        # dat_phien tự xóa danh tính cũ trước; tài khoản KHOA -> ORA-20001
        await goi(conn, "pkg_ctx.dat_phien", [tai_khoan_id])
        yield conn
    finally:
        await _tra_ve_pool(conn)
