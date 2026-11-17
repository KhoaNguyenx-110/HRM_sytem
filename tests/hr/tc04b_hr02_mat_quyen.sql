-- =============================================================================
-- TC-04 buoc 2 - chay bang U_HR02 SAU tc03_08_admin.sql
--   scripts/run.sh U_HR02 tests/hr/tc04b_hr02_mat_quyen.sql
-- Phien moi khong con vai tro HR. User Oracle van con role R_HR (lop 1 cho goi),
-- nhung procedure doc vai tro tu HRM_CTX va tu choi (lop 2) - dung y muc 8.2.
-- =============================================================================
set feedback off
declare
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  dat('TC-04 Phien moi cua U_HR02 khong con HR (' || sys_context('HRM_CTX', 'VAI_TRO') || ')',
      instr(sys_context('HRM_CTX', 'VAI_TRO'), ',HR,') = 0);
  begin
    hrm_owner.pkg_hr.sp_cap_nhat_nhan_vien('NV_C', p_email => 'x@hrm.example.com');
    dat('TC-04 Goi nghiep vu HR sau khi bi thu hoi -> khong bi chan', false);
  exception when others then
    dat('TC-04 Goi nghiep vu HR sau khi bi thu hoi bi tu choi (' || sqlcode || ')', sqlcode = -20009);
  end;
  rollback;
end;
/
