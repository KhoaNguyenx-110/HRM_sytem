# Ứng dụng web HRM (GĐ 7)

Ba lớp: giao diện React + Motion (`web/ui`, bước 7c) → Web API FastAPI (`web/api`) → Oracle.
API **mỏng**: không chứa nghiệp vụ, chỉ gọi package `HRM_OWNER.pkg_*` và đọc view `VW-xx`.
Phân quyền nằm hoàn toàn trong CSDL (HRM_CTX), xem đặc tả mục 8.1, 8.2 và *Thay đổi trong v2.3*.

## Cài đặt (một lần)

```bash
cd web/api
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt     # Linux/macOS: .venv/bin/python
```

Mật khẩu đọc từ `.env` ở gốc dự án (`HRM_APP_PASSWORD`, `DEMO_USER_PASSWORD`). Tùy chọn:
`WEB_JWT_SECRET` (thiếu thì sinh ngẫu nhiên mỗi lần khởi động, mọi người phải đăng nhập lại).

Giao diện (Node 18+):

```bash
cd web/ui && npm install
```

## Chạy

```bash
web/chay_web.sh --demo     # dựng lại CSDL demo, đặt mật khẩu web, chạy API (8000) + giao diện (5173)
web/chay_web.sh            # giữ dữ liệu hiện tại
```

Mở http://localhost:5173. Tài liệu API tự sinh: http://localhost:8000/docs.
Mật khẩu web của mọi tài khoản demo = `DEMO_USER_PASSWORD` trong `.env`.

## Giao diện (`web/ui`)

