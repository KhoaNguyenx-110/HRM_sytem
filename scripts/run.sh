#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Chay mot script SQL trong container Oracle.
#   scripts/run.sh sys     <file.sql> [tham so...]  -> SYSDBA, container FREEPDB1
#   scripts/run.sh owner   <file.sql> [tham so...]  -> HRM_OWNER@FREEPDB1
#   scripts/run.sh HRM_APP <file.sql> [tham so...]  -> HRM_APP@FREEPDB1
#   scripts/run.sh U_NV_A  <file.sql> [tham so...]  -> user demo bat ky (U_*)
# Ma nguon SQL duoc chep vao /tmp/hrm trong container de @@ long nhau hoat dong.
# Mat khau doc tu .env (khong commit).
# -----------------------------------------------------------------------------
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash tren Windows: khong doi /tmp/... thanh duong dan Windows
cd "$(dirname "$0")/.."

set -a; . ./.env; set +a
C="${ORACLE_CONTAINER:-oracle23ai}"
PDB="${ORACLE_PDB:-FREEPDB1}"

who="${1:?sys|owner|HRM_APP|U_*}"; file="${2:?file.sql}"; shift 2
args="$*"

# Dong bo ma nguon SQL vao container (khong chep .env, file xuat luong, ket qua mau).
# KHONG chep thu muc lon: backup/ chua ban sao luu RMAN ~2 GB; chep no o moi lan goi
# da lam day o dia ao cua Docker tren C: (su co 16/11/2026).
# "./backup" (co ./) chi khop thu muc goc; "backup" tron se loai ca scripts/backup, tests/backup
# ./web (GD 7) chua .venv va node_modules (hang tram MB), khong co file SQL nao.
tar cf - --exclude=.env --exclude=.git --exclude=docs --exclude=exports --exclude=./backup \
        --exclude=./web --exclude=node_modules --exclude=.venv \
        --exclude=queries/ket_qua --exclude=tests/ket_qua --exclude=tests/perf/ket_qua \
        --exclude=tests/backup/ket_qua . \
  | docker exec -i "$C" bash -c 'rm -rf /tmp/hrm && mkdir -p /tmp/hrm && tar xf - -C /tmp/hrm'

sqlplus_in() {   # $1 = chuoi dong lenh sqlplus (vd "/ as sysdba" hoac "/nolog")
  docker exec -i -e NLS_LANG=AMERICAN_AMERICA.AL32UTF8 -w /tmp/hrm "$C" sqlplus -s -l $1
}

connect_as() {   # $1 = user, $2 = mat khau
  # define off: chuoi co '&' (vd "R&D") khong bi hieu la bien thay the.
  # Phien sys giu define on vi script SYS nhan mat khau qua &1.
  printf 'connect %s/"%s"@//localhost:1521/%s\nset define off\nset serveroutput on size unlimited\n@%s %s\nexit\n' \
    "$1" "$2" "$PDB" "$file" "$args" | sqlplus_in "/nolog"
}

case "$who" in
  sys)
    # serveroutput phai bat SAU khi doi container, neu khong dbms_output bi mat
    printf 'alter session set container=%s;\nset serveroutput on size unlimited\n@%s %s\nexit\n' \
      "$PDB" "$file" "$args" | sqlplus_in "/ as sysdba"
    ;;
  owner)   connect_as hrm_owner "$HRM_OWNER_PASSWORD" ;;
  HRM_APP) connect_as hrm_app   "$HRM_APP_PASSWORD" ;;
  U_*)     connect_as "$who"    "$DEMO_USER_PASSWORD" ;;
  *) echo "Tham so dau phai la sys, owner, HRM_APP hoac U_*" >&2; exit 2 ;;
esac
