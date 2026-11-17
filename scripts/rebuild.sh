#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Dung lai toan bo CSDL HRM tu dau tren FREEPDB1 (moi truong phat trien).
#   1. SYS   : user HRM_OWNER, context HRM_CTX, role R_*, user HRM_APP
#   2. OWNER : xoa doi tuong cu -> install.sql (DDL, PL/SQL, grant, TC-53)
#   3. OWNER : seed.sql (du lieu danh muc + demo, kiem tra)
#   4. SYS   : 11 user demo U_* theo TAI_KHOAN.ORACLE_USERNAME
# Dung: scripts/rebuild.sh
# -----------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

# grep tra ma 1 khi khong con dong nao: khong coi la loi
loc()  { grep -Ev "$1" || true; }
chon() { grep -E  "$1" || true; }

echo "### 1/4 SYS: owner, context, role, HRM_APP"
scripts/run.sh sys security/00_create_owner.sql "$HRM_OWNER_PASSWORD" | loc '^$|Grant succeeded|Session altered|procedure successfully'
scripts/run.sh sys security/01_sys_objects.sql "$HRM_APP_PASSWORD"     | loc '^$|Grant succeeded|Session altered|procedure successfully|Context created'

echo "### 2/4 OWNER: uninstall + install"
scripts/run.sh owner uninstall.sql
scripts/run.sh owner install.sql | loc '^$|^No errors\.$'

echo "### 3/4 OWNER: seed"
scripts/run.sh owner seed.sql | chon 'PASS|FAIL|ORA-|PLS-|==='

echo "### 4/4 SYS: user demo"
scripts/run.sh sys security/20_demo_users.sql "$DEMO_USER_PASSWORD" | loc '^$|Session altered|procedure successfully'