React 18 + React Router + [Motion](https://motion.dev) (chỉ cho hộp thoại và thông báo). Vite chuyển `/api` sang FastAPI nên trình duyệt chỉ thấy
một nguồn (cookie `SameSite=Strict` hoạt động, không cần CORS).

| Màn hình | Vai trò thấy menu | Nguồn dữ liệu |
|---|---|---|
| Tổng quan | mọi người (ô số liệu theo vai trò) | /toi/*, /duyet, /danh-muc/KY_LUONG, /hop-dong/sap-het-han, /tai-khoan |
| Phiếu lương | có hồ sơ nhân viên | /toi/phieu-luong (chỉ kỳ đã khóa) |
| Nghỉ phép & OT | có hồ sơ nhân viên | /toi/phep, /toi/yeu-cau, /toi/nghi-phep, /toi/ot |
| Hồ sơ của tôi | có hồ sơ nhân viên | /toi/ho-so |
| Duyệt yêu cầu | MANAGER, HR | /duyet |
| Nhân viên | HR (thêm, sửa, hợp đồng, điều chuyển, nghỉ việc), MANAGER (chỉ xem phòng mình) | /nhan-vien |
| Kỳ lương | HR (chốt công, xem công), PAYROLL (tạo, chuyển thưởng, phát sinh, tính, khóa, bảng lương, phiếu) | /danh-muc/KY_LUONG, /ky-luong/*, /cong |
| Tài khoản | ADMIN | /tai-khoan, /danh-ba |
| Nhật ký | ADMIN, HR, PAYROLL (mỗi người phần của mình) | /nhat-ky |

Menu ẩn/hiện theo vai trò chỉ để dễ dùng; **quyền thật nằm trong CSDL** (gọi thẳng API không có quyền vẫn bị từ chối).

Phong cách: tông xanh lá (#1E6B3A) và trắng, phẳng, không gradient; phông Inter (trung tính, đủ dấu tiếng Việt,
số cùng độ rộng cho cột tiền). Chuyển động tối thiểu: chỉ hộp thoại, thông báo và thẻ yêu cầu vừa duyệt mờ dần 0,12 s
(Motion); không có hiệu ứng trang trí. `MotionConfig reducedMotion="user"` tắt cả phần này khi hệ điều hành bật
"giảm chuyển động". Màu viết dạng biến CSS trong `web/ui/src/styles.css`.
`nv005` (HR), `nv006` (HR), `nv012` (Payroll), `nv004` (trưởng phòng Nhân sự + HR), `nv033` (trưởng phòng Kỹ thuật),
`admin`, `nv_khoa` (bị khóa).

## Endpoint (đầy đủ ở /docs)

| Nhóm | Endpoint | Gọi xuống CSDL |
|---|---|---|
| Xác thực | `POST /api/dang-nhap`, `/dang-xuat`, `GET /api/toi`, `POST /api/toi/doi-mat-khau` | pkg_auth, pkg_ctx |
| Cá nhân | `GET /api/toi/ho-so · phieu-luong · phep · cong · yeu-cau`; `POST /api/toi/nghi-phep`, `/nghi-phep/{id}/rut`, `/ot` | VW-01, 05, 02, 03, 11, 12; pkg_leave, pkg_att |
| Duyệt | `GET /api/duyet`, `POST /api/duyet/{NGHI_PHEP·OT·KHEN_THUONG·PHAT_SINH_LUONG}/{ma}`, `GET /api/phong/nhan-su` | VW-08, VW-07; pkg_leave, pkg_att, pkg_hr |
| Nhân sự | `GET/POST /api/nhan-vien`, `GET/PATCH /api/nhan-vien/{ma}`, `POST …/dieu-chuyen · nghi-viec · hop-dong`, `POST /api/hop-dong/{so}/dieu-chinh-luong`, `GET /api/hop-dong/sap-het-han · /cong · /nghi-phep · /phep-con-lai`, `POST /api/ky-luong/{nam}/{thang}/chot-cong` | VW-01, 02, 03, 06, 12, 14; pkg_hr, pkg_att |
| Lương | `POST /api/ky-luong`, `…/{nam}/{thang}/tinh · khoa`, `GET …/bang-luong · phieu/{ma}`, `POST /api/phat-sinh`, `/phat-sinh/chuyen-thuong` | VW-04, VW-05; pkg_payroll |
| Quản trị | `GET/POST /api/tai-khoan`, `POST …/{ten}/khoa · mo`, `POST/DELETE …/{ten}/vai-tro/{ma}`, `GET /api/danh-ba · /nhat-ky` | VW-09, 10, 13; pkg_admin |
| Danh mục | `GET /api/danh-muc/{PHONG_BAN·CHUC_VU·LOAI_NGHI_PHEP·LICH_LAM_VIEC·LOAI_HOP_DONG·LOAI_KHOAN_LUONG·KY_LUONG·VAI_TRO}` | pkg_danh_muc (SP-29) |

Cùng một endpoint, người khác vai trò thấy dữ liệu khác nhau (vd `GET /api/nhan-vien`: HR thấy tất cả,
trưởng phòng thấy phòng mình, nhân viên thấy chính mình, Admin thấy rỗng) vì **view** lọc theo HRM_CTX.

## Kiểm thử

```bash
tests/run_web.sh          # TC-56 (SQL, user HRM_APP) + TC-57 (xác thực, pool 1 kết nối) + TC-58 (luồng nghiệp vụ)
                          # + TC-59 (bấm thật trên Microsoft Edge qua Playwright; API 8001, Vite 5174)
tests/run_web.sh --bo-ui  # máy không có Edge/Node: bỏ TC-59
```

## Vòng đời một request (điểm hay bị hỏi khi bảo vệ)

1. Cookie httpOnly chứa token ký HMAC, chỉ mang `tai_khoan_id`; vai trò KHÔNG nằm trong token.
2. Lấy kết nối `HRM_APP` từ pool → `pkg_ctx.dat_phien(tai_khoan_id)`: CSDL đọc lại trạng thái và vai trò từ bảng
   (tài khoản bị khóa giữa phiên bị chặn ngay ở request kế tiếp).
3. Gọi package / đọc view; endpoint ghi tự `commit`.
4. `finally`: rollback phần dở dang, `pkg_ctx.xoa_phien`, trả kết nối. Không xóa được → loại kết nối khỏi pool.

`tests/test_pool.py` ép pool còn 1 kết nối để chứng minh bước 4: các người dùng xen kẽ trên CÙNG một phiên Oracle
mà không ai thấy danh tính của người trước.
