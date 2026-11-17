#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# TC-54: hieu nang tren du lieu 3 nam (NFR-06, NFR-07, NFR-08).
#   1. scripts/seed_perf.sh (bo qua neu --khong-dung): dung du lieu, tinh 36 ky
#      -> thoi gian tinh tung ky (NFR-08) trong ket_qua/tinh_ky.txt
#   2. Ghi cau hinh may that (ket_qua/may.txt)
#   3. Index nghiep vu 6 bang lon -> INVISIBLE; plan TRUOC/SAU (owner);
#      do QR-08/17/18/21 30 lan TRUOC/SAU (U_PAY01); tra index ve VISIBLE
#   4. 10 phien U_PAY01 dong thoi chay QR-17 + QR-08 (NFR-06)
#   5. Tong hop: ket_qua/tc54_tong_hop.txt
# CSDL de lai o trang thai du lieu hieu nang; ve du lieu demo: scripts/rebuild.sh
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
export MSYS_NO_PATHCONV=1
KQ=tests/perf/ket_qua
mkdir -p "$KQ"

[[ "${1:-}" == "--khong-dung" ]] || scripts/seed_perf.sh || { echo "FAIL  TC-54 khong dung duoc du lieu hieu nang"; exit 1; }

echo "=== Cau hinh may"
{
  echo "Ngay do: $(date '+%d/%m/%Y %H:%M')"
  powershell.exe -NoProfile -Command '
    $c = Get-CimInstance Win32_Processor | Select-Object -First 1
    $m = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $d = Get-PhysicalDisk | Select-Object -First 1
    "May chu: {0}, {1} CPU logic, RAM {2:N1} GB, o dia {3} ({4})" -f $c.Name.Trim(), $c.NumberOfLogicalProcessors, $m, $d.MediaType, $d.FriendlyName
    "He dieu hanh: " + (Get-CimInstance Win32_OperatingSystem).Caption' | tr -d '\r'
  docker info --format 'Docker {{.ServerVersion}} (WSL2): {{.NCPU}} CPU, RAM {{.MemTotal}} byte cap cho container'
  docker exec oracle23ai bash -c 'echo "Oracle: $(sqlplus -v | grep -o "Version.*")"'
} | tee "$KQ/may.txt"

echo "=== TC-54 truoc/sau index"
scripts/run.sh sys     tests/perf/tc54_sys_cap_quyen.sql > /dev/null
scripts/run.sh owner   tests/perf/tc54_an_index_owner.sql > "$KQ/tc54_index.txt" 2>&1
scripts/run.sh owner   tests/perf/tc54_plan_owner.sql     > "$KQ/tc54_plan.txt"  2>&1
scripts/run.sh U_PAY01 tests/perf/tc54_truoc_pay01.sql    > "$KQ/tc54_truoc.txt" 2>&1
scripts/run.sh U_PAY01 tests/perf/tc54_sau_pay01.sql      > "$KQ/tc54_sau.txt"   2>&1
scripts/run.sh owner   tests/perf/tc54_hien_index_owner.sql >> "$KQ/tc54_index.txt" 2>&1
grep -hE 'ORA-|PLS-|SP2-' "$KQ"/tc54_{index,plan,truoc,sau}.txt | grep -v '^PLAN' | head -5
echo "So index dua ve INVISIBLE khi do TRUOC: $(grep -c '^AN' "$KQ/tc54_index.txt")"

echo "=== TC-54 / NFR-06: 10 phien dong thoi"
# run.sh xoa va chep lai /tmp/hrm moi lan goi, nen 10 phien song song goi thang sqlplus
phien() {
  printf 'connect U_PAY01/"%s"@//localhost:1521/FREEPDB1\nset serveroutput on size unlimited\n@tests/perf/tc54_phien_pay01.sql\nexit\n' \
    "$DEMO_USER_PASSWORD" \
    | docker exec -i -e NLS_LANG=AMERICAN_AMERICA.AL32UTF8 -w /tmp/hrm oracle23ai sqlplus -s -l /nolog
}
t0=$SECONDS
for i in $(seq 1 10); do phien > "$KQ/tc54_phien_$i.txt" 2>&1 & done
wait
echo "10 phien xong sau $((SECONDS - t0)) s"
cat "$KQ"/tc54_phien_*.txt | grep '^PH' > "$KQ/tc54_dong_thoi.txt"
rm -f "$KQ"/tc54_phien_*.txt

