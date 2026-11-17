-- =============================================================================
-- TC-52 buoc 4 (U_PAY01): tinh lai va khoa ky 03/2026 (TC-42), COMMIT;
--   sau khoa, them phat sinh vao ky 03 phai bi tu choi.
-- =============================================================================
set feedback off
set linesize 250
declare
  v_so  number;
  v_loi clob;
  v_id  number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  hrm_owner.pkg_payroll.sp_tinh_luong_ky(3, 2026, v_so, v_loi);
  dat('TC-52 Tinh lai ky 03/2026: ' || v_so || ' loi', v_so = 0);
  hrm_owner.pkg_payroll.sp_khoa_ky_luong(3, 2026);
  commit;
  begin
    hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_C', 3, 2026, 'THUONG', 500000, 'TC-52 sau khoa', null, v_id);
    dat('TC-52 Them phat sinh vao ky da khoa -> khong bi chan', false);
  exception when others then
    dat('TC-52 Them phat sinh vao ky da khoa bi tu choi (' || sqlcode || ')', sqlcode = -20501);
    rollback;
  end;
end;
/
