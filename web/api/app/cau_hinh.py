"""Cấu hình backend, đọc từ file .env ở gốc dự án (không commit, không in ra).

Khóa dùng:
  HRM_APP_PASSWORD  mật khẩu user Oracle HRM_APP (kênh web, mục 8.1)
  ORACLE_DSN        mặc định localhost:1521/FREEPDB1 (container oracle23ai)
  WEB_JWT_SECRET    khóa ký token phiên. Thiếu thì sinh ngẫu nhiên mỗi lần khởi
                    động: mọi người dùng phải đăng nhập lại sau khi restart.
"""
import os
import secrets
from dataclasses import dataclass
from pathlib import Path

from dotenv import dotenv_values

GOC_DU_AN = Path(__file__).resolve().parents[3]

# Mọi đối tượng CSDL nằm trong schema HRM_OWNER; HRM_APP không có synonym nên
# luôn gọi kèm tên schema.
SCHEMA = "hrm_owner"


@dataclass(frozen=True)
class CauHinh:
    hrm_app_password: str
    dsn: str
    jwt_secret: str
    jwt_het_han_phut: int = 480        # một ca làm việc
    pool_min: int = 1
    pool_max: int = 8
    cookie_ten: str = "hrm_phien"
    cookie_secure: bool = False        # True khi chạy sau HTTPS


def doc_cau_hinh() -> CauHinh:
    env = dotenv_values(GOC_DU_AN / ".env")
    mat_khau = env.get("HRM_APP_PASSWORD")
    if not mat_khau:
        raise RuntimeError("Thiếu HRM_APP_PASSWORD trong .env")
    pdb = env.get("ORACLE_PDB") or "FREEPDB1"
    return CauHinh(
        hrm_app_password=mat_khau,
        dsn=env.get("ORACLE_DSN") or f"localhost:1521/{pdb}",
        jwt_secret=env.get("WEB_JWT_SECRET") or secrets.token_urlsafe(48),
        # Biến môi trường (không phải .env) để kiểm thử ép pool 1 kết nối
        pool_max=int(os.environ.get("WEB_POOL_MAX") or env.get("WEB_POOL_MAX") or 8),
    )
