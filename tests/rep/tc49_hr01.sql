-- TC-49 (U_HR01): dieu chuyen NV024 tu Kinh doanh sang Ke toan tu 01/11/2026, COMMIT
set feedback off
begin
  hrm_owner.pkg_hr.sp_dieu_chuyen('NV024', 'KE_TOAN', 'NHAN_VIEN', date '2026-11-01',
    'TC-49 điều chuyển sau khi kỳ 01, 02 đã khóa');
  dbms_output.put_line('PASS  TC-49 U_HR01 dieu chuyen NV024 sang KE_TOAN tu 01/11/2026');
  commit;
end;
/
