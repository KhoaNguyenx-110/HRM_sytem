"""Chức năng của mọi nhân viên (R_EMPLOYEE): xem của mình, đăng ký nghỉ / OT, rút đơn.

"Của mình" do view tự lọc theo fn_nhan_vien_hien_tai; API không truyền mã nhân viên.
"""
from datetime import date, datetime
from typing import Literal

from fastapi import APIRouter
from pydantic import BaseModel, Field

from ..csdl import goi
from ..phu_thuoc import SO, PhienCSDL, doc_view, goi_tra_ve

router = APIRouter(prefix="/api/toi", tags=["cá nhân"])

# HR/Payroll/Manager nhìn được nhiều người qua cùng view: ở /api/toi chỉ lấy dòng của mình
MA_CUA_TOI = ("ma_nhan_vien = (select ma_nhan_vien from hrm_owner.vw_ho_so_nhan_vien"
              " where nhan_vien_id = sys_context('HRM_CTX', 'NHAN_VIEN_ID'))")


def gom_phieu(dong: list[dict]) -> list[dict]:
    """VW-05 trả một dòng cho mỗi khoản trên phiếu: gom thành phiếu + danh sách khoản."""
    phieu: dict[int, dict] = {}
    dau = ("nam", "thang", "trang_thai_ky", "phieu_luong_id", "ma_nhan_vien", "ho_ten", "ten_phong_ban",
           "ten_chuc_vu", "luong_co_ban_ap_dung", "gio_huong_luong", "tong_gross", "thu_nhap_chiu_thue",
           "giam_tru_ap_dung", "thu_nhap_tinh_thue", "bao_hiem_nld", "thue_tncn", "khau_tru_khac",
           "tong_net", "bao_hiem_nsdld")
    for d in dong:
        p = phieu.setdefault(d["phieu_luong_id"], {k: d[k] for k in dau} | {"khoan": []})
        if d["chi_tiet_id"] is not None:
            p["khoan"].append({k: d[k] for k in ("ma_khoan", "ten_khoan", "nhom_khoan_ap_dung", "so_luong",
                                                 "don_gia", "he_so", "thanh_tien", "phan_chiu_thue")})
    return list(phieu.values())


@router.get("/ho-so")
async def ho_so(conn: PhienCSDL):
    """VW-01 (dòng của chính mình) + VW-12 quá trình công tác."""
    nv = await doc_view(conn, "vw_ho_so_nhan_vien",
                        "nhan_vien_id = sys_context('HRM_CTX', 'NHAN_VIEN_ID')")
    qt = await doc_view(conn, "vw_qua_trinh_cong_tac",
                        "ma_nhan_vien = :ma", {"ma": nv[0]["ma_nhan_vien"]}, "ngay_bat_dau desc") if nv else []
    return {"ho_so": nv[0] if nv else None, "qua_trinh": qt}


@router.get("/phieu-luong")
async def phieu_luong(conn: PhienCSDL, nam: int | None = None):
    """VW-05: nhân viên chỉ thấy phiếu kỳ DA_KHOA của mình (view tự lọc)."""
    dong = await doc_view(conn, "vw_phieu_luong_ca_nhan",
                          MA_CUA_TOI
                          + (" and nam = :nam" if nam else ""),
                          {"nam": nam} if nam else {}, "nam desc, thang desc, chi_tiet_id", 5000)
    return gom_phieu(dong)


@router.get("/phep")
async def phep(conn: PhienCSDL, nam: int | None = None):
    """VW-02: hạn mức và số ngày phép còn lại."""
    return await doc_view(conn, "vw_phep_con_lai",
                          MA_CUA_TOI
                          + (" and nam = :nam" if nam else ""), {"nam": nam} if nam else {}, "nam desc")


@router.get("/cong")
async def cong(conn: PhienCSDL, nam: int):
    """VW-03: công tháng của mình trong một năm."""
    return await doc_view(conn, "vw_cong_thang",
                          "nam = :nam and " + MA_CUA_TOI,
                          {"nam": nam}, "thang")


@router.get("/yeu-cau")
async def yeu_cau(conn: PhienCSDL):
    """VW-11: đơn nghỉ và đăng ký OT của mình, kèm trạng thái."""
    return await doc_view(conn, "vw_yeu_cau_cua_toi", sap_xep="tu_ngay desc, ma_yeu_cau desc")


class DonNghi(BaseModel):
    ma_loai: str = Field(min_length=1, max_length=20)          # PHEP_NAM | OM | KHONG_LUONG
    tu_ngay: date
    den_ngay: date
    buoi: Literal["CA_NGAY", "SANG", "CHIEU"] = "CA_NGAY"
    ly_do: str = Field(min_length=1, max_length=500)


@router.post("/nghi-phep", status_code=201)
async def dang_ky_nghi(du_lieu: DonNghi, conn: PhienCSDL):
    """SP-14 pkg_leave.sp_dang_ky_nghi: chỉ giữ ngày LAM_VIEC; kiểm tra phép, trùng, kỳ MỞ."""
    (don_id,) = await goi_tra_ve(conn, "pkg_leave.sp_dang_ky_nghi",
                                 [du_lieu.ma_loai, du_lieu.tu_ngay, du_lieu.den_ngay, du_lieu.buoi, du_lieu.ly_do],
                                 [SO])
    await conn.commit()
    return {"don_nghi_id": don_id}


@router.post("/nghi-phep/{don_id}/rut")
async def rut_don(don_id: int, conn: PhienCSDL):
    """Chỉ chủ đơn rút được (CSDL kiểm tra)."""
    await goi(conn, "pkg_leave.sp_xu_ly_don_nghi", [don_id, "RUT", None])
    await conn.commit()
    return {"ok": True}


class DangKyOT(BaseModel):
    bat_dau: datetime
    ket_thuc: datetime
    ly_do: str = Field(min_length=1, max_length=500)


@router.post("/ot", status_code=201)
async def dang_ky_ot(du_lieu: DangKyOT, conn: PhienCSDL):
    """SP-16 pkg_att.sp_dang_ky_ot: hạn mức OT ngày/tháng/năm kiểm tra trong CSDL."""
    (ot_id,) = await goi_tra_ve(conn, "pkg_att.sp_dang_ky_ot",
                                [du_lieu.bat_dau, du_lieu.ket_thuc, du_lieu.ly_do], [SO])
    await conn.commit()
    return {"tang_ca_id": ot_id}


