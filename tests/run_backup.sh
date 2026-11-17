#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# TC-55: sao luu RMAN level 0 + level 1, mat mot datafile, restore + recover
# (dac ta muc 8.4, NFR-13, NFR-14). Kem export schema bang Data Pump.
#   tests/run_backup.sh          chay tren CSDL hien tai (nen la du lieu hieu nang)
#   tests/run_backup.sh --demo   dung lai CSDL demo truoc
# Datafile bi xoa: /opt/oracle/oradata/FREE/FREEPDB1/users01.dbf (tablespace USERS
# cua FREEPDB1, chua toan bo schema HRM_OWNER).
# Ket qua: tests/backup/ket_qua/ (log RMAN, anh chup so dong, tong hop);
# ban sao luu chep ra may chu: backup/ (khong commit).
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
export MSYS_NO_PATHCONV=1
C="${ORACLE_CONTAINER:-oracle23ai}"
KQ=tests/backup/ket_qua
BK=/opt/oracle/backup_hrm
FILE=/opt/oracle/oradata/FREE/FREEPDB1/users01.dbf
mkdir -p "$KQ"
rm -f "$KQ"/*

dat() { if [[ "$2" == 0 ]]; then echo "PASS  $1"; else echo "FAIL  $1"; fi; }
bay_gio() { date +%s.%N; }
# SQL*Plus SYSDBA o CDB$ROOT (run.sh sys chuyen vao PDB nen khong dung duoc o day)
goc() { docker exec -i -w /tmp/hrm "$C" sqlplus -s / as sysdba < "$1"; }
# RMAN: $1 = file lenh, $2 = ten log
rman_chay() {
  docker exec "$C" rman target / cmdfile="/tmp/hrm/$1" log="$BK/log/$2.log" > /dev/null
  local rc=$?
  docker exec "$C" cat "$BK/log/$2.log" > "$KQ/rman_$2.txt"
  return $rc
}

[[ "${1:-}" == "--demo" ]] && { echo "=== Dung lai CSDL demo"; scripts/rebuild.sh > /dev/null 2>&1; }

# Loi that cua RMAN/Oracle nam o DAU dong; RMAN con in lai file lenh (ca chu thich
# co chu "ORA-01157") nen khong duoc tim "ORA-" o bat ky dau trong dong.
co_loi() { grep -qE '^(RMAN|ORA)-[0-9]+' "$1"; }
# Chot an toan: thieu dieu kien thi DUNG, khong bao gio xoa datafile khi chua co ban
# sao luu hop le (su co 16/11/2026: bao PASS sai -> xoa file roi khong restore duoc).
dung() { echo "FAIL  TC-55 DUNG: $1"; exit 1; }

echo "=== TC-55 buoc 0: cau hinh"
[[ "$(docker exec -i "$C" sqlplus -s / as sysdba <<< "set heading off feedback off
select open_mode from v\$pdbs where name = 'FREEPDB1';" | tr -d '[:space:]')" == "READWRITE" ]] \
  || dung "FREEPDB1 khong o trang thai READ WRITE truoc khi bat dau"
scripts/run.sh owner tests/backup/tc55_dem_owner.sql > /dev/null   # dong bo ma nguon vao /tmp/hrm
docker exec "$C" bash -c "rm -rf $BK && mkdir -p $BK/log"
goc scripts/backup/sys_cau_hinh.sql > "$KQ/cau_hinh.txt" 2>&1
grep -qE 'Database log mode[[:space:]]+Archive Mode' "$KQ/cau_hinh.txt" && grep -qE '^900' "$KQ/cau_hinh.txt"
dat "TC-55 CSDL o che do ARCHIVELOG; archive_lag_target = 900 s" $?
printf 'CROSSCHECK BACKUP;\nDELETE NOPROMPT EXPIRED BACKUP;\nCROSSCHECK ARCHIVELOG ALL;\nDELETE NOPROMPT EXPIRED ARCHIVELOG ALL;\n' \
  | docker exec -i "$C" rman target / > /dev/null
rman_chay scripts/backup/00_cau_hinh.rman 00_cau_hinh
grep -q 'CONTROLFILE AUTOBACKUP ON' "$KQ/rman_00_cau_hinh.txt"
dat "TC-55 CONFIGURE CONTROLFILE AUTOBACKUP ON" $?

echo "=== TC-55 buoc 1: level 0"
t=$(bay_gio); rman_chay scripts/backup/01_level0.rman 01_level0; rc=$?
g0=$(awk -v a="$(bay_gio)" -v b="$t" 'BEGIN { print a - b }')
! co_loi "$KQ/rman_01_level0.txt" && [[ $rc -eq 0 ]]
ok=$?   # luu ma thoat TRUOC khi $(...) trong tham so ghi de $?
dat "TC-55 Sao luu incremental level 0 xong sau $(printf '%.0f' "$g0") s" $ok
[[ $ok -eq 0 ]] || dung "ban level 0 loi (xem $KQ/rman_01_level0.txt), khong gia lap su co"

echo "=== TC-55: thay doi sau level 0"
scripts/run.sh U_PAY01 tests/backup/tc55_thay_doi_1_pay01.sql | grep -E '^Da |ORA-'

echo "=== TC-55 buoc 2: level 1"
t=$(bay_gio); rman_chay scripts/backup/02_level1.rman 02_level1; rc=$?
g1=$(awk -v a="$(bay_gio)" -v b="$t" 'BEGIN { print a - b }')
! co_loi "$KQ/rman_02_level1.txt" && [[ $rc -eq 0 ]]
ok=$?   # luu ma thoat TRUOC khi $(...) trong tham so ghi de $?
dat "TC-55 Sao luu incremental level 1 xong sau $(printf '%.0f' "$g1") s" $ok
[[ $ok -eq 0 ]] || dung "ban level 1 loi (xem $KQ/rman_02_level1.txt), khong gia lap su co"

echo "=== TC-55: thay doi sau level 1 (chi con trong redo)"
scripts/run.sh U_HR01 tests/backup/tc55_thay_doi_2_hr01.sql | grep -E '^Da |ORA-'
scripts/run.sh owner tests/backup/tc55_dem_owner.sql | grep -E '^(DEM|OBJ|INVALID|TIEN|MOC)' > "$KQ/truoc_su_co.txt"
echo "Anh chup truoc su co: $(grep -c '^DEM' "$KQ/truoc_su_co.txt") bang, $(grep '^MOC1' "$KQ/truoc_su_co.txt")"

grep -q '^MOC1 .*: 1$' "$KQ/truoc_su_co.txt" && grep -q '^MOC2 .*nv151.tc55@' "$KQ/truoc_su_co.txt" \
  || dung "hai thay doi moc chua duoc ghi, khong gia lap su co"

echo "=== TC-55 buoc 3: su co - xoa datafile USERS cua FREEPDB1"
goc scripts/backup/sys_dong_pdb.sql > "$KQ/su_co.txt" 2>&1
docker exec "$C" rm -f "$FILE"
t_su_co=$(bay_gio)
goc scripts/backup/sys_mo_pdb.sql >> "$KQ/su_co.txt" 2>&1
grep -q 'ORA-01157' "$KQ/su_co.txt"
dat "TC-55 Mo FREEPDB1 sau khi mat file bi loi ORA-01157 (khong doc duoc datafile)" $?

echo "=== TC-55 buoc 4: restore + recover"
rman_chay scripts/backup/03_phuc_hoi.rman 03_phuc_hoi; rc=$?
rto=$(awk -v a="$(bay_gio)" -v b="$t_su_co" 'BEGIN { print a - b }')
! co_loi "$KQ/rman_03_phuc_hoi.txt" && [[ $rc -eq 0 ]] \
  && grep -qE 'restored backup piece|restore complete' "$KQ/rman_03_phuc_hoi.txt"   # that su lay tu ban sao luu
ok=$?   # luu ma thoat TRUOC khi $(...) trong tham so ghi de $?
dat "TC-55 RESTORE + RECOVER datafile, mo lai PDB; thoi gian tu luc phat hien den khi mo: $(printf '%.1f' "$rto") s (RTO muc tieu <= 7200 s)" $ok

scripts/run.sh owner tests/backup/tc55_dem_owner.sql | grep -E '^(DEM|OBJ|INVALID|TIEN|MOC)' > "$KQ/sau_phuc_hoi.txt"
diff "$KQ/truoc_su_co.txt" "$KQ/sau_phuc_hoi.txt" > "$KQ/chenh_lech.txt"
ok=$?   # luu ma thoat TRUOC khi $(...) trong tham so ghi de $?
dat "TC-55 So dong $(grep -c '^DEM' "$KQ/sau_phuc_hoi.txt") bang, so doi tuong, tong tien giong het truoc su co (diff rong)" $ok
grep -q 'MOC1 .*: 1$' "$KQ/sau_phuc_hoi.txt"
dat "TC-55 Thay doi sau level 0 con (ap tu level 1)" $?
grep -q 'MOC2 .*nv151.tc55@' "$KQ/sau_phuc_hoi.txt"
dat "TC-55 Thay doi sau level 1 con (ap tu redo; RPO = 0 voi giao dich da commit)" $?
grep -q '^INVALID 0$' "$KQ/sau_phuc_hoi.txt"
dat "TC-55 0 doi tuong INVALID sau phuc hoi" $?

echo "=== Data Pump: export schema HRM_OWNER"
scripts/run.sh sys tests/backup/tc55_sys_data_pump.sql > /dev/null
dp_dir=$(scripts/run.sh sys tests/backup/tc55_sys_data_pump.sql | grep '^DIR ' | awk '{print $2}')
docker exec -i "$C" bash -c 'umask 077; cat > /tmp/hrm_exp.par' <<EOF
userid=hrm_owner/"$HRM_OWNER_PASSWORD"@//localhost:1521/FREEPDB1
schemas=HRM_OWNER
directory=DATA_PUMP_DIR
dumpfile=hrm_owner_tc55.dmp
logfile=hrm_owner_tc55.log
reuse_dumpfiles=yes
EOF
docker exec "$C" bash -c 'expdp parfile=/tmp/hrm_exp.par > /dev/null 2>&1; rm -f /tmp/hrm_exp.par'
docker exec "$C" cat "$dp_dir/hrm_owner_tc55.log" > "$KQ/expdp.txt" 2>/dev/null
grep -q 'successfully completed' "$KQ/expdp.txt"
ok=$?   # luu ma thoat TRUOC khi $(...) trong tham so ghi de $?
dat "TC-55 Export schema HRM_OWNER bang Data Pump ($(grep -o 'exported "HRM_OWNER"' "$KQ/expdp.txt" | wc -l) bang)" $ok

echo "=== Chep ban sao luu ra may chu (ngoai container CSDL)"
dung_luong=$(docker exec "$C" bash -c "du -sh $BK" | cut -f1)
rm -rf backup && mkdir -p backup
docker cp "$C:$BK" backup/ > /dev/null && docker cp "$C:$dp_dir/hrm_owner_tc55.dmp" backup/ > /dev/null
ok=$?   # luu ma thoat TRUOC khi $(...) trong tham so ghi de $?
dat "TC-55 Ban sao luu tai backup/: $(du -sh backup | cut -f1)" $ok
# May phat trien: o dia ao cua Docker nam tren C: va khong tu co lai, nen sau khi da
# co ban o backup/ thi xoa ban trong container (lan chay sau CROSSCHECK roi DELETE EXPIRED).
# Tren may that ban sao luu giu tren o/thiet bi rieng theo chinh sach giu 14 ngay.
docker exec "$C" bash -c "rm -rf $BK; rm -f $dp_dir/hrm_owner_tc55.dmp"

{
  echo "TC-55 - $(date '+%d/%m/%Y %H:%M')"
  echo "Level 0: $(printf '%.0f' "$g0") s; level 1: $(printf '%.0f' "$g1") s; phuc hoi (RTO do duoc): $(printf '%.1f' "$rto") s"
  echo "Dung luong ban sao luu RMAN: $dung_luong"
  grep -E '^MOC|^INVALID|^TIEN' "$KQ/sau_phuc_hoi.txt"
} | tee "$KQ/tong_hop.txt"
