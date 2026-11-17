"""Danh mục qua SP-29 pkg_danh_muc (bảng gốc: HRM_APP không có quyền SELECT)."""
from typing import Literal

from fastapi import APIRouter

from ..cau_hinh import SCHEMA
from ..phu_thuoc import CON_TRO, PhienCSDL

router = APIRouter(prefix="/api/danh-muc", tags=["danh mục"])

LoaiDanhMuc = Literal["PHONG_BAN", "CHUC_VU", "LOAI_NGHI_PHEP", "LICH_LAM_VIEC",
                      "LOAI_HOP_DONG", "LOAI_KHOAN_LUONG", "KY_LUONG", "VAI_TRO"]


async def doc_danh_muc(conn, loai: str, nam: int | None = None) -> list[dict]:
    # sp_tra_danh_muc(p_loai, o_ket_qua OUT, p_nam): tham số OUT nằm GIỮA nên gọi trực tiếp
    async with conn.cursor() as cur:
        rc = cur.var(CON_TRO)
        await cur.callproc(f"{SCHEMA}.pkg_danh_muc.sp_tra_danh_muc", [loai, rc, nam])
        con_tro = rc.getvalue()
        cot = [d[0].lower() for d in con_tro.description]
        return [dict(zip(cot, d)) for d in await con_tro.fetchall()]


@router.get("/{loai}")
async def danh_muc(loai: LoaiDanhMuc, conn: PhienCSDL, nam: int | None = None):
    return await doc_danh_muc(conn, loai, nam)
