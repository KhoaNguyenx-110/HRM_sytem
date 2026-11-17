-- TC-46 buoc 1: U_HR01 ghi ky luat cho NV010 (TP Nhan su phe duyet), COMMIT
set feedback off
begin
  hrm_owner.pkg_hr.sp_ghi_ky_luat('NV010', 'TC46/2026/QĐ-KL', date '2026-02-20',
    'TC-46 vi phạm nội quy an toàn', 'KHIEN_TRACH', 'nv004');
  dbms_output.put_line('PASS  TC-46 U_HR01 ghi ky luat TC46/2026 cho NV010');
  commit;
end;
/
