-- U_HR02 duyet quyet dinh TC45/2026 do U_HR01 tao (muc 2.4), COMMIT
set feedback off
begin
  hrm_owner.pkg_hr.sp_duyet_khen_thuong('TC45/2026/QĐ-KT', 'DA_DUYET');
  dbms_output.put_line('PASS  U_HR02 duyet quyet dinh TC45/2026 do U_HR01 tao');
  commit;
end;
/
