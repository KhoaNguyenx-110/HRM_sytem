-- =============================================================================
-- TC-54 (HRM_OWNER): execution plan cua QR-08, QR-17, QR-18, QR-21 truoc/sau index.
-- Chay khi cac index nghiep vu dang INVISIBLE (tc54_an_index_owner.sql):
--   TRUOC: optimizer bo qua index INVISIBLE
--   SAU  : alter session set optimizer_use_invisible_indexes = true
-- Owner chay vi EXPLAIN PLAN tren view cua schema khac can quyen bang goc (ORA-01039);
-- plan khong phu thuoc nguoi chay (bo loc danh tinh la ham, khong doi cau truc).
-- Dong ket qua: PLAN <che do> <QR> | <dong plan>
-- =============================================================================
set feedback off
set linesize 200
set pagesize 0
set trimspool on
variable p_nam    number
variable p_thang  number
variable p_phong  varchar2(20)
variable p_ma     varchar2(20)
variable p_tu_ky  varchar2(7)
variable p_den_ky varchar2(7)
variable p_che_do varchar2(5)
exec :p_nam := 2025; :p_thang := 6; :p_phong := 'KY_THUAT'; :p_ma := 'NV150'; :p_tu_ky := '2023-04'; :p_den_ky := '2026-03'

exec :p_che_do := 'TRUOC'
delete from plan_table;
@@tc54_plan_than.sql

alter session set optimizer_use_invisible_indexes = true;
exec :p_che_do := 'SAU'
delete from plan_table;
@@tc54_plan_than.sql
