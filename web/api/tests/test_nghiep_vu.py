"""Luồng nghiệp vụ đầu-cuối qua API, đúng vai trò (TC-58, GĐ 7b).

Các hàm chạy THEO THỨ TỰ trong file (cùng một CSDL demo vừa dựng lại):
  1. danh mục theo vai trò
  2. lương 01/2026: HR chốt công -> Payroll chuyển thưởng, tính -> đúng net 35.635.200
     của ví dụ 9.8 (TC-36) -> khóa -> NV_A mới thấy phiếu
  3. nghỉ phép + OT: NV_B đăng ký, trưởng phòng Kỹ thuật duyệt / từ chối, rút đơn
  4. HR: thêm nhân viên, hợp đồng, chồng lấn bị chặn; phạm vi xem theo vai trò
  5. Admin: cấp tài khoản, gán/thu vai trò, nhật ký
Mọi kiểm tra phân quyền là kết quả CSDL trả về (API không tự kiểm tra vai trò).
"""
from conftest import dang_nhap, goi

NET_VD98 = 35_635_200          # đáp án ví dụ 9.8 / TC-36 cho NV_A tháng 01/2026
_ck: dict[str, dict] = {}


def ck(client, ten):
    """Cookie phiên của từng tài khoản (đăng nhập một lần)."""
    if ten not in _ck:
        _ck[ten] = dang_nhap(client, ten)
    return _ck[ten]


def get(client, ten, url, **kw):
    return goi(client, "GET", url, ck(client, ten) if ten else None, **kw)


def post(client, ten, url, json=None):
    return goi(client, "POST", url, ck(client, ten), json=json or {})


# ---------------------------------------------------------------------------
def test_1_danh_muc_theo_vai_tro(client):
    r = get(client, "nv_a", "/api/danh-muc/PHONG_BAN")
    assert r.status_code == 200 and {d["ma_phong_ban"] for d in r.json()} >= {"KY_THUAT", "NHAN_SU"}
    assert get(client, "nv_a", "/api/danh-muc/VAI_TRO").status_code == 403
    assert get(client, "nv_a", "/api/danh-muc/KY_LUONG").status_code == 403
    assert len(get(client, "admin", "/api/danh-muc/VAI_TRO").json()) == 5
    r = get(client, "nv_a", "/api/danh-muc/LICH_LAM_VIEC")          # thiếu năm -> -20022
    assert r.status_code == 400 and r.json()["ma"] == "ORA-20022"
    assert len(get(client, "nv_a", "/api/danh-muc/LICH_LAM_VIEC", params={"nam": 2026}).json()) == 365
    assert get(client, "nv_a", "/api/danh-muc/KHONG_CO").status_code == 422   # FastAPI chặn trước


def test_2_luong_thang_1_den_phieu_nhan_vien(client):
    # Nhân viên không tính lương được (CSDL: -20009)
    assert post(client, "nv_a", "/api/ky-luong/2026/1/tinh").status_code == 403
    # Tính khi chưa chốt công: CSDL từ chối
    r = post(client, "nv012", "/api/ky-luong/2026/1/tinh")
    assert r.status_code in (400, 409), r.text

    r = post(client, "nv005", "/api/ky-luong/2026/1/chot-cong")
    assert r.status_code == 200 and r.json()["so_loi"] == 0, r.text
    r = post(client, "nv012", "/api/phat-sinh/chuyen-thuong",
             {"so_quyet_dinh": "001/2026/QĐ-KT", "thang": 1, "nam": 2026})
    assert r.status_code == 201, r.text
    r = post(client, "nv012", "/api/ky-luong/2026/1/tinh")
    assert r.status_code == 200 and r.json()["so_loi"] == 0, r.text

    bang = get(client, "nv012", "/api/ky-luong/2026/1/bang-luong").json()
    nv_a = next(d for d in bang if d["ma_nhan_vien"] == "NV_A")
    assert nv_a["tong_net"] == NET_VD98
    assert get(client, "nv_a", "/api/ky-luong/2026/1/bang-luong").json() == []   # VW-04: chỉ Payroll
    assert get(client, "nv005", "/api/ky-luong/2026/1/bang-luong").json() == []  # HR cũng không

    assert get(client, "nv_a", "/api/toi/phieu-luong").json() == []        # chưa khóa: chưa thấy
    assert post(client, "nv012", "/api/ky-luong/2026/1/khoa").status_code == 200
    phieu = get(client, "nv_a", "/api/toi/phieu-luong", params={"nam": 2026}).json()
    assert len(phieu) == 1 and phieu[0]["tong_net"] == NET_VD98
    assert {k["ma_khoan"] for k in phieu[0]["khoan"]} >= {"LUONG_CONG", "THUONG", "BHXH_NLD", "THUE_TNCN"}
    # Đồng nghiệp không xem được phiếu của NV_A
    assert get(client, "nv_b", "/api/ky-luong/2026/1/phieu/NV_A").json() is None

    # Kỳ đã chốt: không còn đăng ký nghỉ vào tháng 01 (TC-30 / -20301)
    r = post(client, "nv_a", "/api/toi/nghi-phep", {"ma_loai": "PHEP_NAM", "tu_ngay": "2026-01-26",
                                                     "den_ngay": "2026-01-26", "ly_do": "thử"})
    assert r.status_code == 409 and r.json()["ma"] == "ORA-20301"


