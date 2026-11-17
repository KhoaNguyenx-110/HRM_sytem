#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Nghiem thu GD 6: chay du 59 ca kiem thu (dac ta muc 12.5; TC-56..59 bo sung v2.3) theo thu tu, luu ket
# qua tung bo va tong hop theo ma TC.
#   tests/run_nghiem_thu.sh                 chay tat ca (~15 phut)
#   tests/run_nghiem_thu.sh --bo-hieu-nang  bo qua TC-54, TC-55 (nhanh, ~5 phut)
# Ket qua: tests/ket_qua/<bo>.txt va tests/ket_qua/tong_hop_tc.txt
# Cuoi cung dung lai CSDL demo.
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."
KQ=tests/ket_qua
mkdir -p "$KQ"
rm -f "$KQ"/*.txt

chay() {   # $1 = ten bo, $2... = lenh
  local ten=$1; shift
  local t0=$SECONDS
  "$@" > "$KQ/$ten.txt" 2>&1
  printf '%-10s %3d PASS  %3d FAIL  (%d s)\n' "$ten" \
    "$(grep -c '^PASS' "$KQ/$ten.txt")" "$(grep -c '^FAIL' "$KQ/$ten.txt")" $((SECONDS - t0))
}

echo "=== Nghiem thu $(date '+%d/%m/%Y %H:%M')"
# TC-53 (install.sql tren schema trong) + kiem tra du lieu mau nam trong rebuild
chay cai_dat  scripts/rebuild.sh
grep -q 'PASS  TC-53' "$KQ/cai_dat.txt" || { echo "DUNG: dung lai CSDL loi (xem $KQ/cai_dat.txt)"; exit 1; }
chay bao_mat  tests/run_security.sh
chay ho_so    bash -c 'scripts/rebuild.sh > /dev/null 2>&1 && tests/run_hr.sh'
chay cong     bash -c 'scripts/rebuild.sh > /dev/null 2>&1 && tests/run_att.sh'
chay luong    tests/run_pay.sh
chay bao_cao  tests/run_rep.sh
chay audit    tests/run_audit.sh
chay web      tests/run_web.sh
if [[ "${1:-}" != "--bo-hieu-nang" ]]; then
  chay hieu_nang tests/run_perf.sh
  chay sao_luu   tests/run_backup.sh
fi
scripts/rebuild.sh > /dev/null 2>&1 && echo "Da tra CSDL ve du lieu demo"

# Tong hop theo ma TC: mot dong PASS/FAIL co the nhac nhieu ma (vd "TC-13/TC-52")
{
  echo "Ma    PASS  FAIL  Bo kiem thu"
  for i in $(seq -w 1 59); do
    p=$(grep -h '^PASS' "$KQ"/*.txt | grep -c "TC-$i")
    f=$(grep -h '^FAIL' "$KQ"/*.txt | grep -c "TC-$i")
    bo=$(grep -l -E "^(PASS|FAIL).*TC-$i" "$KQ"/*.txt 2>/dev/null | xargs -r -n1 basename | sed 's/\.txt$//' | sort -u | paste -sd, -)
    printf 'TC-%s %4d  %4d  %s\n' "$i" "$p" "$f" "${bo:--}"
  done
} > "$KQ/tong_hop_tc.txt"
dat=$(awk 'NR > 1 && $2 > 0 && $3 == 0' "$KQ/tong_hop_tc.txt" | wc -l)
khong=$(awk 'NR > 1 && $3 > 0' "$KQ/tong_hop_tc.txt" | wc -l)
chua=$(awk 'NR > 1 && $2 == 0 && $3 == 0' "$KQ/tong_hop_tc.txt" | wc -l)
echo "=== Theo ma TC: $dat dat, $khong co dong FAIL, $chua chua co ket qua (tests/ket_qua/tong_hop_tc.txt)"
awk 'NR > 1 && ($3 > 0 || $2 == 0)' "$KQ/tong_hop_tc.txt"
echo "=== Tong: $(grep -h '^PASS' "$KQ"/*.txt | wc -l) PASS, $(grep -h '^FAIL' "$KQ"/*.txt | wc -l) FAIL"
