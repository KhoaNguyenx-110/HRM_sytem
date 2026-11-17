"""Nghiệp vụ nhân sự (R_HR): hồ sơ, hợp đồng, điều chuyển, công, chốt công, báo cáo HR.

Danh sách đọc qua view (VW-01, 02, 03, 06, 12, 14) - view lọc theo vai trò nên
trưởng phòng gọi cùng endpoint chỉ thấy phòng mình, nhân viên chỉ thấy mình.
Mọi thao tác ghi gọi pkg_hr / pkg_att / pkg_leave; CSDL kiểm tra vai trò HR.
"""
from datetime import date

from fastapi import APIRouter
from pydantic import BaseModel, Field

from ..csdl import goi
from ..loi import LoiNghiepVu
from ..phu_thuoc import CLOB, SO, PhienCSDL, doc_view, goi_tra_ve

router = APIRouter(prefix="/api", tags=["nhân sự"])


@router.get("/nhan-vien")
async def danh_sach(conn: PhienCSDL, q: str | None = None, phong_ban: str | None = None,
                    con_lam: bool | None = None):
    dk, ts = [], {}
    if q:
        dk.append("(upper(ho_ten) like upper(:q) or upper(ma_nhan_vien) like upper(:q))")
        ts["q"] = f"%{q.strip()}%"
    if phong_ban:
        dk.append("ma_phong_ban = :pb")
        ts["pb"] = phong_ban
    if con_lam is not None:
        dk.append("trang_thai_lam_viec = :tt")
        ts["tt"] = "DANG_LAM" if con_lam else "DA_NGHI"
    return await doc_view(conn, "vw_ho_so_nhan_vien", " and ".join(dk), ts, "ma_nhan_vien")


@router.get("/nhan-vien/{ma}")
async def chi_tiet(ma: str, conn: PhienCSDL):
    nv = await doc_view(conn, "vw_ho_so_nhan_vien", "ma_nhan_vien = upper(:ma)", {"ma": ma})
    if not nv:
        # Không có hoặc ngoài phạm vi được xem: trả cùng một câu (không lộ mã nào tồn tại)
        raise LoiNghiepVu(404, "Không tìm thấy nhân viên trong phạm vi bạn được xem.")
    qt = await doc_view(conn, "vw_qua_trinh_cong_tac", "ma_nhan_vien = upper(:ma)", {"ma": ma}, "ngay_bat_dau desc")
    phep = await doc_view(conn, "vw_phep_con_lai", "ma_nhan_vien = upper(:ma)", {"ma": ma}, "nam desc")
    return {"ho_so": nv[0], "qua_trinh": qt, "phep": phep}


class NhanVienMoi(BaseModel):
    ma_nhan_vien: str = Field(min_length=1, max_length=20)
    ho_ten: str = Field(min_length=1, max_length=100)
    ngay_sinh: date
    so_dinh_danh: str
    ma_so_thue: str | None = None
    email: str
    so_dien_thoai: str | None = None
    dia_chi: str | None = None
    ngay_vao_lam: date
    ma_phong_ban: str
    ma_chuc_vu: str


@router.post("/nhan-vien", status_code=201)
async def them(nv: NhanVienMoi, conn: PhienCSDL):
    """SP-03 pkg_hr.sp_them_nhan_vien (kèm phân công đầu tiên)."""
    (nv_id,) = await goi_tra_ve(conn, "pkg_hr.sp_them_nhan_vien", [
        nv.ma_nhan_vien, nv.ho_ten, nv.ngay_sinh, nv.so_dinh_danh, nv.ma_so_thue, nv.email,
        nv.so_dien_thoai, nv.dia_chi, nv.ngay_vao_lam, nv.ma_phong_ban, nv.ma_chuc_vu], [SO])
    await conn.commit()
    return {"nhan_vien_id": nv_id}


class CapNhatNhanVien(BaseModel):
    """Trường bỏ trống (null) = giữ nguyên."""
    ho_ten: str | None = None
    email: str | None = None
    so_dien_thoai: str | None = None
    dia_chi: str | None = None
    so_dinh_danh: str | None = None
    ma_so_thue: str | None = None


@router.patch("/nhan-vien/{ma}")
async def cap_nhat(ma: str, du_lieu: CapNhatNhanVien, conn: PhienCSDL):
    await goi(conn, "pkg_hr.sp_cap_nhat_nhan_vien", [
        ma, du_lieu.ho_ten, du_lieu.email, du_lieu.so_dien_thoai, du_lieu.dia_chi,
        du_lieu.so_dinh_danh, du_lieu.ma_so_thue])
    await conn.commit()
    return {"ok": True}


