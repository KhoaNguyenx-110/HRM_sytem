# HRM-system: Quản lý nhân sự và tính lương trên Oracle

Đồ án môn Hệ quản trị cơ sở dữ liệu. Toàn bộ nghiệp vụ nằm trong Oracle (schema `HRM_OWNER`): 32 bảng, 9 package, 22 trigger, 14 view tự lọc theo người đăng nhập. Bên ngoài là một Web API FastAPI mỏng và giao diện React. Đặc tả, biên bản nghiệm thu và kiến trúc chi tiết nằm trong `docs/`.

```
Trình duyệt ──> Vite :5173 ──/api──> FastAPI :8000 ──HRM_APP──> Oracle 26ai Free (Docker, PDB FREEPDB1)
DBeaver ─────────────────────────────── user demo U_* ─────────┘
```

Dưới đây là cách dựng lại mọi thứ trên một máy mới. Lần đầu mất khoảng 20–30 phút, phần lớn là thời gian tải image Oracle và chờ CSDL khởi tạo.

## Cần cài trước

| Công cụ | Ghi chú |
|---|---|
| Docker Desktop (hoặc Docker Engine) | Image Oracle nặng vài GB; nhớ chừa chỗ trống ổ đĩa |
| Git Bash (Windows) | Mọi script là bash. Trên Linux/macOS dùng terminal bình thường |
| Python 3.10 trở lên | Cho Web API |
| Node.js 18 trở lên | Cho giao diện |
| DBeaver (không bắt buộc) | Nếu muốn thử kênh truy cập trực tiếp bằng user Oracle |

## 1. Lấy mã nguồn và tạo `.env`

```bash
git clone <địa chỉ repo> HRM-system
cd HRM-system
cp .env.example .env
```

Mở `.env` và điền 4 mật khẩu. Bạn tự chọn, miễn là chỉ có chữ, số, dấu gạch dưới và dài từ 8 ký tự. File này đã nằm trong `.gitignore`, *đừng* commit nó.

Trên Windows, lưu `.env` với ký tự xuống dòng LF. Nếu là CRLF, bash sẽ đọc dính ký tự `\r` vào cuối mật khẩu và đăng nhập Oracle thất bại mà không báo lý do rõ ràng.

## 2. Chạy Oracle trong Docker

```bash
docker run -d --name oracle23ai \
  -p 1521:1521 \
  -e ORACLE_PWD=<mật khẩu SYS tùy chọn> \
  -v oracle-data:/opt/oracle/oradata \
  container-registry.oracle.com/database/free:latest
```

Lần đầu Oracle tự tạo CSDL, mất vài phút. Chờ đến khi `docker ps` hiện `(healthy)` rồi mới sang bước sau. Các script kết nối SYS bằng `/ as sysdba` ngay trong container, nên mật khẩu SYS ở trên không cần ghi vào `.env`.

Muốn đặt tên container khác `oracle23ai` thì sửa `ORACLE_CONTAINER` trong `.env` cho khớp.

## 3. Dựng CSDL

```bash
scripts/rebuild.sh
```

Script tạo user `HRM_OWNER`, context `HRM_CTX`, 5 role `R_*` và user `HRM_APP`, rồi chạy `install.sql` (bảng, PL/SQL, view, cấp quyền) và `seed.sql` (dữ liệu demo 50 nhân viên). Cuối cùng nó tạo 11 user Oracle demo `U_*`. Có dòng nào báo `FAIL`, `ORA-` hay `PLS-` thì dừng lại xem trước khi đi tiếp.

Muốn có sẵn dữ liệu lương để xem phiếu và báo cáo (kỳ 01, 02/2026 đã khóa, kỳ 03/2026 tạm tính), chạy thêm:

```bash
scripts/demo_luong.sh
```

## 4. Cài và chạy ứng dụng web

Phần này chỉ cần làm một lần:

```bash
cd web/api
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt   # Linux/macOS: .venv/bin/python
cd ../ui
npm install
cd ../..
```

Sau đó mỗi lần muốn chạy:

```bash
web/chay_web.sh          # giữ dữ liệu hiện có
web/chay_web.sh --demo   # dựng lại CSDL demo từ đầu rồi mới chạy
```

Mở http://localhost:5173. Tài liệu API tự sinh có ở http://localhost:8000/docs. Ctrl+C để tắt cả API lẫn giao diện.

