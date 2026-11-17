"""Đặt mật khẩu web thật cho các tài khoản dữ liệu mẫu (chỉ môi trường phát triển).

seed/02_demo.sql lưu một chuỗi GIỮ CHỖ đúng định dạng bcrypt nhưng không phải hash
thật (kênh DBeaver xác thực bằng Oracle user nên chưa cần). Kênh web cần hash thật:
công cụ này băm DEMO_USER_PASSWORD (.env) bằng bcrypt và ghi cho MỌI tài khoản còn
chuỗi giữ chỗ -> mật khẩu web = mật khẩu user Oracle demo.

- Chạy bằng HRM_OWNER (công cụ cài đặt, giống seed); ứng dụng không bao giờ dùng owner.
- Chạy lại nhiều lần không sao: tài khoản đã có hash thật (vd đã đổi mật khẩu) giữ nguyên.
- Trigger TR-01 ghi audit "MAT_KHAU: DA_DOI" (không ghi giá trị) cho từng tài khoản.
- Một hash dùng chung cho mọi tài khoản demo (cùng một mật khẩu nên không lộ thêm gì),
  để không mất ~13 s băm 51 lần với chi phí 12.

Chạy: web/api/.venv/Scripts/python web/api/cong_cu/dat_mat_khau_demo.py
"""
import sys
from pathlib import Path

import bcrypt
import oracledb
from dotenv import dotenv_values

GOC = Path(__file__).resolve().parents[3]
GIU_CHO = "$2b$12$DEMO.%"


def main() -> int:
    env = dotenv_values(GOC / ".env")
    mat_khau = env.get("DEMO_USER_PASSWORD")
    if not mat_khau or not env.get("HRM_OWNER_PASSWORD"):
        print("FAIL  thiếu DEMO_USER_PASSWORD hoặc HRM_OWNER_PASSWORD trong .env")
        return 1
    dsn = env.get("ORACLE_DSN") or f"localhost:1521/{env.get('ORACLE_PDB') or 'FREEPDB1'}"
    chuoi_bam = bcrypt.hashpw(mat_khau.encode(), bcrypt.gensalt(12)).decode()
    with oracledb.connect(user="hrm_owner", password=env["HRM_OWNER_PASSWORD"], dsn=dsn) as conn:
        with conn.cursor() as cur:
            cur.execute("update tai_khoan set mat_khau_bam = :h where mat_khau_bam like :g",
                        h=chuoi_bam, g=GIU_CHO)
            so = cur.rowcount
        conn.commit()
    print(f"Da dat mat khau web cho {so} tai khoan demo")
    return 0


if __name__ == "__main__":
    sys.exit(main())
