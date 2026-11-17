-- =============================================================================
-- HR duyet phat sinh do Payroll lap - chay bang U_HR02, COMMIT
-- Ma phat sinh lay tu VW-08 (loai PHAT_SINH_LUONG).
-- =============================================================================
set feedback off
declare
  v_id number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select ma_yeu_cau into v_id from hrm_owner.vw_don_cho_duyet
   where loai_yeu_cau = 'PHAT_SINH_LUONG' and ma_nhan_vien = 'NV_C' and ly_do like 'TC-38%';
  dat('VW-08 HR thay phat sinh cho duyet ' || v_id, true);
  begin
    hrm_owner.pkg_hr.sp_duyet_phat_sinh(v_id, 'XYZ');
    dat('Ket qua duyet sai -> khong bi chan', false);
  exception when others then
    dat('Ket qua duyet sai bi tu choi (' || sqlcode || ')', sqlcode = -20523);
  end;
  hrm_owner.pkg_hr.sp_duyet_phat_sinh(v_id, 'DA_DUYET');
  dat('U_HR02 duyet phat sinh TC-38', true);
  begin
    hrm_owner.pkg_hr.sp_duyet_phat_sinh(v_id, 'TU_CHOI');
    dat('Duyet lai phat sinh da xu ly -> khong bi chan', false);
  exception when others then
    dat('Duyet lai phat sinh da xu ly bi tu choi (' || sqlcode || ')', sqlcode = -20523);
  end;
  commit;
end;
/
