"""TC-59: thao tác thật trên trình duyệt (Playwright + Microsoft Edge có sẵn).

Chỉ chạy khi có WEB_UI_URL (tests/run_web.sh bật API + Vite ở cổng riêng trên CSDL
demo vừa dựng lại rồi đặt biến này). Các hàm chạy theo thứ tự trong file.
Kiểm tra cái người dùng THẤY: chữ trên màn hình, nút, menu - không đọc CSDL trực tiếp.
"""
import os
import re

import pytest

URL = os.environ.get("WEB_UI_URL")
pytestmark = pytest.mark.skipif(not URL, reason="cần WEB_UI_URL (chạy qua tests/run_web.sh)")

if URL:
    from playwright.sync_api import expect, sync_playwright

from conftest import MK_DEMO

NET_VD98 = "35.635.200 đ"


@pytest.fixture(scope="module")
def trinh_duyet():
    with sync_playwright() as p:
        b = p.chromium.launch(channel=os.environ.get("WEB_UI_BROWSER", "msedge"))
        yield b
        b.close()


@pytest.fixture
def mo(trinh_duyet):
    """mo(ten) -> trang đã đăng nhập; ghi lại lỗi JavaScript để kiểm tra cuối."""
    ds, loi = [], []

    def _mo(ten=None, mat_khau=MK_DEMO, rong=1366):
        ctx = trinh_duyet.new_context(viewport={"width": rong, "height": 860}, locale="vi-VN")
        ds.append(ctx)
        pg = ctx.new_page()
        pg.on("pageerror", lambda e: loi.append(str(e)))
        pg.goto(URL)
        if ten:
            dang_nhap(pg, ten, mat_khau)
            expect(pg.locator(".dau-trang")).to_be_visible()
        return pg
    yield _mo
    for c in ds:
        c.close()
    assert not loi, f"lỗi JavaScript: {loi}"


def dang_nhap(pg, ten, mat_khau=MK_DEMO):
    pg.get_by_label("Tên đăng nhập").fill(ten)
    pg.get_by_label("Mật khẩu", exact=True).fill(mat_khau)
    pg.get_by_role("button", name="Đăng nhập").click()


def di(pg, muc):
    """Bấm một mục trên thanh menu (chữ có thể trùng với ô ở trang chủ)."""
    pg.locator(".thanh-ben").get_by_role("link", name=muc, exact=True).click()


def menu(pg):
    pg.wait_for_selector(".thanh-ben nav a")
    return [t.strip() for t in pg.locator(".thanh-ben nav a").all_inner_texts()]


# ---------------------------------------------------------------------------
def test_1_dang_nhap_sai_roi_dung(mo):
    pg = mo()
    dang_nhap(pg, "nv_a", "sai-mat-khau-123")
    expect(pg.locator(".bao-loi")).to_have_text("Tên đăng nhập hoặc mật khẩu không đúng.")
    dang_nhap(pg, "nv_a")
    expect(pg.locator(".dau-trang .ten")).to_have_text("Ngô Minh Linh")
    expect(pg.get_by_role("heading", name=re.compile("Xin chào"))).to_be_visible()


def test_2_menu_theo_vai_tro(mo):
    assert menu(mo("nv_a")) == ["Tổng quan", "Phiếu lương", "Nghỉ phép & OT", "Hồ sơ của tôi"]
    assert menu(mo("admin")) == ["Tổng quan", "Tài khoản", "Nhật ký"]
    m = menu(mo("nv012"))
    assert "Kỳ lương" in m and "Duyệt yêu cầu" not in m and "Tài khoản" not in m
    m = menu(mo("nv033"))
    assert "Duyệt yêu cầu" in m and "Kỳ lương" not in m


def test_3_an_menu_khong_phai_la_bao_mat(mo):
    """Gọi thẳng API (bỏ qua giao diện) bằng phiên của nhân viên: CSDL vẫn từ chối."""
    pg = mo("nv_a")
    r = pg.request.post(f"{URL}/api/ky-luong/2026/2/tinh")
    assert r.status == 403
    assert "không có quyền" in r.json()["loi"]