def test_3_nghi_phep_ot_duyet(client):
    con_truoc = get(client, "nv_b", "/api/toi/phep", params={"nam": 2026}).json()[0]["so_ngay_con_lai"]
    r = post(client, "nv_b", "/api/toi/nghi-phep", {"ma_loai": "PHEP_NAM", "tu_ngay": "2026-04-06",
                                                     "den_ngay": "2026-04-07", "ly_do": "Việc gia đình"})
    assert r.status_code == 201, r.text
    don = r.json()["don_nghi_id"]
    yc = get(client, "nv_b", "/api/toi/yeu-cau").json()
    assert any(d["ma_yeu_cau"] == don and d["trang_thai"] == "CHO_DUYET" for d in yc)

    # Đồng nghiệp không thấy, không duyệt được; trưởng phòng Kỹ thuật thì có
    assert all(d["ma_yeu_cau"] != don for d in get(client, "nv_a", "/api/duyet").json())
    assert post(client, "nv_a", f"/api/duyet/NGHI_PHEP/{don}", {"dong_y": True}).status_code == 403
    assert any(d["loai_yeu_cau"] == "NGHI_PHEP" and d["ma_yeu_cau"] == don
               for d in get(client, "nv033", "/api/duyet").json())
    assert post(client, "nv033", f"/api/duyet/NGHI_PHEP/{don}", {"dong_y": True}).status_code == 200

    yc = get(client, "nv_b", "/api/toi/yeu-cau").json()
    assert next(d for d in yc if d["ma_yeu_cau"] == don)["trang_thai"] == "DA_DUYET"
    con_sau = get(client, "nv_b", "/api/toi/phep", params={"nam": 2026}).json()[0]["so_ngay_con_lai"]
    assert con_truoc - con_sau == 2

    # OT: từ chối phải có ý kiến? (OT không bắt buộc) - từ chối và kiểm tra trạng thái
    r = post(client, "nv_b", "/api/toi/ot", {"bat_dau": "2026-04-08T18:00:00", "ket_thuc": "2026-04-08T20:00:00",
                                              "ly_do": "Triển khai bản vá"})
    assert r.status_code == 201, r.text
    ot = r.json()["tang_ca_id"]
    assert post(client, "nv033", f"/api/duyet/OT/{ot}", {"dong_y": False, "y_kien": "Không cần"}).status_code == 200
    assert next(d for d in get(client, "nv_b", "/api/toi/yeu-cau").json()
                if d["loai_yeu_cau"] == "OT" and d["ma_yeu_cau"] == ot)["trang_thai"] == "TU_CHOI"

    # Rút đơn: chỉ chủ đơn
    don2 = post(client, "nv_b", "/api/toi/nghi-phep", {"ma_loai": "PHEP_NAM", "tu_ngay": "2026-04-09",
                                                        "den_ngay": "2026-04-09", "ly_do": "Đi khám"}).json()["don_nghi_id"]
    assert post(client, "nv_a", f"/api/toi/nghi-phep/{don2}/rut").status_code >= 400
    assert post(client, "nv_b", f"/api/toi/nghi-phep/{don2}/rut").status_code == 200
    assert next(d for d in get(client, "nv_b", "/api/toi/yeu-cau").json()
                if d["ma_yeu_cau"] == don2 and d["loai_yeu_cau"] == "NGHI_PHEP")["trang_thai"] == "DA_RUT"


