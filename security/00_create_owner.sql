-- =============================================================================
-- 00_create_owner.sql
-- Tao schema HRM_OWNER chua toan bo doi tuong CSDL (dac ta muc 1.5).
-- Chay bang SYSDBA trong FREEPDB1. Tham so: &1 = mat khau HRM_OWNER.
-- HRM_OWNER chi dung de cai dat; khong dung de van hanh hay kiem thu phan quyen.
-- =============================================================================
whenever sqlerror exit failure rollback
set verify off

declare
  v_count number;
begin
  select count(*) into v_count from dba_users where username = 'HRM_OWNER';
  if v_count = 0 then
    execute immediate 'create user hrm_owner identified by "&1" '
                   || 'default tablespace users temporary tablespace temp '
                   || 'quota unlimited on users';
    dbms_output.put_line('Da tao user HRM_OWNER');
  else
    dbms_output.put_line('HRM_OWNER da ton tai, bo qua buoc tao');
  end if;
end;
/

-- Quyen toi thieu de dung lai CSDL tu install.sql (khong cap DBA).
grant create session    to hrm_owner;
grant create table      to hrm_owner;
grant create view       to hrm_owner;
grant create procedure  to hrm_owner;
grant create trigger    to hrm_owner;
grant create sequence   to hrm_owner;
grant create type       to hrm_owner;
grant create domain     to hrm_owner;
grant create synonym    to hrm_owner;

exit
