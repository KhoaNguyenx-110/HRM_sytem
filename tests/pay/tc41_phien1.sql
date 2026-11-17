-- =============================================================================
-- TC-41 phien 1 (U_PAY01, ket noi thu nhat): tinh ky 02/2026, giu khoa dong ky
-- 8 giay roi COMMIT. Phien 2 (tc41_phien2.sql) bat dau sau 2 giay.
-- =============================================================================
set feedback off
declare
  v_so  number;
  v_loi clob;
begin
  hrm_owner.pkg_payroll.sp_tinh_luong_ky(2, 2026, v_so, v_loi);
  dbms_output.put_line(case when v_so = 0 then 'PASS  ' else 'FAIL  ' end
    || 'TC-41 Phien 1 tinh ky 02/2026 (' || v_so || ' loi), giu khoa 8 giay'
    || case when v_so > 0 then chr(10) || v_loi end);
  dbms_session.sleep(8);
  commit;
end;
/
