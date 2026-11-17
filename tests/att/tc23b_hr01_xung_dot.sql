-- =============================================================================
-- TC-23 (cong + nghi vuot chuan) - chay bang U_HR01 SAU tc23_setup_owner.sql
--   scripts/run.sh U_HR01 tests/att/tc23b_hr01_xung_dot.sql
-- Procedure khong cho tao xung dot nay (BR-12 kiem tra khi ghi), nen du lieu loi
-- duoc chu schema chen truc tiep (giong seed_loi.sql) de chung minh lop kiem tra
-- thu hai khi chot cong.
-- =============================================================================
set feedback off
declare
  v_so number;
  v_ds clob;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  hrm_owner.pkg_att.sp_chot_cong(2, 2026, v_so, v_ds);
  dat('TC-23 Chot cong 02/2026 co xung dot: ' || v_so || ' loi', v_so = 1);
  dat('TC-23 Dong loi CONG_NGHI_VUOT_CHUAN cua NV_C ngay 10/02',
      instr(v_ds, 'CONG_NGHI_VUOT_CHUAN | NV_C | 10/02/2026') > 0);
  dbms_output.put_line('      ' || replace(v_ds, chr(10), ' ; '));
  rollback;
end;
/
