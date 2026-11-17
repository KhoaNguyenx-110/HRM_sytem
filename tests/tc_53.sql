-- =============================================================================
-- tc_53.sql - TC-53: install.sql tren schema trong cho 0 doi tuong INVALID (NFR-16)
-- Kem cac phep dem doi chieu voi tu dien du lieu.
-- =============================================================================
set serveroutput on size unlimited
set feedback off

declare
  v number;
  procedure kiem_tra(p_ten varchar2, p_thuc_te number, p_mong_doi number) is
  begin
    dbms_output.put_line(
      case when p_thuc_te = p_mong_doi then 'PASS  ' else 'FAIL  ' end ||
      rpad(p_ten, 42) || ' thuc te = ' || p_thuc_te || ', mong doi = ' || p_mong_doi);
  end;
begin
  select count(*) into v from user_objects where status <> 'VALID';
  kiem_tra('TC-53 Doi tuong INVALID', v, 0);

  select count(*) into v from user_tables where table_name not like 'BIN$%';
  kiem_tra('So bang', v, 32);

  select count(*) into v from user_objects where object_type = 'DOMAIN';
  kiem_tra('So domain', v, 5);

  select count(*) into v from user_constraints where constraint_type = 'R';
  kiem_tra('So khoa ngoai', v, 57);

  select count(*) into v from user_constraints
   where constraint_type = 'R' and delete_rule <> 'NO ACTION';
  kiem_tra('FK co ON DELETE (BR-33)', v, 0);

  select count(*) into v from user_tab_comments
   where table_type = 'TABLE' and comments is null;
  kiem_tra('Bang thieu chu thich', v, 0);

  select count(*) into v from user_indexes
   where index_name in ('IX02_TAI_KHOAN_TEN', 'IX14_CTNP_BUOI_HIEU_LUC') and uniqueness = 'UNIQUE';
  kiem_tra('Unique index ham IX-02, IX-14', v, 2);

  for r in (select object_type, object_name from user_objects where status <> 'VALID') loop
    dbms_output.put_line('      INVALID: ' || r.object_type || ' ' || r.object_name);
  end loop;
end;
/
