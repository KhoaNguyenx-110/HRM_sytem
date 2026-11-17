-- TC-26 buoc 1 (U_HR01): chot cong 03/2026 va COMMIT
set feedback off
declare
  v_so number; v_ds clob;
begin
  hrm_owner.pkg_att.sp_chot_cong(3, 2026, v_so, v_ds);
  commit;
  dbms_output.put_line(case when v_so = 0 then 'PASS  ' else 'FAIL  ' end || 'TC-26 Chuan bi: chot cong 03/2026 (' || v_so || ' loi)');
end;
/
