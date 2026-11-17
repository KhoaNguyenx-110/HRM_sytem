#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Chay QR-01..QR-24 tren du lieu demo va luu ket qua mau vao queries/ket_qua/.
#   * Dung lai CSDL (scripts/rebuild.sh) va du lieu luong demo (scripts/demo_luong.sh):
#     ky 01, 02/2026 DA_KHOA; ky 03/2026 tam tinh.
#   * User chay moi truy van lay tu dong "-- Chay: scripts/run.sh <USER> ..." dau tien
#     trong phan dau file, nen chi khai bao o mot cho.
# Dung: queries/run_all.sh            (dung lai CSDL truoc)
#       queries/run_all.sh --khong-dung (chay tren CSDL hien tai)
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."

if [[ "${1:-}" != "--khong-dung" ]]; then
  echo "=== Dung lai CSDL va du lieu luong demo"
  scripts/rebuild.sh > /dev/null 2>&1 || { echo "FAIL  rebuild"; exit 1; }
  scripts/demo_luong.sh
fi

mkdir -p queries/ket_qua
loi=0
for f in queries/qr[0-9][0-9]_*.sql; do
  ten=$(basename "$f" .sql)
  user=$(grep -m1 -oE '^-- Chay: scripts/run.sh [A-Za-z0-9_]+' "$f" | awk '{print $4}')
  {
    echo "-- $ten   (user $user, chay luc $(date '+%d/%m/%Y %H:%M'))"
    scripts/run.sh "$user" "$f" 2>&1 | grep -v '^$'
  } > "queries/ket_qua/$ten.txt"
  if grep -qE '^(ORA|PLS|SP2)-' "queries/ket_qua/$ten.txt"; then
    echo "LOI   $ten ($user)"; loi=$((loi + 1))
  else
    dong=$(grep -oE '^[0-9]+ rows? selected|^no rows selected' "queries/ket_qua/$ten.txt" | tr '\n' ';')
    echo "OK    $ten ($user)  $dong"
  fi
done
echo "=== $loi truy van loi; ket qua mau o queries/ket_qua/"
