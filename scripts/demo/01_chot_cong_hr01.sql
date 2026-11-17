-- Demo luong buoc 1 (U_HR01): chot cong 01, 02, 03/2026
set feedback off
declare
  v_so  number;
  v_loi clob;
begin
  for t in 1 .. 3 loop
    hrm_owner.pkg_att.sp_chot_cong(t, 2026, v_so, v_loi);
    dbms_output.put_line(case when v_so = 0 then 'Da ' else 'FAIL  ' end || 'chot cong '
      || lpad(t, 2, '0') || '/2026: ' || v_so || ' loi' || case when v_so > 0 then chr(10) || v_loi end);
  end loop;
  commit;
end;
/
