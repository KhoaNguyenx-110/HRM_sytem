-- =============================================================================
-- TC-29: nguoi nhieu vai tro (HR + MANAGER) van khong tu duyet don cua minh
--   scripts/run.sh U_TP_NS tests/att/tc29_tp_ns.sql
-- =============================================================================
set feedback off
declare
  v_id number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-04-20', date '2026-04-20', 'CA_NGAY', 'Việc riêng', v_id);
  begin
    hrm_owner.pkg_leave.sp_xu_ly_don_nghi(v_id, 'DUYET');
    dat('TC-29 HR+MANAGER tu duyet don cua minh -> khong bi chan', false);
  exception when others then
    dat('TC-29 HR+MANAGER tu duyet don cua minh bi tu choi (' || sqlcode || ')', sqlcode = -20407);
  end;
  rollback;
end;
/
