-- Demo luong buoc 2 (U_PAY01): chuyen thuong 001/2026 vao ky 01; tinh va khoa
-- ky 01, 02; tinh ky 03 (de "tam tinh" - bao cao phai ghi ro).
set feedback off
declare
  v_so  number;
  v_loi clob;
  v_id  number;
begin
  hrm_owner.pkg_payroll.sp_chuyen_thuong('001/2026/QĐ-KT', 1, 2026, v_id);
  for t in 1 .. 3 loop
    hrm_owner.pkg_payroll.sp_tinh_luong_ky(t, 2026, v_so, v_loi);
    if v_so > 0 then
      dbms_output.put_line('FAIL  tinh ky ' || t || ': ' || v_loi);
      rollback;
      return;
    end if;
    if t < 3 then
      hrm_owner.pkg_payroll.sp_khoa_ky_luong(t, 2026);
    end if;
    dbms_output.put_line('Da tinh ky ' || lpad(t, 2, '0') || '/2026' || case when t < 3 then ' va khoa' else ' (tam tinh)' end);
  end loop;
  commit;
end;
/
