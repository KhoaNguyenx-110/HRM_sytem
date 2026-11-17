"""Danh tính không rò rỉ qua pool kết nối (đặc tả 8.1 bước 5).

Pool chỉ có 1 kết nối (conftest), nên mọi request đều dùng CÙNG một phiên Oracle
(cùng SID). Sau mỗi request - kể cả request lỗi giữa chừng - phiên đó phải không
còn danh tính, và người kế tiếp chỉ thấy dữ liệu của chính mình.
"""
from app import csdl
from conftest import dang_nhap, goi


def _trang_thai_phien(client) -> tuple[str, str | None]:
    """(SID, TAI_KHOAN_ID trong HRM_CTX) của kết nối duy nhất trong pool."""
    async def doc():
        conn = await csdl.pool().acquire()
        try:
            async with conn.cursor() as cur:
                await cur.execute("select sys_context('USERENV', 'SID'), "
                                  "sys_context('HRM_CTX', 'TAI_KHOAN_ID') from dual")
                return await cur.fetchone()
        finally:
            await csdl.pool().release(conn)
    return client.portal.call(doc)


def test_pool_mot_ket_noi(client):
    assert client.app.state.cau_hinh.pool_max == 1


def test_xen_ke_nguoi_dung_tren_cung_mot_phien(client):
    ck_a, ck_admin = dang_nhap(client, "nv_a"), dang_nhap(client, "admin")
    sid_dau, _ = _trang_thai_phien(client)
    for _ in range(5):
        a = goi(client, "GET", "/api/toi", ck_a).json()
        assert a["ten_dang_nhap"] == "nv_a" and a["vai_tro"] == ["EMPLOYEE"]
        ad = goi(client, "GET", "/api/toi", ck_admin).json()
        assert ad["ten_dang_nhap"] == "admin" and ad["ho_so"] is None
        assert goi(client, "GET", "/api/toi").status_code == 401   # khách: không kế thừa ai
        sid, tk = _trang_thai_phien(client)
        assert sid == sid_dau, "phải là cùng một phiên Oracle thì phép thử mới có nghĩa"
        assert tk is None, "kết nối trả về pool vẫn còn danh tính"


def test_request_loi_giua_chung_van_xoa_danh_tinh(client):
    ck = dang_nhap(client, "nv_a")
    r = goi(client, "POST", "/api/toi/doi-mat-khau", ck,
            json={"mat_khau_cu": "sai-mat-khau", "mat_khau_moi": "Mot-mat-khau-moi"})
    assert r.status_code == 400                     # lỗi xảy ra SAU dat_phien
    assert _trang_thai_phien(client)[1] is None


def test_tai_khoan_khoa_khong_de_lai_danh_tinh(client):
    """dat_phien thất bại (tài khoản KHOA) cũng không để lại danh tính cũ."""
    from conftest import admin_lam
    ck = dang_nhap(client, "nv042")
    try:
        admin_lam("pkg_admin.sp_khoa_tai_khoan", ["nv042"])
        assert goi(client, "GET", "/api/toi", ck).status_code == 401
        assert _trang_thai_phien(client)[1] is None
    finally:
        admin_lam("pkg_admin.sp_mo_tai_khoan", ["nv042"])
