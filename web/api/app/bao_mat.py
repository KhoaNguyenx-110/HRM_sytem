"""Mật khẩu (bcrypt, NFR-04) và token phiên (JWT ký HMAC, cookie httpOnly).

CSDL không bao giờ nhận mật khẩu rõ: backend băm và so sánh, CSDL chỉ lưu và
trả chuỗi băm (pkg_auth, đặc tả mục 8.1 bước 1-4).
Token chỉ mang tai_khoan_id + tên; vai trò KHÔNG nằm trong token mà được
pkg_ctx.dat_phien đọc lại từ bảng ở mỗi request, nên thu hồi vai trò hay khóa
tài khoản có hiệu lực ngay ở request kế tiếp.
"""
import time

import bcrypt
import jwt
from fastapi import Request

from .loi import LoiNghiepVu

CHI_PHI_BCRYPT = 12
# Chuỗi băm giả để so sánh khi tên đăng nhập không tồn tại: thời gian phản hồi
# giống trường hợp sai mật khẩu, không lộ tên nào có thật.
_BAM_GIA = bcrypt.hashpw(b"khong-dung", bcrypt.gensalt(CHI_PHI_BCRYPT))

DO_DAI_TOI_THIEU = 8


def bam_mat_khau(mat_khau: str) -> str:
    return bcrypt.hashpw(mat_khau.encode(), bcrypt.gensalt(CHI_PHI_BCRYPT)).decode()


def khop_mat_khau(mat_khau: str, chuoi_bam: str | None) -> bool:
    """So mật khẩu với chuỗi băm; chuỗi băm thiếu hoặc sai định dạng -> False."""
    if not chuoi_bam:
        bcrypt.checkpw(mat_khau.encode(), _BAM_GIA)   # chỉ để tốn thời gian như thật
        return False
    try:
        return bcrypt.checkpw(mat_khau.encode(), chuoi_bam.encode())
    except ValueError:
        # Vd hash giữ chỗ của dữ liệu mẫu (chưa chạy cong_cu/dat_mat_khau_demo.py)
        bcrypt.checkpw(mat_khau.encode(), _BAM_GIA)
        return False


def kiem_tra_mat_khau_moi(mat_khau: str) -> None:
    if len(mat_khau) < DO_DAI_TOI_THIEU:
        raise LoiNghiepVu(400, f"Mật khẩu mới phải có ít nhất {DO_DAI_TOI_THIEU} ký tự.")


def tao_token(secret: str, tai_khoan_id: int, ten: str, het_han_phut: int) -> str:
    bay_gio = int(time.time())
    return jwt.encode(
        {"sub": str(tai_khoan_id), "ten": ten, "iat": bay_gio, "exp": bay_gio + het_han_phut * 60},
        secret, algorithm="HS256")


def doc_token(request: Request) -> tuple[int, str]:
    """Lấy (tai_khoan_id, ten) từ cookie phiên; thiếu/hết hạn/sai chữ ký -> 401."""
    ch = request.app.state.cau_hinh
    token = request.cookies.get(ch.cookie_ten)
    if not token:
        raise LoiNghiepVu(401, "Chưa đăng nhập.", "CHUA_DANG_NHAP")
    try:
        du_lieu = jwt.decode(token, ch.jwt_secret, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise LoiNghiepVu(401, "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.", "HET_HAN")
    except jwt.InvalidTokenError:
        raise LoiNghiepVu(401, "Phiên đăng nhập không hợp lệ.", "TOKEN_SAI")
    return int(du_lieu["sub"]), du_lieu["ten"]
