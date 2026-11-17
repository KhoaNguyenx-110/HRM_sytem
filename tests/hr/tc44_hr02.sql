-- =============================================================================
-- TC-44 (phan HR02): duyet khen thuong theo muc 2.4 - chay bang U_HR02
--   scripts/run.sh U_HR02 tests/hr/tc44_hr02.sql
-- =============================================================================
set feedback off
declare
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  -- HR02 duyet quyet dinh do HR01 tao: hop le
  hrm_owner.pkg_hr.sp_duyet_khen_thuong('003/2026/QĐ-KT', 'DA_DUYET');
  dat('TC-44 HR khac nguoi tao duyet quyet dinh', true);

  begin
    hrm_owner.pkg_hr.sp_duyet_khen_thuong('003/2026/QĐ-KT', 'DA_DUYET');
    dat('RWD-02 Duyet lai quyet dinh da duyet -> khong bi chan', false);
  exception when others then
    dat('RWD-02 Duyet lai quyet dinh da duyet bi tu choi (' || sqlcode || ')', sqlcode = -20603);
  end;

  -- HR02 tu tao roi tu duyet: bi chan
  hrm_owner.pkg_hr.sp_luu_khen_thuong('NV_C', '098/2026/QĐ-KT', date '2026-03-01', 'Thử tự duyệt', 'TIEN', 500000);
  begin
    hrm_owner.pkg_hr.sp_duyet_khen_thuong('098/2026/QĐ-KT', 'DA_DUYET');
    dat('TC-44 HR02 tu duyet quyet dinh minh tao -> khong bi chan', false);
  exception when others then
    dat('TC-44 HR02 tu duyet quyet dinh minh tao bi tu choi (' || sqlcode || ')', sqlcode = -20604);
  end;
  rollback;
end;
/
