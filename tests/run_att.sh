#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bo kiem thu giai doan 4b (cong, OT, nghi phep): TC-19..TC-30, TR-03.
# Moi ca chay bang dung user theo muc 12.5. Dung: tests/run_att.sh
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."

chay() {   # $1 = user, $2 = file
  echo "--- $2  (user $1)"
  scripts/run.sh "$1" "$2" 2>&1 | grep -E 'PASS|FAIL|ORA-|PLS-|SP2-|\(da |  [A-Z_]+ \|' || true
}

chay U_HR01  tests/att/tc19_20_23_25_hr01.sql
chay owner   tests/att/tc23_setup_owner.sql
chay U_HR01  tests/att/tc23b_hr01_xung_dot.sql
chay owner   tests/att/tc23_cleanup_owner.sql
chay U_NV_A  tests/att/tc21_26_30_nv_a.sql
chay U_TP_KT tests/att/tc22_29_tp_kt.sql
chay U_TP_KD tests/att/tc22_29_tp_kd.sql
chay U_TP_NS tests/att/tc29_tp_ns.sql
chay U_NV_B  tests/att/tc27_nv_b.sql
chay U_PAY01 tests/att/tc24_pay01.sql

echo "--- TC-26: dang ky nghi trong ky da chot cong"
chay U_HR01  tests/att/tc26_chot_hr01.sql
chay U_NV_A  tests/att/tc26b_nv_a.sql
chay owner   tests/att/tc26_restore_owner.sql

chay owner   tests/att/tc_tr03_owner.sql

echo "--- TC-28: hai phien duyet dong thoi"
chay U_TP_KD tests/att/tc28_setup_tp_kd.sql
( scripts/run.sh U_HR01 tests/att/tc28_phien.sql 2>&1 | grep -E 'PASS|FAIL|ORA-' ) &
sleep 2
scripts/run.sh U_HR02 tests/att/tc28_phien.sql 2>&1 | grep -E 'PASS|FAIL|ORA-'
wait
chay owner   tests/att/tc28_cleanup_owner.sql