class DieuChuyen(BaseModel):
    ma_phong_ban: str
    ma_chuc_vu: str
    ngay_hieu_luc: date
    can_cu: str = Field(min_length=1, max_length=200)


@router.post("/nhan-vien/{ma}/dieu-chuyen")
async def dieu_chuyen(ma: str, du_lieu: DieuChuyen, conn: PhienCSDL):
    await goi(conn, "pkg_hr.sp_dieu_chuyen",
              [ma, du_lieu.ma_phong_ban, du_lieu.ma_chuc_vu, du_lieu.ngay_hieu_luc, du_lieu.can_cu])
    await conn.commit()
    return {"ok": True}


class NghiViec(BaseModel):
    ngay_nghi_viec: date


@router.post("/nhan-vien/{ma}/nghi-viec")
async def nghi_viec(ma: str, du_lieu: NghiViec, conn: PhienCSDL):
    await goi(conn, "pkg_hr.sp_nghi_viec", [ma, du_lieu.ngay_nghi_viec])
    await conn.commit()
    return {"ok": True}


class HopDong(BaseModel):
    so_hop_dong: str = Field(min_length=1, max_length=30)
    ma_loai: str
    ngay_bat_dau: date
    ngay_ket_thuc: date | None = None
    luong_co_ban: int = Field(gt=0)
    can_cu_dong_bao_hiem: int = Field(gt=0)


@router.post("/nhan-vien/{ma}/hop-dong", status_code=201)
async def luu_hop_dong(ma: str, hd: HopDong, conn: PhienCSDL):
    """SP-05: CSDL chặn hợp đồng chồng lấn (-20205), loại hợp đồng cần ngày kết thúc..."""
    await goi(conn, "pkg_hr.sp_luu_hop_dong", [ma, hd.so_hop_dong, hd.ma_loai, hd.ngay_bat_dau,
                                               hd.ngay_ket_thuc, hd.luong_co_ban, hd.can_cu_dong_bao_hiem])
    await conn.commit()
    return {"ok": True}


class DieuChinhLuong(BaseModel):
    tu_ngay: date
    luong_co_ban: int = Field(gt=0)
    can_cu_dong_bao_hiem: int = Field(gt=0)


@router.post("/hop-dong/{so_hop_dong}/dieu-chinh-luong")
async def dieu_chinh_luong(so_hop_dong: str, du_lieu: DieuChinhLuong, conn: PhienCSDL):
    await goi(conn, "pkg_hr.sp_dieu_chinh_luong",
              [so_hop_dong, du_lieu.tu_ngay, du_lieu.luong_co_ban, du_lieu.can_cu_dong_bao_hiem])
    await conn.commit()
    return {"ok": True}


@router.get("/hop-dong/sap-het-han")
async def hop_dong_sap_het_han(conn: PhienCSDL):
    """VW-06 (QR-03)."""
    return await doc_view(conn, "vw_hop_dong_sap_het_han", sap_xep="ngay_ket_thuc")


@router.get("/cong")
async def cong_thang(conn: PhienCSDL, nam: int, thang: int, phong_ban: str | None = None):
    """VW-03 cho HR / Payroll / trưởng phòng (view lọc phạm vi)."""
    dk = "nam = :nam and thang = :thang" + (" and ma_phong_ban = :pb" if phong_ban else "")
    ts = {"nam": nam, "thang": thang} | ({"pb": phong_ban} if phong_ban else {})
    return await doc_view(conn, "vw_cong_thang", dk, ts, "ma_nhan_vien", 5000)


@router.get("/nghi-phep")
async def nghi_phep_chi_tiet(conn: PhienCSDL, tu_ngay: date, den_ngay: date):
    """VW-14 (QR-11): từng ngày nghỉ trong khoảng."""
    return await doc_view(conn, "vw_nghi_phep_chi_tiet", "ngay between :tu and :den",
                          {"tu": tu_ngay, "den": den_ngay}, "ngay, ma_nhan_vien", 5000)


@router.get("/phep-con-lai")
async def phep_con_lai(conn: PhienCSDL, nam: int):
    """VW-02 cho HR / trưởng phòng."""
    return await doc_view(conn, "vw_phep_con_lai", "nam = :nam", {"nam": nam}, "ma_nhan_vien", 5000)


@router.post("/ky-luong/{nam}/{thang}/chot-cong")
async def chot_cong(nam: int, thang: int, conn: PhienCSDL):
    """SP-07: trả danh sách lỗi thay vì ném lỗi; có lỗi thì kỳ chưa chốt."""
    so_loi, ds_loi = await goi_tra_ve(conn, "pkg_att.sp_chot_cong", [thang, nam], [SO, CLOB])
    await conn.commit()
    return {"so_loi": so_loi, "ds_loi": [d for d in (ds_loi or "").splitlines() if d.strip()]}
