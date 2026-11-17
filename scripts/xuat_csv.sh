#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Xuat ket qua mot truy van ra CSV bang dung user nghiep vu (FR-REP-06, TC-51).
#   scripts/xuat_csv.sh <USER> <file.sql> <ten> [--nen]
#     -> exports/<ten>.csv
#     --nen: nen thanh exports/<ten>.zip ma hoa AES-256 (NFR-05), xoa ban CSV tran.
#            Mat khau lay tu .env (CSV_ZIP_PASSWORD), KHONG nam cung file zip;
#            neu .env chua co thi sinh ngau nhien va ghi vao .env.
# Pham vi du lieu do view quyet dinh (loc theo danh tinh cua <USER>), khong do
# script nay. Thu muc exports/ nam trong .gitignore.
# Nen dung tar.exe co san cua Windows (libarchive), giai nen bang 7-Zip hoac
# "tar -x --passphrase ...".
# -----------------------------------------------------------------------------
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."

who="${1:?USER}"; file="${2:?file.sql}"; ten="${3:?ten file}"; nen="${4:-}"
set -a; . ./.env; set +a
C="${ORACLE_CONTAINER:-oracle23ai}"

mkdir -p exports scripts/tmp
docker exec "$C" bash -c 'mkdir -p /tmp/hrm_xuat && rm -f /tmp/hrm_xuat/*'

# Vo boc: bat che do CSV, spool ra file trong container, roi chay file truy van
cat > scripts/tmp/xuat_$ten.sql <<EOF
set markup csv on quote on
set termout off feedback off verify off heading on pagesize 50000 trimspool on
alter session set nls_date_format = 'YYYY-MM-DD';
spool /tmp/hrm_xuat/$ten.csv
@$file
spool off
EOF
scripts/run.sh "$who" "scripts/tmp/xuat_$ten.sql" > /dev/null
rm -f "scripts/tmp/xuat_$ten.sql"

docker cp "$C:/tmp/hrm_xuat/$ten.csv" "exports/$ten.csv" > /dev/null
docker exec "$C" rm -f "/tmp/hrm_xuat/$ten.csv"
sed -i '/^$/d' "exports/$ten.csv"

if [[ "$nen" == "--nen" ]]; then
  if [[ -z "${CSV_ZIP_PASSWORD:-}" ]]; then
    CSV_ZIP_PASSWORD=$(head -c 64 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20)
    printf 'CSV_ZIP_PASSWORD=%s\n' "$CSV_ZIP_PASSWORD" >> .env
    echo "Da sinh mat khau nen moi va ghi vao .env (CSV_ZIP_PASSWORD)"
  fi
  rm -f "exports/$ten.zip"
  /c/Windows/System32/tar.exe -a -c -f "exports/$ten.zip" --options zip:encryption=aes256 \
    --passphrase "$CSV_ZIP_PASSWORD" -C exports "$ten.csv"
  rm -f "exports/$ten.csv"
  echo "exports/$ten.zip (AES-256)"
else
  echo "exports/$ten.csv"
fi