def test_4_nhan_su(client):
    nv = {"ma_nhan_vien": "NV900", "ho_ten": "Trần Kiểm Thử", "ngay_sinh": "1995-05-05",
          "so_dinh_danh": "001095009009", "ma_so_thue": "8009009009", "email": "nv900@congty.vn",
          "so_dien_thoai": "0909009009", "dia_chi": "Hà Nội", "ngay_vao_lam": "2026-04-01",
          "ma_phong_ban": "KY_THUAT", "ma_chuc_vu": "CHUYEN_VIEN"}
    assert post(client, "nv_a", "/api/nhan-vien", nv).status_code == 403
    r = post(client, "nv005", "/api/nhan-vien", nv)
    assert r.status_code == 201, r.text
    assert len(get(client, "nv005", "/api/nhan-vien", params={"q": "nv900"}).json()) == 1
    r = goi(client, "PATCH", "/api/nhan-vien/NV900", ck(client, "nv005"), json={"email": "tran.kt@congty.vn"})
    assert r.status_code == 200, r.text
    ct = get(client, "nv005", "/api/nhan-vien/NV900").json()
    assert ct["ho_so"]["email"] == "tran.kt@congty.vn" and len(ct["qua_trinh"]) == 1

    hd = {"so_hop_dong": "HD-NV900-01", "ma_loai": "KHONG_XAC_DINH", "ngay_bat_dau": "2026-04-01",
          "luong_co_ban": 18_000_000, "can_cu_dong_bao_hiem": 18_000_000}
    assert post(client, "nv005", "/api/nhan-vien/NV900/hop-dong", hd).status_code == 201
    r = post(client, "nv005", "/api/nhan-vien/NV900/hop-dong", hd | {"so_hop_dong": "HD-NV900-02",
                                                                       "ngay_bat_dau": "2026-06-01"})
    assert r.status_code == 409 and r.json()["ma"] == "ORA-20205"            # chồng lấn

    # Phạm vi xem do view quyết định
    assert [d["ma_nhan_vien"] for d in get(client, "nv_a", "/api/nhan-vien").json()] == ["NV_A"]
    assert get(client, "admin", "/api/nhan-vien").json() == []                 # TC-08
    assert get(client, "nv_a", "/api/nhan-vien/NV_B").status_code == 404
    phong = {d["ma_phong_ban"] for d in get(client, "nv033", "/api/nhan-vien").json()}
    assert phong == {"KY_THUAT"}                                              # trưởng phòng: phòng mình


def test_5_quan_tri(client):
    r = post(client, "nv005", "/api/tai-khoan", {"ten_dang_nhap": "nv900", "mat_khau_tam": "Tam-thoi-2026",
                                                  "ma_nhan_vien": "NV900"})
    assert r.status_code == 403                                                # HR không cấp tài khoản
    r = post(client, "admin", "/api/tai-khoan", {"ten_dang_nhap": "NV900", "mat_khau_tam": "Tam-thoi-2026",
                                                  "ma_nhan_vien": "NV900"})
    assert r.status_code == 201, r.text
    toi = get(client, None, "/api/toi", cookies=None)
    assert toi.status_code == 401
    ck900 = dang_nhap(client, "nv900", "Tam-thoi-2026")
    assert goi(client, "GET", "/api/toi", ck900).json()["vai_tro"] == ["EMPLOYEE"]

    assert post(client, "admin", "/api/tai-khoan/nv900/vai-tro/HR").status_code == 200
    assert set(goi(client, "GET", "/api/toi", ck900).json()["vai_tro"]) == {"EMPLOYEE", "HR"}  # hiệu lực ngay
    assert goi(client, "DELETE", "/api/tai-khoan/nv900/vai-tro/HR", ck(client, "admin")).status_code == 200
    assert goi(client, "GET", "/api/toi", ck900).json()["vai_tro"] == ["EMPLOYEE"]
    assert post(client, "admin", "/api/tai-khoan/admin/vai-tro/HR").status_code >= 400   # không tự nâng quyền

    tk = {d["ten_dang_nhap"]: d for d in get(client, "admin", "/api/tai-khoan").json()}
    assert "nv900" in tk and tk["nv_khoa"]["trang_thai"] == "KHOA"
    assert get(client, "nv005", "/api/tai-khoan").json() == []                 # VW-09 chỉ Admin

    nk_admin = get(client, "admin", "/api/nhat-ky").json()
    assert nk_admin and {d["doi_tuong"] for d in nk_admin} <= {"TAI_KHOAN", "TAI_KHOAN_VAI_TRO"}
    nk_hr = get(client, "nv005", "/api/nhat-ky", params={"doi_tuong": "NHAN_VIEN"}).json()
    assert any(d["ten_dang_nhap"] == "nv005" for d in nk_hr)                   # thao tác ở bước 4, ghi đúng người
    assert get(client, "nv_a", "/api/nhat-ky").json() == []
