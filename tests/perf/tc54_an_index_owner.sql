-- =============================================================================
-- TC-54 (HRM_OWNER): dua cac index nghiep vu cua 6 bang lon ve INVISIBLE de do
-- "truoc index". Index INVISIBLE van duoc cap nhat va van bao dam UNIQUE, chi la
-- optimizer bo qua (tru phien bat optimizer_use_invisible_indexes = TRUE).
-- Khong dong vao index cua khoa chinh (PK): noi bang theo PK la mac dinh.
-- Tra lai: tests/perf/tc54_hien_index_owner.sql
-- =============================================================================
set feedback off
set linesize 200
begin
  for r in (select i.index_name, i.table_name
              from user_indexes i
             where i.table_name in ('CHAM_CONG', 'CHI_TIET_NGHI_PHEP', 'DANG_KY_TANG_CA',
                                    'PHIEU_LUONG', 'CHI_TIET_PHIEU_LUONG', 'QUA_TRINH_CONG_TAC')
               and not exists (select 1 from user_constraints c
                                where c.index_name = i.index_name and c.constraint_type = 'P')
             order by i.table_name, i.index_name) loop
    execute immediate 'alter index ' || r.index_name || ' invisible';
    dbms_output.put_line('AN    ' || rpad(r.table_name, 22) || r.index_name);
  end loop;
end;
/
