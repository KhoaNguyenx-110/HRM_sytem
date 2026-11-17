#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bo kiem thu bao mat giai doan 3. Moi ca chay bang dung user theo muc 12.2,
# khong dung HRM_OWNER de ket luan phan quyen (muc 8.2).
# Dung: tests/run_security.sh
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."

chay() {   # $1 = user, $2 = file
  echo "--- $2  (user $1)"
  scripts/run.sh "$1" "$2" 2>&1 | grep -E 'PASS|FAIL|ORA-|PLS-|SP2-|\[' || true
}

chay U_TP_NS   tests/security/tc01_dang_nhap_nhieu_vai_tro.sql
chay U_NV_KHOA tests/security/tc05_tai_khoan_khoa.sql
chay U_NV_A    tests/security/tc07_chong_gia_danh.sql
chay HRM_APP   tests/security/tc_kenh_web.sql
echo "--- Khoi phuc du lieu"
scripts/run.sh owner tests/security/restore.sql
