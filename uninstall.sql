-- =============================================================================
-- uninstall.sql - Xoa moi doi tuong trong schema HRM_OWNER (giu lai user).
-- Chay bang HRM_OWNER:  scripts/run.sh owner uninstall.sql
-- Chi dung tren moi truong phat trien.
-- =============================================================================
set serveroutput on size unlimited
set feedback off

declare
  v_dem number := 0;
begin
  -- Thu tu: TRIGGER truoc tien (TR-05 la logon trigger: neu pkg_ctx bi xoa truoc,
  -- trigger INVALID se chan dang nhap cua user demo va HRM_APP), roi doi tuong phu
  -- thuoc, bang, domain cuoi cung.
  for r in (
    select object_type, object_name
      from user_objects
     where object_type in ('TRIGGER', 'VIEW', 'PACKAGE', 'PROCEDURE', 'FUNCTION', 'TYPE',
                           'SEQUENCE', 'SYNONYM', 'TABLE', 'DOMAIN')
       and object_name not like 'BIN$%'
       and generated = 'N'
     order by case object_type
                when 'TRIGGER' then 0
                when 'VIEW' then 1 when 'PACKAGE' then 2 when 'PROCEDURE' then 3
                when 'FUNCTION' then 4 when 'SYNONYM' then 5 when 'SEQUENCE' then 6
                when 'TABLE' then 7 when 'TYPE' then 8 when 'DOMAIN' then 9 end)
  loop
    begin
      execute immediate 'drop ' || r.object_type || ' "' || r.object_name || '"' ||
        case r.object_type
          when 'TABLE'  then ' cascade constraints purge'
          when 'TYPE'   then ' force'
          when 'DOMAIN' then ' force'
        end;
      v_dem := v_dem + 1;
    exception when others then
      -- Bang IDENTITY sinh sequence ISEQ$$ tu dong; da bi xoa cung bang
      if sqlcode not in (-942, -2289, -4043) then raise; end if;
    end;
  end loop;
  dbms_output.put_line('Da xoa ' || v_dem || ' doi tuong');
end;
/
