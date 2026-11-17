-- =============================================================================
-- 20_demo_users.sql - 11 user demo cho kenh DBeaver (dac ta muc 12.2)
-- Chay bang SYSDBA trong FREEPDB1, SAU seed.sql. Chay lai nhieu lan duoc.
-- Tham so: &1 = mat khau chung cua user demo
--
-- Moi tai khoan nghiep vu co ORACLE_USERNAME duoc tao mot Oracle user cung ten.
-- Role R_* cap theo TAI_KHOAN_VAI_TRO: day la lop chan thu nhat (quyen EXECUTE,
-- SELECT). Lop chan nghiep vu la vai tro trong HRM_CTX, do pkg_ctx nap luc dang
-- nhap (muc 8.2). Tai khoan nghiep vu KHOA van dang nhap Oracle duoc nhung khong
-- nhan danh tinh phien (TC-05).
-- =============================================================================
whenever sqlerror exit failure rollback
set verify off

declare
  v_dem number;
begin
  for u in (select t.tai_khoan_id, t.oracle_username
              from hrm_owner.tai_khoan t
             where t.oracle_username is not null
             order by t.oracle_username) loop
    select count(*) into v_dem from dba_users where username = u.oracle_username;
    if v_dem = 0 then
      execute immediate 'create user ' || dbms_assert.simple_sql_name(u.oracle_username)
                     || ' identified by "&1"';
    else
      execute immediate 'alter user ' || dbms_assert.simple_sql_name(u.oracle_username)
                     || ' identified by "&1" account unlock';
    end if;
    execute immediate 'grant create session to ' || u.oracle_username;

    -- Thu hoi het role R_* roi cap lai theo du lieu hien tai
    for r in (select granted_role from dba_role_privs
               where grantee = u.oracle_username and granted_role like 'R\_%' escape '\') loop
      execute immediate 'revoke ' || r.granted_role || ' from ' || u.oracle_username;
    end loop;

    for r in (select 'R_' || v.ma_vai_tro as role_name
                from hrm_owner.tai_khoan_vai_tro tv
                join hrm_owner.vai_tro v on v.vai_tro_id = tv.vai_tro_id
               where tv.tai_khoan_id = u.tai_khoan_id) loop
      execute immediate 'grant ' || r.role_name || ' to ' || u.oracle_username;
    end loop;

    dbms_output.put_line('User demo ' || rpad(u.oracle_username, 10) || ' san sang');
  end loop;
end;
/

exit
