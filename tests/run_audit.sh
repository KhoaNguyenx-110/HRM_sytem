#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bo kiem thu TC-52 (audit: NFR-11, NFR-15, BR-34).
# Dung lai CSDL + du lieu luong demo (ky 01, 02 DA_KHOA; 03 tam tinh), roi:
#   U_HR01 sua ho so / muc luong / han muc   (TC-13, TC-14)
#   U_PAY01 lap phat sinh -> U_HR02 duyet     (TC-34)
#   U_PAY01 tinh lai, khoa ky 03              (TC-42)
#   doi chieu audit bang U_HR01, U_PAY01; thu xoa nhat ky bang U_HR01, U_PAY01, owner.
#   tests/run_audit.sh          chay va tra CSDL ve du lieu mau
#   tests/run_audit.sh --giu    giu trang thai sau kiem thu
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."

chay() {   # $1 = user, $2 = file
  echo "--- $2  (user $1)"
  scripts/run.sh "$1" "$2" 2>&1 | grep -E 'PASS|FAIL|ORA-|PLS-|SP2-|^Da |^TK ' || true
}

echo "=== Dung lai CSDL va du lieu luong demo"
scripts/rebuild.sh > /dev/null 2>&1 || { echo "FAIL  rebuild"; exit 1; }
scripts/demo_luong.sh

echo "=== TC-52: thao tac nhay cam"
chay U_HR01  tests/audit/tc52_1_hr01.sql
chay U_PAY01 tests/audit/tc52_2_pay01.sql
chay U_HR02  tests/audit/tc52_3_hr02.sql
chay U_PAY01 tests/audit/tc52_4_pay01.sql
echo "=== TC-52: doi chieu audit va thu xoa"
chay U_HR01  tests/audit/tc52_5_hr01_kiem_tra.sql
chay U_PAY01 tests/audit/tc52_6_pay01_kiem_tra.sql
chay owner   tests/audit/tc52_7_owner.sql

if [[ "${1:-}" != "--giu" ]]; then
  echo "=== Tra CSDL ve du lieu mau"
  scripts/rebuild.sh > /dev/null 2>&1 && echo "Da dung lai CSDL" || echo "FAIL  rebuild cuoi"
fi
