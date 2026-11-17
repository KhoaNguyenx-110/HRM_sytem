"""Đăng nhập kênh web (đặc tả 8.1 bước 1-5; AUTH-01, AUTH-05; BR-04)."""
from conftest import MK_DEMO, admin_lam, dang_nhap, goi

SAI = "Tên đăng nhập hoặc mật khẩu không đúng."


def test_chua_dang_nhap_bi_tu_choi(client):
    r = goi(client, "GET", "/api/toi")
    assert r.status_code == 401
    assert r.json()["ma"] == "CHUA_DANG_NHAP"


def test_sai_mat_khau_va_ten_khong_ton_tai_cung_mot_cau(client):
    """Không lộ tên đăng nhập nào có thật."""
    r1 = goi(client, "POST", "/api/dang-nhap", json={"ten_dang_nhap": "nv_a", "mat_khau": "sai-roi-123"})
    r2 = goi(client, "POST", "/api/dang-nhap", json={"ten_dang_nhap": "khong_co_ai", "mat_khau": "sai-roi-123"})
    assert (r1.status_code, r2.status_code) == (401, 401)
    assert r1.json()["loi"] == r2.json()["loi"] == SAI
    # Lần đúng sau đó đặt lại bộ đếm sai (ghi_thanh_cong)
    dang_nhap(client, "nv_a")


def test_nhan_vien_danh_tinh_do_csdl_nap(client):
    ck = dang_nhap(client, "NV_A ")          # tên được chuẩn hóa: bỏ khoảng trắng, chữ thường
    r = goi(client, "GET", "/api/toi", ck)
    assert r.status_code == 200
    toi = r.json()
    assert toi["ten_dang_nhap"] == "nv_a"
    assert toi["vai_tro"] == ["EMPLOYEE"]
    assert toi["ho_so"]["ma_nhan_vien"] == "NV_A"


def test_cookie_httponly_samesite(client):
    client.cookies.clear()
    r = client.post("/api/dang-nhap", json={"ten_dang_nhap": "nv_a", "mat_khau": MK_DEMO})
    client.cookies.clear()
    set_cookie = r.headers["set-cookie"].lower()
    assert "httponly" in set_cookie and "samesite=strict" in set_cookie


def test_nhieu_vai_tro_va_admin_khong_co_ho_so(client):
    toi = goi(client, "GET", "/api/toi", dang_nhap(client, "nv004")).json()
    assert set(toi["vai_tro"]) == {"EMPLOYEE", "HR", "MANAGER"}     # TC-01
    toi = goi(client, "GET", "/api/toi", dang_nhap(client, "admin")).json()
    assert toi["vai_tro"] == ["ADMIN"] and toi["ho_so"] is None     # TC-08


def test_tai_khoan_khoa_khong_dang_nhap_duoc(client):
    r = goi(client, "POST", "/api/dang-nhap", json={"ten_dang_nhap": "nv_khoa", "mat_khau": MK_DEMO})
    assert r.status_code == 403 and r.json()["ma"] == "TAI_KHOAN_KHOA"


def test_token_gia_mao_bi_tu_choi(client):
    ck = dang_nhap(client, "nv_a")
    ten = next(iter(ck))
    gia = {ten: ck[ten][:-4] + ("AAAA" if not ck[ten].endswith("AAAA") else "BBBB")}
    r = goi(client, "GET", "/api/toi", gia)
    assert r.status_code == 401 and r.json()["ma"] == "TOKEN_SAI"


def test_nam_lan_sai_lien_tiep_thi_khoa(client):
    """AUTH-05: 4 lần sai, 1 lần đúng (đặt lại bộ đếm), rồi 5 lần sai -> KHOA."""
    ten = "nv040"
    sai = {"ten_dang_nhap": ten, "mat_khau": "sai-mat-khau"}
    try:
        for _ in range(4):
            assert goi(client, "POST", "/api/dang-nhap", json=sai).status_code == 401
        dang_nhap(client, ten)                                     # vẫn vào được
        for _ in range(5):
            assert goi(client, "POST", "/api/dang-nhap", json=sai).status_code == 401
        r = goi(client, "POST", "/api/dang-nhap", json={"ten_dang_nhap": ten, "mat_khau": MK_DEMO})
        assert r.status_code == 403 and r.json()["ma"] == "TAI_KHOAN_KHOA"
    finally:
        admin_lam("pkg_admin.sp_mo_tai_khoan", [ten])


def test_khoa_giua_phien_co_hieu_luc_ngay(client):
    """Token còn hạn nhưng tài khoản vừa bị khóa: request kế tiếp bị chặn (BR-04)."""
    ten = "nv041"
    ck = dang_nhap(client, ten)
    assert goi(client, "GET", "/api/toi", ck).status_code == 200
    try:
        admin_lam("pkg_admin.sp_khoa_tai_khoan", [ten])
        r = goi(client, "GET", "/api/toi", ck)
        assert r.status_code == 401 and r.json()["ma"] == "ORA-20001"
    finally:
        admin_lam("pkg_admin.sp_mo_tai_khoan", [ten])
    assert goi(client, "GET", "/api/toi", ck).status_code == 200


def test_doi_mat_khau(client):
    ten, moi = "nv_c", "Mat-khau-moi-2026"
    ck = dang_nhap(client, ten)
    r = goi(client, "POST", "/api/toi/doi-mat-khau", ck, json={"mat_khau_cu": "sai", "mat_khau_moi": moi})
    assert r.status_code == 400
    r = goi(client, "POST", "/api/toi/doi-mat-khau", ck, json={"mat_khau_cu": MK_DEMO, "mat_khau_moi": "ngan"})
    assert r.status_code == 400
    r = goi(client, "POST", "/api/toi/doi-mat-khau", ck, json={"mat_khau_cu": MK_DEMO, "mat_khau_moi": moi})
    assert r.status_code == 200, r.text
    r = goi(client, "POST", "/api/dang-nhap", json={"ten_dang_nhap": ten, "mat_khau": MK_DEMO})
    assert r.status_code == 401                                   # mật khẩu cũ hết hiệu lực
    ck = dang_nhap(client, ten, moi)
    # Trả lại mật khẩu demo cho các kiểm thử khác
    r = goi(client, "POST", "/api/toi/doi-mat-khau", ck, json={"mat_khau_cu": moi, "mat_khau_moi": MK_DEMO})
    assert r.status_code == 200
