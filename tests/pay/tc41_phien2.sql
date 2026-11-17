-- =============================================================================
-- TC-41 phien 2 (U_PAY01, ket noi thu hai): tinh cung ky 02/2026 trong luc phien
-- 1 giu khoa -> cho dung 5 giay (FOR UPDATE WAIT 5) roi bao "ky dang duoc xu ly".
-- =============================================================================
set feedback off
declare
  v_so      number;
  v_loi     clob;
  v_bat_dau timestamp := systimestamp;
  v_cho     number;
begin
  hrm_owner.pkg_payroll.sp_tinh_luong_ky(2, 2026, v_so, v_loi);
  dbms_output.put_line('FAIL  TC-41 Phien 2 tinh duoc ky dang bi phien 1 giu');
  rollback;
exception when others then
  v_cho := extract(second from (systimestamp - v_bat_dau));
  dbms_output.put_line(case when sqlcode = -20502 and v_cho between 4.5 and 7 then 'PASS  ' else 'FAIL  ' end
    || 'TC-41 Phien 2 cho ' || round(v_cho, 1) || ' giay roi bao ban (' || sqlcode || '): '
    || substr(sqlerrm, 12, 80));
  rollback;
end;
/
