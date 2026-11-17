"""Chuyển lỗi Oracle thành phản hồi HTTP.

CSDL là nơi kiểm tra nghiệp vụ; câu báo lỗi ORA-20xxx đã viết bằng tiếng Việt cho
người dùng (RAISE_APPLICATION_ERROR), nên backend chỉ chọn mã HTTP và trả nguyên
câu đó. Lỗi khác (lỗi hệ thống) KHÔNG trả chi tiết ra trình duyệt, chỉ ghi log.
"""
import logging
import re

import oracledb
from fastapi import Request
from fastapi.responses import JSONResponse

log = logging.getLogger("hrm.loi")

# Mã nghiệp vụ -> HTTP. Mã không có trong bảng: 400 (dữ liệu không hợp lệ).
_HTTP_THEO_MA = {
    20001: 401,   # tài khoản không hợp lệ / bị khóa (pkg_ctx.dat_phien)
    20003: 401,   # chưa có danh tính phiên
    20002: 403,   # sai kênh gọi
    20009: 403,   # không đủ vai trò (pkg_chung.yeu_cau_vai_tro)
    20301: 409,   # kỳ lương không còn MỞ
    20205: 409,   # hợp đồng chồng lấn
}
# Lỗi Oracle hệ thống nhưng người dùng hiểu được
_HTTP_ORACLE = {
    54: (409, "Dữ liệu đang được người khác xử lý, vui lòng thử lại sau ít phút."),
    1: (409, "Dữ liệu đã tồn tại (trùng khóa)."),
}

_RE_ORA = re.compile(r"ORA-(\d{5}):\s*(.*)")


class LoiNghiepVu(Exception):
    """Lỗi do backend tự phát hiện (vd sai mật khẩu), không phải từ CSDL."""

    def __init__(self, http: int, thong_bao: str, ma: str | None = None):
        self.http, self.thong_bao, self.ma = http, thong_bao, ma


def phan_tich(loi: oracledb.DatabaseError) -> tuple[int, str, str]:
    """Trả (mã HTTP, câu báo lỗi, mã ORA) cho một lỗi Oracle."""
    err = loi.args[0]
    ma = getattr(err, "code", 0) or 0
    if 20000 <= ma <= 20999:
        # Dòng đầu là "ORA-20xxx: <câu tiếng Việt>"; các dòng sau là ngăn xếp ORA-06512
        dong_dau = str(getattr(err, "message", err)).splitlines()[0]
        m = _RE_ORA.match(dong_dau)
        cau = m.group(2) if m else dong_dau
        return _HTTP_THEO_MA.get(ma, 400), cau, f"ORA-{ma}"
    if ma in _HTTP_ORACLE:
        http, cau = _HTTP_ORACLE[ma]
        return http, cau, f"ORA-{ma:05d}"
    return 500, "Lỗi hệ thống. Vui lòng thử lại hoặc báo quản trị viên.", f"ORA-{ma:05d}"


async def xu_ly_loi_oracle(_: Request, loi: oracledb.DatabaseError):
    http, cau, ma = phan_tich(loi)
    if http == 500:
        log.exception("Lỗi Oracle không lường trước: %s", ma, exc_info=loi)
    return JSONResponse(status_code=http, content={"loi": cau, "ma": ma})


async def xu_ly_loi_nghiep_vu(_: Request, loi: LoiNghiepVu):
    return JSONResponse(status_code=loi.http, content={"loi": loi.thong_bao, "ma": loi.ma})
