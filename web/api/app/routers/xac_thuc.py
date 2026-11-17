"""Đăng nhập, đăng xuất, thông tin phiên, đổi mật khẩu (SP-27, AUTH-01, AUTH-05)."""
import asyncio

from fastapi import APIRouter, Request, Response
from pydantic import BaseModel, Field

from ..bao_mat import bam_mat_khau, doc_token, khop_mat_khau, kiem_tra_mat_khau_moi, tao_token
from ..cau_hinh import SCHEMA
from ..csdl import goi, ket_noi_an_danh
from ..loi import LoiNghiepVu
from ..phu_thuoc import PhienCSDL, doc_dong

router = APIRouter(prefix="/api", tags=["xác thực"])

# Một câu chung cho "không có tên này" và "sai mật khẩu": không lộ tên nào tồn tại
_SAI = "Tên đăng nhập hoặc mật khẩu không đúng."


class DangNhap(BaseModel):
    ten_dang_nhap: str = Field(min_length=1, max_length=50)
    mat_khau: str = Field(min_length=1, max_length=200)


class DoiMatKhau(BaseModel):
    mat_khau_cu: str = Field(min_length=1, max_length=200)
    mat_khau_moi: str = Field(min_length=1, max_length=200)


async def _thong_tin_xac_thuc(conn, ten: str) -> tuple[int | None, str | None, str | None]:
    """pkg_auth.lay_thong_tin_xac_thuc: (tai_khoan_id, chuỗi băm, trạng thái)."""
    async with conn.cursor() as cur:
        v_id, v_bam, v_tt = cur.var(int), cur.var(str), cur.var(str)
        await cur.callproc(f"{SCHEMA}.pkg_auth.lay_thong_tin_xac_thuc", [ten, v_id, v_bam, v_tt])
        return v_id.getvalue(), v_bam.getvalue(), v_tt.getvalue()


@router.post("/dang-nhap")
async def dang_nhap(du_lieu: DangNhap, request: Request, response: Response):
    ch = request.app.state.cau_hinh
    ten = du_lieu.ten_dang_nhap.strip().lower()
    async with ket_noi_an_danh() as conn:
        tk_id, chuoi_bam, trang_thai = await _thong_tin_xac_thuc(conn, ten)
        # bcrypt tốn ~0,25 s CPU: chạy ở luồng phụ để không chặn các request khác
        dung = await asyncio.to_thread(khop_mat_khau, du_lieu.mat_khau, chuoi_bam)
        if tk_id is None:
            raise LoiNghiepVu(401, _SAI, "SAI_DANG_NHAP")
        if not dung:
            # Autonomous transaction trong CSDL: đếm lần sai, đủ 5 lần thì KHOA
            await goi(conn, "pkg_auth.ghi_that_bai", [ten])
            raise LoiNghiepVu(401, _SAI, "SAI_DANG_NHAP")
        if trang_thai != "HOAT_DONG":
            raise LoiNghiepVu(403, "Tài khoản đã bị khóa. Liên hệ quản trị viên để mở lại.", "TAI_KHOAN_KHOA")
        await goi(conn, "pkg_auth.ghi_thanh_cong", [tk_id])
        await conn.commit()

    response.set_cookie(
        ch.cookie_ten, tao_token(ch.jwt_secret, tk_id, ten, ch.jwt_het_han_phut),
        max_age=ch.jwt_het_han_phut * 60, httponly=True, samesite="strict",
        secure=ch.cookie_secure, path="/api")
    return {"ok": True}


@router.post("/dang-xuat")
async def dang_xuat(request: Request, response: Response):
    response.delete_cookie(request.app.state.cau_hinh.cookie_ten, path="/api")
    return {"ok": True}


@router.get("/toi")
async def toi(conn: PhienCSDL):
    """Danh tính phiên do CSDL nạp (HRM_CTX), không lấy từ token."""
    ctx = (await doc_dong(conn, """
        select sys_context('HRM_CTX', 'TAI_KHOAN_ID')  as tai_khoan_id,
               sys_context('HRM_CTX', 'NHAN_VIEN_ID')  as nhan_vien_id,
               sys_context('HRM_CTX', 'TEN_DANG_NHAP') as ten_dang_nhap,
               sys_context('HRM_CTX', 'VAI_TRO')       as vai_tro
          from dual"""))[0]
    ho_so = []
    if ctx["nhan_vien_id"]:
        ho_so = await doc_dong(conn, f"""
            select ma_nhan_vien, ho_ten, ten_phong_ban, ten_chuc_vu
              from {SCHEMA}.vw_ho_so_nhan_vien where nhan_vien_id = :id""",
            {"id": int(ctx["nhan_vien_id"])})
    return {
        "tai_khoan_id": int(ctx["tai_khoan_id"]),
        "ten_dang_nhap": ctx["ten_dang_nhap"],
        "nhan_vien_id": int(ctx["nhan_vien_id"]) if ctx["nhan_vien_id"] else None,
        "vai_tro": [v for v in (ctx["vai_tro"] or "").split(",") if v],
        "ho_so": ho_so[0] if ho_so else None,
    }


@router.post("/toi/doi-mat-khau")
async def doi_mat_khau(du_lieu: DoiMatKhau, conn: PhienCSDL, request: Request):
    _, ten = doc_token(request)
    kiem_tra_mat_khau_moi(du_lieu.mat_khau_moi)
    _, bam_cu, _ = await _thong_tin_xac_thuc(conn, ten)
    if not await asyncio.to_thread(khop_mat_khau, du_lieu.mat_khau_cu, bam_cu):
        raise LoiNghiepVu(400, "Mật khẩu hiện tại không đúng.", "ORA-20004")
    if du_lieu.mat_khau_cu == du_lieu.mat_khau_moi:
        raise LoiNghiepVu(400, "Mật khẩu mới phải khác mật khẩu hiện tại.", "ORA-20005")
    bam_moi = await asyncio.to_thread(bam_mat_khau, du_lieu.mat_khau_moi)
    # CSDL kiểm tra lại chuỗi băm cũ còn khớp (chống hai lần đổi đồng thời)
    await goi(conn, "pkg_auth.sp_doi_mat_khau", [bam_cu, bam_moi])
    await conn.commit()
    return {"ok": True}