Mọi tài khoản demo trên web dùng chung mật khẩu là giá trị `DEMO_USER_PASSWORD` trong `.env`:

| Tài khoản | Vai trò |
|---|---|
| `admin` | Quản trị tài khoản (không xem được lương) |
| `nv005`, `nv006` | HR |
| `nv012` | Payroll |
| `nv004` | Trưởng phòng Nhân sự, kiêm HR |
| `nv033` | Trưởng phòng Kỹ thuật |
| `nv_a`, `nv_b` | Nhân viên phòng Kỹ thuật |
| `nv_khoa` | Tài khoản bị khóa, dùng để thử đăng nhập bị từ chối |

Có một chỗ hay vấp: `scripts/rebuild.sh` đưa mật khẩu web về chuỗi giữ chỗ, nên sau khi rebuild sẽ không đăng nhập web được. Chạy `web/chay_web.sh` là được, vì nó đặt lại mật khẩu demo trước khi bật server.

## 5. (Tùy chọn) Kết nối bằng DBeaver

Host `localhost`, port `1521`, service name `FREEPDB1`. Đăng nhập bằng một user demo như `U_HR01`, `U_PAY01`, `U_TP_KT`, `U_NV_A` hay `U_ADMIN`, mật khẩu là `DEMO_USER_PASSWORD`. Mỗi user chỉ thấy đúng phần dữ liệu của vai trò mình, vì trigger đăng nhập TR-05 gắn danh tính và các view tự lọc theo đó. Truy vấn mẫu QR-01 đến QR-24 nằm trong `queries/`.

## Kiểm thử

```bash
tests/run_nghiem_thu.sh                 # đủ 59 ca kiểm thử, khoảng 15 phút
tests/run_nghiem_thu.sh --bo-hieu-nang  # bỏ TC-54, TC-55, khoảng 5 phút
tests/run_web.sh --bo-ui                # riêng kênh web, bỏ phần bấm trình duyệt
```

Kết quả ghi vào `tests/ket_qua/`. Bộ nghiệm thu dựng lại CSDL nhiều lần, nên đừng chạy khi đang cần giữ dữ liệu. TC-59 bấm thật trên Microsoft Edge qua Playwright; máy không có Edge thì dùng `--bo-ui`. TC-55 tự chuyển CSDL sang ARCHIVELOG, xóa thử một datafile rồi khôi phục bằng RMAN. Bản sao lưu được chép ra thư mục `backup/` (đã ignore), có thể nặng vài GB.

## Cấu trúc thư mục

| Thư mục | Nội dung |
|---|---|
| `security/` | Script SYS: user, context, role, cấp quyền, user demo |
| `ddl/` | Domain, bảng, khóa ngoại, index |
| `plsql/` | Function, package, trigger, view, đánh số theo thứ tự biên dịch |
| `seed/` | Dữ liệu danh mục và demo; `seed/perf/` cho kiểm thử hiệu năng |
| `queries/` | QR-01 đến QR-24 |
| `tests/` | Kịch bản TC-01 đến TC-59 và kết quả lần chạy gần nhất |
| `web/api`, `web/ui` | FastAPI và React, chi tiết trong `web/README.md` |
| `scripts/` | Chạy SQL, dựng lại CSDL, sao lưu, xuất CSV |
| `docs/` | Đặc tả yêu cầu, biên bản nghiệm thu |

## Gỡ lỗi nhanh

- **Cổng 1521, 8000 hoặc 5173 đã bị chiếm.** Tắt chương trình đang dùng cổng đó, hoặc đổi cổng khi `docker run` rồi đặt `ORACLE_DSN` trong `.env`.
- **`scripts/run.sh` báo `ORA-01017` (sai tên hoặc mật khẩu).** Thường do `.env` có CRLF hoặc ký tự đặc biệt trong mật khẩu. Sửa lại rồi chạy `scripts/rebuild.sh`.
- **Script báo `$'\r': command not found`.** File `.sh` bị đổi sang CRLF. Repo đã có `.gitattributes` để tránh chuyện này; nếu vẫn gặp (ví dụ do giải nén từ file zip) thì chạy `sed -i 's/\r$//' <file>` cho file bị lỗi, hoặc clone lại bằng Git.
- **Đăng nhập web báo sai mật khẩu ngay sau khi rebuild.** Xem lại mục 4: chạy `web/chay_web.sh`.