def test_4_luong_thang_1_qua_giao_dien(mo):
    # HR chốt công
    pg = mo("nv005")
    di(pg, "Kỳ lương")
    pg.get_by_role("button", name="Kỳ 01/2026").click()
    pg.get_by_role("button", name="Chốt công", exact=True).click()
    expect(pg.get_by_text("Đã chốt công, chờ bộ phận Tiền lương")).to_be_visible(timeout=15000)

    # Payroll: chuyển thưởng, tính, xem phiếu NV_A, khóa
    pg = mo("nv012")
    di(pg, "Kỳ lương")
    pg.get_by_role("button", name="Kỳ 01/2026").click()
    pg.get_by_role("button", name="Chuyển thưởng").click()
    pg.get_by_label("Số quyết định khen thưởng").fill("001/2026/QĐ-KT")
    pg.locator(".hop-thoai").get_by_role("button", name="Chuyển").click()
    expect(pg.locator(".toast").last).to_contain_text("Đã chuyển thưởng")
    pg.get_by_role("button", name="Tính lương").click()
    expect(pg.get_by_role("heading", name="Bảng lương")).to_be_visible(timeout=20000)
    pg.locator("td", has_text=re.compile(r"^NV_A$")).click()
    expect(pg.locator(".phieu-net strong")).to_have_text(NET_VD98)
    pg.keyboard.press("Escape")
    pg.get_by_role("button", name="Khóa kỳ").click()
    pg.locator(".hop-thoai").get_by_role("button", name="Khóa kỳ").click()
    expect(pg.get_by_text("Kỳ đã khóa")).to_be_visible(timeout=15000)

    # Nhân viên thấy phiếu của mình
    pg = mo("nv_a")
    di(pg, "Phiếu lương")
    expect(pg.locator(".phieu-net strong")).to_have_text(NET_VD98)
    expect(pg.get_by_text("Thưởng", exact=True)).to_be_visible()


def test_5_dang_ky_nghi_va_truong_phong_duyet(mo):
    pg = mo("nv_b")
    di(pg, "Nghỉ phép & OT")
    pg.get_by_label("Từ ngày").fill("2026-04-20")
    pg.get_by_label("Đến ngày").fill("2026-04-21")
    pg.get_by_label("Lý do").fill("Về quê")
    pg.get_by_role("button", name="Gửi đơn").click()
    expect(pg.locator(".toast").last).to_have_text("Đã gửi đơn, chờ duyệt.")
    expect(pg.get_by_role("row", name="20/04/2026")).to_contain_text("Chờ duyệt")

    tp = mo("nv033")
    di(tp, "Duyệt yêu cầu")
    the = tp.locator(".the-yc", has_text="20/04/2026")
    expect(the).to_contain_text("NV_B")
    the.get_by_role("button", name="Đồng ý").click()
    expect(the).to_have_count(0)                       # thẻ thu lại và biến mất

    pg.reload()
    expect(pg.get_by_role("row", name="20/04/2026")).to_contain_text("Đã duyệt")


def test_6_admin_khoa_va_mo_tai_khoan(mo):
    ad = mo("admin")
    di(ad, "Tài khoản")
    ad.get_by_placeholder(re.compile("Tìm tên đăng nhập")).fill("nv_c")
    dong = ad.get_by_role("row", name=re.compile(r"^nv_c "))
    dong.get_by_role("button", name="Khóa").click()
    expect(dong).to_contain_text("Bị khóa")

    pg = mo()
    dang_nhap(pg, "nv_c")
    expect(pg.locator(".bao-loi")).to_contain_text("Tài khoản đã bị khóa")

    dong.get_by_role("button", name="Mở khóa").click()
    expect(dong).to_contain_text("Hoạt động")
    dang_nhap(pg, "nv_c")
    expect(pg.locator(".dau-trang")).to_be_visible()


def test_7_man_hinh_dien_thoai(mo):
    pg = mo("nv_a", rong=390)
    di(pg, "Nghỉ phép & OT")
    expect(pg.get_by_role("button", name="Gửi đơn")).to_be_visible()
    # Không có thanh cuộn ngang ở cấp trang
    assert pg.evaluate("document.documentElement.scrollWidth") <= 390
