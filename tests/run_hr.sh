#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bo kiem thu giai doan 4a (tai khoan, to chuc, ho so, quyet dinh).
# Moi ca chay bang dung user theo muc 12.2 / 12.5.
# Dung: tests/run_hr.sh
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."

chay() {   # $1 = user, $2 = file
  echo "--- $2  (user $1)"
  scripts/run.sh "$1" "$2" 2>&1 | grep -E 'PASS|FAIL|ORA-|PLS-|SP2-|\(da ' || true
}

chay U_ADMIN tests/hr/tc03_08_admin.sql
chay U_HR02  tests/hr/tc04b_hr02_mat_quyen.sql
chay U_ADMIN tests/hr/tc04c_admin_khoi_phuc.sql
chay U_HR01  tests/hr/tc09_17_hr01.sql
chay U_HR02  tests/hr/tc44_hr02.sql
for u in U_NV_A U_TP_KT U_TP_KD U_HR01; do
  chay "$u" tests/hr/tc18_pham_vi.sql
done
