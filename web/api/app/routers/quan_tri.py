"""Quản trị tài khoản (R_ADMIN) và nhật ký hệ thống (VW-10, chia theo vai trò).

Admin không xem được hồ sơ/lương (TC-08): danh bạ tối thiểu lấy từ VW-13.
Mật khẩu ban đầu do Admin nhập được băm ở backend; CSDL chỉ nhận chuỗi băm.
"""
import asyncio

from fastapi import APIRouter
from pydantic import BaseModel, Field

from ..bao_mat import bam_mat_khau, kiem_tra_mat_khau_moi
from ..csdl import goi
from ..phu_thuoc import SO, PhienCSDL, doc_view, goi_tra_ve

router = APIRouter(prefix="/api", tags=["quản trị"])


@router.get("/tai-khoan")
async def tai_khoan(conn: PhienCSDL):
    """VW-09."""
    return await doc_view(conn, "vw_tai_khoan_quan_tri", sap_xep="ten_dang_nhap")


@router.get("/danh-ba")
async def danh_ba(conn: PhienCSDL):
    """VW-13: đủ để cấp tài khoản, không có lương hay định danh."""
    return await doc_view(conn, "vw_danh_ba_nhan_vien", sap_xep="ma_nhan_vien")


class TaiKhoanMoi(BaseModel):
    ten_dang_nhap: str = Field(min_length=3, max_length=50)
    mat_khau_tam: str
    ma_nhan_vien: str | None = None          # NULL = tài khoản kỹ thuật


@router.post("/tai-khoan", status_code=201)
async def tao_tai_khoan(tk: TaiKhoanMoi, conn: PhienCSDL):
    kiem_tra_mat_khau_moi(tk.mat_khau_tam)
    bam = await asyncio.to_thread(bam_mat_khau, tk.mat_khau_tam)
    (tk_id,) = await goi_tra_ve(conn, "pkg_admin.sp_tao_tai_khoan",
                                [tk.ten_dang_nhap.strip().lower(), bam, tk.ma_nhan_vien, None], [SO])
    await conn.commit()
    return {"tai_khoan_id": tk_id}


@router.post("/tai-khoan/{ten}/khoa")
async def khoa(ten: str, conn: PhienCSDL):
    await goi(conn, "pkg_admin.sp_khoa_tai_khoan", [ten])
    await conn.commit()
    return {"ok": True}


@router.post("/tai-khoan/{ten}/mo")
async def mo(ten: str, conn: PhienCSDL):
    await goi(conn, "pkg_admin.sp_mo_tai_khoan", [ten])
    await conn.commit()
    return {"ok": True}


@router.post("/tai-khoan/{ten}/vai-tro/{ma_vai_tro}")
async def gan_vai_tro(ten: str, ma_vai_tro: str, conn: PhienCSDL):
    """CSDL chặn Admin tự đổi vai trò của chính mình."""
    await goi(conn, "pkg_admin.sp_gan_vai_tro", [ten, ma_vai_tro])
    await conn.commit()
    return {"ok": True}


@router.delete("/tai-khoan/{ten}/vai-tro/{ma_vai_tro}")
async def thu_hoi_vai_tro(ten: str, ma_vai_tro: str, conn: PhienCSDL):
    await goi(conn, "pkg_admin.sp_thu_hoi_vai_tro", [ten, ma_vai_tro])
    await conn.commit()
    return {"ok": True}


@router.get("/nhat-ky")
async def nhat_ky(conn: PhienCSDL, doi_tuong: str | None = None, gioi_han: int = 200):
    """VW-10: mỗi vai trò thấy phần nhật ký của mình (Admin: tài khoản; HR: hồ sơ; Payroll: lương)."""
    return await doc_view(conn, "vw_nhat_ky", "doi_tuong = :dt" if doi_tuong else "",
                          {"dt": doi_tuong.upper()} if doi_tuong else {}, "thoi_diem desc, nhat_ky_id desc",
                          min(max(gioi_han, 1), 1000))
