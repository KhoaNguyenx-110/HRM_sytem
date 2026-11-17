#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Dung CSDL hieu nang 3 nam cho TC-54 (dac ta muc 5.6, 12.3 "seed_perf").
#   1. scripts/rebuild.sh               : CSDL + du lieu demo
#   2. owner  seed/perf/01..04          : lich, chinh sach, 36 ky, 270 nhan vien them,
#                                         don nghi, OT, cham cong, phat sinh
#   3. U_HR01 scripts/perf/01           : chot cong 36 ky (SP-07)
#   4. U_PAY01 scripts/perf/02          : tinh + khoa 36 ky (SP-09, SP-11), do thoi gian
#   5. owner  seed/perf/05_dem.sql      : thong ke optimizer, so dong tung bang
# Ket qua thoi gian tinh tung ky: tests/perf/ket_qua/tinh_ky.txt
# Tra ve du lieu demo: scripts/rebuild.sh
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p tests/perf/ket_qua
rm -f tests/perf/ket_qua/tinh_ky.txt   # khong de so do cu bi doc nham khi lan nay loi

loc() { grep -E 'PASS|FAIL|ORA-|PLS-|SP2-|^Da |^DEM|^TG' || true; }
# chay <user> <file>: chay script, loc dong ket qua, in thoi gian
chay() {
  local t0=$SECONDS out
  echo "--- $2  (user $1)"
  out=$(scripts/run.sh "$1" "$2" 2>&1 | loc)
  [[ -n "$out" ]] && echo "$out"
  # Loi o mot buoc thi dung ca bo: du lieu thieu se cho so do sai
  if grep -qE "^FAIL|ORA-|PLS-|SP2-" <<< "$out"; then echo "FAIL  seed_perf dung o $2"; exit 1; fi
  echo "    ($((SECONDS - t0)) s)"
}

echo "### 1/5 Dung lai CSDL demo"
t0=$SECONDS
scripts/rebuild.sh > /dev/null 2>&1 || { echo "FAIL  rebuild"; exit 1; }
echo "    ($((SECONDS - t0)) s)"

echo "### 2/5 OWNER: sinh du lieu 3 nam"
for f in 01_nen 02_nhan_vien 03_cong_nghi_ot 04_quyet_dinh_phat_sinh; do
  chay owner "seed/perf/$f.sql"
done

echo "### 3/5 U_HR01: chot cong 36 ky"
chay U_HR01 scripts/perf/01_chot_cong_hr01.sql

echo "### 4/5 U_PAY01: tinh va khoa 36 ky"
t0=$SECONDS
scripts/run.sh U_PAY01 scripts/perf/02_tinh_luong_pay01.sql 2>&1 | loc > tests/perf/ket_qua/tinh_ky.txt
grep -v '^TG' tests/perf/ket_qua/tinh_ky.txt || true
[[ $(grep -c '^TG' tests/perf/ket_qua/tinh_ky.txt) -eq 36 ]] || { echo "FAIL  seed_perf: khong tinh du 36 ky"; exit 1; }
echo "    ($((SECONDS - t0)) s)"
awk '/^TG/ { n++; s += $4; if ($4 > mx) { mx = $4; k = $2; p = $3 } }
     END { if (n) printf "    %d ky, trung binh %.2f s/ky, cham nhat %s (%d phieu) %.2f s\n", n, s/n, k, p, mx }' \
  tests/perf/ket_qua/tinh_ky.txt

echo "### 5/5 OWNER: thong ke va so dong"
chay owner seed/perf/05_dem.sql
