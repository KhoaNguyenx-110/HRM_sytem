"""Nghiệp vụ lương (R_PAYROLL): kỳ lương, phát sinh, tính, khóa, bảng lương, phiếu.

Chuỗi trạng thái kỳ (MO -> DA_CHOT_CONG -> DA_TINH -> DA_KHOA) do CSDL giữ;
API chỉ gọi đúng procedure và trả lỗi nghiệp vụ nếu sai thứ tự.
"""
from fastapi import APIRouter
from pydantic import BaseModel, Field

from ..csdl import goi
from ..phu_thuoc import CLOB, SO, PhienCSDL, doc_view, goi_tra_ve
from .ca_nhan import gom_phieu

router = APIRouter(prefix="/api", tags=["lương"])


class KyMoi(BaseModel):
    thang: int = Field(ge=1, le=12)
    nam: int = Field(ge=2000, le=2100)


@router.post("/ky-luong", status_code=201)
async def tao_ky(ky: KyMoi, conn: PhienCSDL):
    (ky_id,) = await goi_tra_ve(conn, "pkg_payroll.sp_tao_ky_luong", [ky.thang, ky.nam, None], [SO])
    await conn.commit()
    return {"ky_luong_id": ky_id}


@router.post("/ky-luong/{nam}/{thang}/tinh")
async def tinh(nam: int, thang: int, conn: PhienCSDL):
    """SP-09: lỗi theo từng nhân viên trả về danh sách (không dừng cả kỳ)."""
    so_loi, ds_loi = await goi_tra_ve(conn, "pkg_payroll.sp_tinh_luong_ky", [thang, nam], [SO, CLOB])
    await conn.commit()
    return {"so_loi": so_loi, "ds_loi": [d for d in (ds_loi or "").splitlines() if d.strip()]}


@router.post("/ky-luong/{nam}/{thang}/khoa")
async def khoa(nam: int, thang: int, conn: PhienCSDL):
    """SP-11: sau khi khóa, phiếu bất biến (TR-02) và nhân viên mới xem được (VW-05)."""
    await goi(conn, "pkg_payroll.sp_khoa_ky_luong", [thang, nam])
    await conn.commit()
    return {"ok": True}


@router.get("/ky-luong/{nam}/{thang}/bang-luong")
async def bang_luong(nam: int, thang: int, conn: PhienCSDL, phong_ban: str | None = None):
    """VW-04: bảng lương tổng hợp (chỉ Payroll thấy dòng)."""
    dk = "nam = :nam and thang = :thang" + (" and ma_phong_ban = :pb" if phong_ban else "")
    ts = {"nam": nam, "thang": thang} | ({"pb": phong_ban} if phong_ban else {})
    return await doc_view(conn, "vw_bang_luong_tong_hop", dk, ts, "ma_phong_ban, ma_nhan_vien", 5000)


@router.get("/ky-luong/{nam}/{thang}/phieu/{ma_nhan_vien}")
async def phieu(nam: int, thang: int, ma_nhan_vien: str, conn: PhienCSDL):
    """VW-05: phiếu chi tiết từng khoản (Payroll xem mọi kỳ; nhân viên dùng /api/toi)."""
    dong = await doc_view(conn, "vw_phieu_luong_ca_nhan",
                          "nam = :nam and thang = :thang and ma_nhan_vien = upper(:ma)",
                          {"nam": nam, "thang": thang, "ma": ma_nhan_vien}, "chi_tiet_id")
    ds = gom_phieu(dong)
    return ds[0] if ds else None


class PhatSinh(BaseModel):
    ma_nhan_vien: str
    thang: int = Field(ge=1, le=12)
    nam: int
    ma_khoan: str            # vd THUONG, DIEU_CHINH_TANG, DIEU_CHINH_GIAM, KHAU_TRU
    so_tien: int = Field(gt=0)
    can_cu: str = Field(min_length=1, max_length=500)


@router.post("/phat-sinh", status_code=201)
async def luu_phat_sinh(ps: PhatSinh, conn: PhienCSDL):
    """SP-10: Payroll lập, chờ HR duyệt (VW-08 loại PHAT_SINH_LUONG)."""
    (ps_id,) = await goi_tra_ve(conn, "pkg_payroll.sp_luu_phat_sinh",
                                [ps.ma_nhan_vien, ps.thang, ps.nam, ps.ma_khoan, ps.so_tien, ps.can_cu, None], [SO])
    await conn.commit()
    return {"phat_sinh_id": ps_id}


class ChuyenThuong(BaseModel):
    so_quyet_dinh: str
    thang: int = Field(ge=1, le=12)
    nam: int


@router.post("/phat-sinh/chuyen-thuong", status_code=201)
async def chuyen_thuong(du_lieu: ChuyenThuong, conn: PhienCSDL):
    """Chuyển quyết định khen thưởng tiền ĐÃ DUYỆT thành phát sinh của kỳ."""
    (ps_id,) = await goi_tra_ve(conn, "pkg_payroll.sp_chuyen_thuong",
                                [du_lieu.so_quyet_dinh, du_lieu.thang, du_lieu.nam], [SO])
    await conn.commit()
    return {"phat_sinh_id": ps_id}
