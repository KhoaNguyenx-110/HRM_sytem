"""Hạ tầng kiểm thử API (GĐ 7).

- Pool bị ép còn 1 kết nối (WEB_POOL_MAX=1): mọi request dùng CHUNG một phiên
  Oracle, nên nếu danh tính bị sót lại giữa hai request thì kiểm thử sẽ thấy.
- Mật khẩu đọc từ .env, không in ra.
- Cần CSDL demo đã dựng và đã chạy cong_cu/dat_mat_khau_demo.py (tests/run_web.sh lo).
"""
import os
from pathlib import Path

import oracledb
import pytest
from dotenv import dotenv_values

os.environ["WEB_POOL_MAX"] = "1"

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

GOC = Path(__file__).resolve().parents[3]
ENV = dotenv_values(GOC / ".env")
MK_DEMO = ENV["DEMO_USER_PASSWORD"]
DSN = ENV.get("ORACLE_DSN") or f"localhost:1521/{ENV.get('ORACLE_PDB') or 'FREEPDB1'}"


@pytest.fixture(scope="session")
def client():
    with TestClient(app) as c:
        yield c


def dang_nhap(client, ten: str, mat_khau: str = MK_DEMO) -> dict:
    """Đăng nhập, trả cookie phiên (dict) để gửi kèm các request sau."""
    client.cookies.clear()
    r = client.post("/api/dang-nhap", json={"ten_dang_nhap": ten, "mat_khau": mat_khau})
    assert r.status_code == 200, r.text
    cookie = dict(client.cookies)
    client.cookies.clear()
    return cookie


def goi(client, phuong_thuc: str, url: str, cookie: dict | None = None, **kw):
    """Gửi request với đúng cookie của một người dùng (không để lẫn cookie)."""
    client.cookies.clear()
    if cookie:
        client.cookies.update(cookie)
    try:
        return client.request(phuong_thuc, url, **kw)
    finally:
        client.cookies.clear()


def admin_lam(thu_tuc: str, tham_so: list):
    """Thao tác quản trị trực tiếp qua HRM_APP + danh tính admin (dọn dữ liệu kiểm thử),
    đi đúng kênh web chứ không dùng HRM_OWNER."""
    with oracledb.connect(user="hrm_app", password=ENV["HRM_APP_PASSWORD"], dsn=DSN) as conn:
        cur = conn.cursor()
        v_id, v_bam, v_tt = cur.var(int), cur.var(str), cur.var(str)
        cur.callproc("hrm_owner.pkg_auth.lay_thong_tin_xac_thuc", ["admin", v_id, v_bam, v_tt])
        cur.callproc("hrm_owner.pkg_ctx.dat_phien", [v_id.getvalue()])
        cur.callproc(f"hrm_owner.{thu_tuc}", tham_so)
        conn.commit()
        cur.callproc("hrm_owner.pkg_ctx.xoa_phien")
