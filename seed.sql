-- =============================================================================
-- seed.sql - Nap du lieu danh muc va du lieu demo sau install.sql.
-- Chay bang HRM_OWNER:  scripts/run.sh owner seed.sql
-- Dung lai sach tu dau:  uninstall.sql -> install.sql -> seed.sql
-- =============================================================================
whenever sqlerror exit failure rollback
set define off
set feedback off
set serveroutput on size unlimited

prompt === Seed 01 Danh muc, chinh sach 2026, lich 2026
@@seed/01_catalog.sql
prompt === Seed 02 Du lieu demo
@@seed/02_demo.sql

whenever sqlerror continue
prompt === Kiem tra du lieu mau
@@tests/check_seed.sql