echo "=== Tong hop"
{
  echo "TC-54 - $(head -1 "$KQ/may.txt")"
  echo
  echo "NFR-08 Tinh ky (sp_tinh_luong_ky, 36 ky, U_PAY01):"
  awk '/^TG/ { n++; s += $4; if ($4 > mx) { mx = $4; k = $2; p = $3 } }
       END { printf "  %d ky, trung binh %.2f s/ky; ky lau nhat %s: %d phieu, %.2f s (muc nghiem thu: ghi thoi gian; muc tieu <= 30 s)\n", n, s/n, k, p, mx }' \
    "$KQ/tinh_ky.txt"
  echo
  echo "NFR-07 / plan: 30 lan moi truy van, 1 phien (ms; gets = logical reads/lan)"
  printf "  %-5s | %-24s | %-24s | %-16s | %s\n" "QR" "TRUOC p50 / p95 / max" "SAU p50 / p95 / max" "gets truoc>sau" "dong/lan"
  join <(grep -h '^DO TRUOC' "$KQ/tc54_truoc.txt" | awk '{print $3, $5, $6, $7, $8, $9}' | sort) \
       <(grep -h '^DO SAU'   "$KQ/tc54_sau.txt"   | awk '{print $3, $5, $6, $7, $8}' | sort) \
    | awk '{ printf "  %-5s | %7s / %7s / %7s | %7s / %7s / %7s | %7s > %-6s | %s\n", $1, $2, $3, $4, $7, $8, $9, $5, $10, $6 }'
  # So do luu lai cua VW-03 ban dau (gom theo TRUNC(ngay,'MM'), chua co IX-17)
  if [[ -f "$KQ/tc54_v1_truoc.txt" && -f "$KQ/tc54_v1_sau.txt" ]]; then
    paste -d' ' <(grep '^DO TRUOC QR08' "$KQ/tc54_v1_truoc.txt") <(grep '^DO SAU QR08' "$KQ/tc54_v1_sau.txt") \
      | awk '{ printf "  QR08 voi VW-03 ban dau: TRUOC p50 %s / p95 %s ms, %s gets; SAU p50 %s / p95 %s ms, %s gets\n", $5, $6, $8, $14, $15, $17 }'
  fi
  echo
  echo "NFR-06: 10 phien U_PAY01 dong thoi, moi phien 20 lan QR-17 + 20 lan QR-08 (ms)"
  for q in QR17 QR08; do
    grep "^PH $q " "$KQ/tc54_dong_thoi.txt" | awk '{print $3}' | sort -n \
      | awk -v q="$q" '{ a[NR] = $1 } END { i50 = int(NR * 0.5 + 0.999); i95 = int(NR * 0.95 + 0.999);
                         printf "  %s: %d mau, p50 %.1f, p95 %.1f, max %.1f (muc tieu p95 <= 2000)\n", q, NR, a[i50], a[i95], a[NR] }'
  done
} | tee "$KQ/tc54_tong_hop.txt"

echo "=== Danh gia TC-54"
dat() { if [[ "$2" == 0 ]]; then echo "PASS  $1"; else echo "FAIL  $1"; fi; }
mx=$(awk '/^TG/ { if ($4 > m) m = $4 } END { print m + 0 }' "$KQ/tinh_ky.txt")
so=$(grep -c '^TG' "$KQ/tinh_ky.txt")
awk -v m="$mx" -v n="$so" 'BEGIN { exit !(n == 36 && m <= 30) }'
dat "TC-54 NFR-08 Tinh du 36 ky, ky lau nhat ${mx} s (<= 30 s)" $?
n_plan=$(grep -cE '^PLAN (TRUOC|SAU) QR(08|17|18|21) \| Plan hash value' "$KQ/tc54_plan.txt")
[[ $n_plan -eq 8 ]]
dat "TC-54 Execution plan truoc/sau index cua QR-08, QR-17, QR-18, QR-21 ($n_plan/8 plan)" $?
p95_bc=$(grep -hE '^DO SAU QR(18|21) ' "$KQ/tc54_sau.txt" | awk '{ if ($6 > m) m = $6 } END { print m + 0 }')
n_bc=$(grep -chE '^DO SAU QR(18|21) 30 ' "$KQ/tc54_sau.txt")
awk -v p="$p95_bc" -v n="$n_bc" 'BEGIN { exit !(n == 2 && p > 0 && p <= 5000) }'   # du 2 truy van x 30 lan
dat "TC-54 NFR-07 p95 QR-18/QR-21 sau index ${p95_bc} ms (<= 5000 ms)" $?
p95_dt=$(awk '/^PH/ { print $3 }' "$KQ/tc54_dong_thoi.txt" | sort -n | awk '{ a[NR] = $1 } END { print a[int(NR * 0.95 + 0.999)] }')
n_dt=$(grep -c '^PH' "$KQ/tc54_dong_thoi.txt")
awk -v p="$p95_dt" -v n="$n_dt" 'BEGIN { exit !(n == 400 && p != "" && p <= 2000) }'   # 10 phien x 40 lan
dat "TC-54 NFR-06 p95 tra cuu voi 10 phien dong thoi ${p95_dt} ms tren ${n_dt} mau (<= 2000 ms)" $?
