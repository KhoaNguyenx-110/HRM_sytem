"""Hàng chờ duyệt (VW-08) và xử lý duyệt cho trưởng phòng / HR.

VW-08 gộp 4 loại yêu cầu; mỗi loại do một procedure riêng xử lý với quy ước
tham số khác nhau. Endpoint chung ở đây chỉ QUY ĐỔI quy ước, không tự kiểm tra
ai được duyệt: CSDL kiểm tra người duyệt hợp lệ (quy tắc 2.4, fn_nguoi_duyet_hop_le),
không tự duyệt của mình, kỳ còn MỞ...
"""
from typing import Literal

from fastapi import APIRouter
from pydantic import BaseModel, Field

from ..csdl import goi
from ..loi import LoiNghiepVu
from ..phu_thuoc import PhienCSDL, doc_view

router = APIRouter(prefix="/api", tags=["duyệt"])

LoaiYeuCau = Literal["NGHI_PHEP", "OT", "KHEN_THUONG", "PHAT_SINH_LUONG"]


@router.get("/duyet")
async def hang_cho(conn: PhienCSDL):
    """Những yêu cầu mà người đăng nhập là người duyệt hợp lệ."""
    return await doc_view(conn, "vw_don_cho_duyet", sap_xep="tu_ngay, ma_yeu_cau")


class QuyetDinhDuyet(BaseModel):
    dong_y: bool
    y_kien: str | None = Field(default=None, max_length=500)   # bắt buộc khi từ chối đơn nghỉ / khen thưởng
    so_gio_duyet: float | None = Field(default=None, gt=0)     # chỉ OT: duyệt ít giờ hơn đăng ký


@router.post("/duyet/{loai}/{ma}")
async def xu_ly(loai: LoaiYeuCau, ma: int, qd: QuyetDinhDuyet, conn: PhienCSDL):
    if loai == "NGHI_PHEP":       # SP-15: DUYET | TU_CHOI
        await goi(conn, "pkg_leave.sp_xu_ly_don_nghi", [ma, "DUYET" if qd.dong_y else "TU_CHOI", qd.y_kien])
    elif loai == "OT":            # SP-17: DA_DUYET | TU_CHOI
        await goi(conn, "pkg_att.sp_duyet_ot", [ma, "DA_DUYET" if qd.dong_y else "TU_CHOI", qd.so_gio_duyet])
    elif loai == "PHAT_SINH_LUONG":
        await goi(conn, "pkg_hr.sp_duyet_phat_sinh", [ma, "DA_DUYET" if qd.dong_y else "TU_CHOI"])
    else:                         # KHEN_THUONG: procedure nhận SỐ QUYẾT ĐỊNH, không nhận id
        dong = await doc_view(conn, "vw_don_cho_duyet",
                              "loai_yeu_cau = 'KHEN_THUONG' and ma_yeu_cau = :ma", {"ma": ma})
        if not dong:
            raise LoiNghiepVu(404, "Không tìm thấy quyết định khen thưởng đang chờ bạn duyệt.")
        # VW-08 trình bày nội dung là "<số quyết định> - <hình thức>"
        so_qd = dong[0]["noi_dung"].rsplit(" - ", 1)[0]
        await goi(conn, "pkg_hr.sp_duyet_khen_thuong", [so_qd, "DA_DUYET" if qd.dong_y else "TU_CHOI", qd.y_kien])
    await conn.commit()
    return {"ok": True}


@router.get("/phong/nhan-su")
async def nhan_su_phong(conn: PhienCSDL):
    """VW-07: nhân sự phòng mình đang quản lý (chỉ trưởng phòng thấy dòng)."""
    return await doc_view(conn, "vw_nhan_su_phong", sap_xep="ma_nhan_vien")
