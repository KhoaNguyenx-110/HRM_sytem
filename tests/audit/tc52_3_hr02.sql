-- =============================================================================
-- TC-52 buoc 3 (U_HR02): duyet phat sinh do U_PAY01 lap (lay tu VW-08), COMMIT
-- =============================================================================
set feedback off
set linesize 250
declare
  v_id number;
begin
  select ma_yeu_cau into v_id from hrm_owner.vw_don_cho_duyet
   where loai_yeu_cau = 'PHAT_SINH_LUONG' and ma_nhan_vien = 'NV_C' and ly_do like 'TC-52%';
  hrm_owner.pkg_hr.sp_duyet_phat_sinh(v_id, 'DA_DUYET');
  commit;
  dbms_output.put_line('Da COMMIT duyet phat sinh ' || v_id);
end;
/
