-- TC-26 buoc 2 (U_NV_A): dang ky nghi trong ky da chot cong -> tu choi toan don
set feedback off
declare
  v_id number;
begin
  -- Don keo dai 30/03 - 02/04: thang 3 da chot nen ca don bi tu choi
  hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-03-30', date '2026-04-02', 'CA_NGAY', 'Thử', v_id);
  dbms_output.put_line('FAIL  TC-26 Nghi trong ky da chot cong -> khong bi chan');
  rollback;
exception when others then
  dbms_output.put_line(case when sqlcode = -20301 then 'PASS  ' else 'FAIL  ' end
    || 'TC-26 Nghi trong ky da chot cong bi tu choi toan don (' || sqlcode || ')');
  rollback;
end;
/
