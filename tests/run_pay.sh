#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bo kiem thu giai doan 4c (luong, khen thuong/ky luat): TC-31..TC-46, TR-02, TR-04.
# Moi ca chay bang dung user theo muc 12.5.
#
# Cac ca phu thuoc trang thai ky (MO -> CHOT_CONG -> DA_TINH -> DA_KHOA), nen
# bo nay tu dung lai CSDL tu dau (scripts/rebuild.sh, ~15 giay), chay theo thu tu,
# roi dung lai lan nua de tra CSDL ve du lieu mau.
#   tests/run_pay.sh          chay va tra ve du lieu mau
#   tests/run_pay.sh --giu    giu trang thai sau kiem thu (ky 01 DA_KHOA, ky 02
#                             DA_TINH) de xem trong DBeaver
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."

chay() {   # $1 = user, $2 = file
  echo "--- $2  (user $1)"
  scripts/run.sh "$1" "$2" 2>&1 | grep -E 'PASS|FAIL|ORA-|PLS-|SP2-|Danh sach loi|^Da ' || true
}

echo "=== Dung lai CSDL tu dau"
scripts/rebuild.sh > /dev/null 2>&1 || { echo "FAIL  rebuild"; exit 1; }

echo "=== TC-31, TC-35: tao ky, tinh khi chua chot cong"
chay U_PAY01 tests/pay/tc31_35_pay01.sql
chay U_HR01  tests/pay/tc35_45_hr01.sql
chay U_HR02  tests/pay/tc45_hr02.sql
echo "=== TC-35b, TC-33, TC-45, TC-34a: truoc khi tinh"
chay U_PAY01 tests/pay/tc32_33_34_45_pay01.sql
echo "=== TC-36, TC-37: tinh ky 01/2026, vi du muc 9.8"
chay U_PAY01 tests/pay/tc36_37_pay01.sql
echo "=== TC-39: tinh lai cung dau vao"
chay U_PAY01 tests/pay/tc39_pay01.sql
echo "=== TC-40: loi giua lan tinh lai"
chay owner   tests/pay/tc40_setup_owner.sql
chay U_PAY01 tests/pay/tc40_pay01.sql
chay owner   tests/pay/tc40_cleanup_owner.sql
echo "=== TC-34c, TC-38: phat sinh sau khi tinh, net am"
chay U_PAY01 tests/pay/tc34_38_pay01_lap.sql
chay U_HR02  tests/pay/tc38_hr02.sql
chay U_PAY01 tests/pay/tc38_pay01_tinh.sql
chay owner   tests/pay/tc38_cleanup_owner.sql
echo "=== TC-42, TC-34b, TC-45b: khoa ky va sau khoa"
chay U_PAY01 tests/pay/tc42_pay01.sql
chay owner   tests/pay/tc42_owner.sql
echo "=== TC-32: chinh sach theo phien ban"
chay U_PAY01 tests/pay/tc32_pay01.sql

echo "=== TC-41: hai phien cung tinh ky 02/2026"
( scripts/run.sh U_PAY01 tests/pay/tc41_phien1.sql 2>&1 | grep -E 'PASS|FAIL|ORA-' ) &
sleep 2
scripts/run.sh U_PAY01 tests/pay/tc41_phien2.sql 2>&1 | grep -E 'PASS|FAIL|ORA-'
wait
chay U_PAY01 tests/pay/tc41_kiem_tra_pay01.sql

echo "=== TC-43: nhan vien xem phieu"
chay U_NV_A  tests/pay/tc43_nv_a.sql
echo "=== TC-46: ky luat khong sinh khoan luong"
chay U_HR01  tests/pay/tc46_hr01.sql
chay owner   tests/pay/tc46_owner.sql

if [[ "${1:-}" != "--giu" ]]; then
  echo "=== Tra CSDL ve du lieu mau"
  scripts/rebuild.sh > /dev/null 2>&1 && echo "Da dung lai CSDL" || echo "FAIL  rebuild cuoi"
fi
