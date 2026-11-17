-- =============================================================================
-- install.sql - Dung lai toan bo CSDL HRM tren schema HRM_OWNER trong.
-- Chay bang HRM_OWNER:  scripts/run.sh owner install.sql
-- Dung ngay khi gap loi dau tien. Ket thuc bang TC-53.
-- =============================================================================
whenever sqlerror exit failure rollback
set define off
set feedback off
set serveroutput on size unlimited

prompt === 01 Mien du lieu
@@ddl/01_domains.sql
prompt === 02 Bang (32)
@@ddl/02_tables.sql
prompt === 03 Khoa ngoai
@@ddl/03_foreign_keys.sql
prompt === 04 Index
@@ddl/04_indexes.sql

-- Yeu cau truoc (SYS): security/00_create_owner.sql, security/01_sys_objects.sql
prompt === 05 PL/SQL: danh tinh phien (FN-06, SP-28, SP-27, TR-05)
@@plsql/01_fn_ctx.sql
@@plsql/02_pkg_ctx.sql
@@plsql/03_pkg_auth.sql
@@plsql/04_tr05_logon.sql
prompt === 06 PL/SQL: tai khoan, to chuc, ho so, quyet dinh (GD 4a)
@@plsql/05_pkg_chung.sql
-- pkg_payroll: chi spec o day; body o 17 (can FN-01/04/05, FN-02)
@@plsql/06_pkg_payroll.sql
@@plsql/07_pkg_admin.sql
@@plsql/08_pkg_hr.sql
@@plsql/09_tr01_audit.sql
@@plsql/10_views_hr.sql
prompt === 07 PL/SQL: cong, OT, nghi phep (GD 4b)
@@plsql/11_fn_att.sql
@@plsql/12_pkg_att.sql
@@plsql/13_pkg_leave.sql
@@plsql/14_tr03_cong_da_chot.sql
@@plsql/15_views_att.sql
prompt === 08 PL/SQL: tinh luong (GD 4c)
@@plsql/16_fn_luong.sql
@@plsql/17_pkg_payroll_body.sql
@@plsql/18_tr02_tr04.sql
@@plsql/19_views_payroll.sql
prompt === 09 PL/SQL: view bao cao (GD 5)
@@plsql/20_views_bao_cao.sql
prompt === 10a PL/SQL: danh muc cho kenh web (GD 7)
@@plsql/21_pkg_danh_muc.sql
prompt === 10 Cap quyen
@@security/10_grants.sql

-- Truy van QR-01..24 nam o thu muc queries/ (khong cai vao schema).

whenever sqlerror continue
prompt === TC-53 Kiem tra sau cai dat
@@tests/tc_53.sql
