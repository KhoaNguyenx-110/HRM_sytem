-- =============================================================================
-- 01_sys_objects.sql - Doi tuong cap CSDL cho bao mat (dac ta muc 8.1, 8.2)
-- Chay bang SYSDBA trong FREEPDB1, TRUOC install.sql. Chay lai nhieu lan duoc.
-- Tham so: &1 = mat khau HRM_APP
--
--   * Secure application context HRM_CTX: chi hrm_owner.pkg_ctx gan duoc gia tri
--   * 5 role nghiep vu R_*
--   * User HRM_APP cua ung dung web: chi CREATE SESSION; quyen EXECUTE cap o
--     security/10_grants.sql. Khong co quyen tren bang.
--   * HRM_OWNER duoc ADMINISTER DATABASE TRIGGER de tao TR-05 (AFTER LOGON)
-- =============================================================================
whenever sqlerror exit failure rollback
set verify off

-- Context gan voi package; package chua can ton tai khi tao context
create or replace context hrm_ctx using hrm_owner.pkg_ctx;

declare
  procedure tao_role(p_role varchar2) is
  begin
    execute immediate 'create role ' || p_role;
    dbms_output.put_line('Da tao role ' || p_role);
  exception when others then
    if sqlcode <> -1921 then raise; end if;   -- ORA-01921: role da ton tai
  end;
begin
  tao_role('R_ADMIN');
  tao_role('R_HR');
  tao_role('R_PAYROLL');
  tao_role('R_MANAGER');
  tao_role('R_EMPLOYEE');
end;
/

declare
  v_dem number;
begin
  select count(*) into v_dem from dba_users where username = 'HRM_APP';
  if v_dem = 0 then
    execute immediate 'create user hrm_app identified by "&1"';
    dbms_output.put_line('Da tao user HRM_APP');
  else
    execute immediate 'alter user hrm_app identified by "&1" account unlock';
  end if;
end;
/
grant create session to hrm_app;

-- TR-05 la trigger AFTER LOGON ON DATABASE thuoc schema HRM_OWNER
grant administer database trigger to hrm_owner;

-- SP-23 khoa theo dinh danh nguoi phu thuoc chuan hoa (BR-10)
grant execute on dbms_lock to hrm_owner;

exit
