-- =============================================================================
-- TC-52 buoc 2 (U_PAY01): lap phat sinh thuong cho NV_C ky 03/2026 (TC-34), COMMIT
-- =============================================================================
set feedback off
set linesize 250
declare
  v_id number;
begin
  hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_C', 3, 2026, 'THUONG', 2000000,
    'TC-52 thưởng doanh số quý I', null, v_id);
  commit;
  dbms_output.put_line('Da COMMIT phat sinh ' || v_id || ' (CHO_DUYET)');
end;
/
