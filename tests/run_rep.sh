#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bo kiem thu giai doan 5 (bao cao): TC-47..TC-51 va QR-05.
# Can ky luong da tinh/khoa, nen bo nay dung lai CSDL + du lieu luong demo
# (ky 01, 02 DA_KHOA; 03 tam tinh), chay, roi dung lai lan nua.
#   tests/run_rep.sh          chay va tra CSDL ve du lieu mau
#   tests/run_rep.sh --giu    giu trang thai sau kiem thu
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."

chay() {   # $1 = user, $2 = file
  echo "--- $2  (user $1)"
  scripts/run.sh "$1" "$2" 2>&1 | grep -E 'PASS|FAIL|ORA-|PLS-|SP2-|^Da |^QUY|^NV024' || true
}
dat() {    # $1 = ten, $2 = 0 neu dat
  if [[ "$2" == 0 ]]; then echo "PASS  $1"; else echo "FAIL  $1"; fi
}

echo "=== Dung lai CSDL va du lieu luong demo"
scripts/rebuild.sh > /dev/null 2>&1 || { echo "FAIL  rebuild"; exit 1; }
scripts/demo_luong.sh

echo "=== TC-47: nhan su tai ngay, hop dong sap het han; QR-05"
chay owner   tests/rep/tc47_setup_owner.sql
chay U_HR01  tests/rep/tc47_hr01.sql
chay U_ADMIN tests/rep/tc47_admin.sql

echo "=== TC-48: cong/phep/OT co don tu choi va da rut (truong phong)"
chay U_TP_KT tests/rep/tc48_tp_kt.sql

echo "=== TC-49: dieu chuyen roi xem quy luong ky cu"
out=$(scripts/run.sh U_PAY01 tests/rep/tc49_pay01.sql 2>&1 | grep -E '^QUY|^NV024|PASS|FAIL'); echo "$out"
truoc=$(echo "$out" | grep '^QUY')
chay U_HR01  tests/rep/tc49_hr01.sql
out=$(scripts/run.sh U_PAY01 tests/rep/tc49_pay01.sql 2>&1 | grep -E '^QUY|^NV024|PASS|FAIL'); echo "$out"
sau=$(echo "$out" | grep '^QUY')
[[ -n "$truoc" && "$truoc" == "$sau" ]]; dat "TC-49 Quy luong KINH_DOANH ky 01 khong doi sau dieu chuyen ($sau)" $?

echo "=== TC-50: so sanh voi ky truoc co quy bang 0"
chay U_PAY01 tests/rep/tc50_pay01.sql

echo "=== TC-51: xuat CSV bang truong phong va Payroll"
set -a; . ./.env; set +a
scripts/xuat_csv.sh U_TP_KT queries/xuat/tp_nhan_su_phong.sql tc51_tp_kt > /dev/null
f=exports/tc51_tp_kt.csv
so=$(($(wc -l < "$f") - 1))
ngoai=$(tail -n +2 "$f" | grep -vc '"KY_THUAT"' || true)
dat "TC-51 TP_KT xuat nhan su phong: $so dong, dong ngoai phong Ky thuat: $ngoai" $([[ $so -gt 0 && $ngoai -eq 0 ]]; echo $?)
! head -1 "$f" | grep -qiE 'MAT_KHAU|HASH|DINH_DANH|MA_SO_THUE'
ok=$?   # luu ma thoat TRUOC khi $(...) trong tham so ghi de $?
dat "TC-51 File cua TP khong co cot mat khau/dinh danh/MST: $(head -1 "$f" | cut -c1-80)..." $ok

scripts/xuat_csv.sh U_TP_KT queries/xuat/pay_bang_luong.sql tc51_tp_luong > /dev/null
grep -q 'ORA-00942' exports/tc51_tp_luong.csv
dat "TC-51 TP xuat bang luong (VW-04) bi chan: ORA-00942" $?

scripts/xuat_csv.sh U_PAY01 queries/xuat/pay_bang_luong.sql tc51_luong --nen > /dev/null
[[ -f exports/tc51_luong.zip && ! -f exports/tc51_luong.csv ]]
dat "TC-51 File luong chi con ban nen exports/tc51_luong.zip (khong de lai CSV tran)" $?
! /c/Windows/System32/tar.exe -x -O -f exports/tc51_luong.zip --passphrase "sai-mat-khau" > /dev/null 2>&1
dat "TC-51 Giai nen bang mat khau sai bi tu choi (AES-256)" $?
noi_dung=$(/c/Windows/System32/tar.exe -x -O -f exports/tc51_luong.zip --passphrase "$CSV_ZIP_PASSWORD" 2>/dev/null)
dong=$(($(printf '%s\n' "$noi_dung" | wc -l) - 1))
[[ $dong -eq 50 ]] && ! printf '%s\n' "$noi_dung" | head -1 | grep -qiE 'MAT_KHAU|HASH'
dat "TC-51 Giai nen bang mat khau trong .env: $dong phieu, khong co cot hash mat khau" $?
printf '%s\n' "$noi_dung" | tail -n +2 | grep -qv '"CHINH THUC"'
dat "TC-51 Ky 01/2026 da khoa: moi dong ghi CHINH THUC" $([[ $? -ne 0 ]]; echo $?)
rm -f exports/tc51_*

if [[ "${1:-}" != "--giu" ]]; then
  echo "=== Tra CSDL ve du lieu mau"
  scripts/rebuild.sh > /dev/null 2>&1 && echo "Da dung lai CSDL" || echo "FAIL  rebuild cuoi"
fi
