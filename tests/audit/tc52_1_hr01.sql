-- =============================================================================
-- TC-52 buoc 1 (U_HR01): thay doi nhay cam phia HR, COMMIT
--   TC-13: sua email ho so NV_C
--   TC-14: hop dong chong hieu luc (bi tu choi - khong duoc de lai audit);
--          dieu chinh luong HD-NV_A-01 tu 01/12/2026 (thanh cong)
--   Han muc phep: dieu chinh NV_B nam 2026 them 1 ngay
-- =============================================================================
set feedback off
set linesize 250
declare
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  hrm_owner.pkg_hr.sp_cap_nhat_nhan_vien('NV_C', p_email => 'nv.c.tc52@hrm.example.com');
  begin
    hrm_owner.pkg_hr.sp_luu_hop_dong('NV_A', 'HD-TC52-LOI', 'XAC_DINH', date '2026-12-01', date '2027-11-30',
                                     30000000, 30000000);
    dat('TC-52 Hop dong chong hieu luc -> khong bi chan', false);
  exception when others then
    dat('TC-52 Hop dong chong hieu luc bi tu choi (' || sqlcode || ')', sqlcode = -20205);
  end;
  hrm_owner.pkg_hr.sp_dieu_chinh_luong('HD-NV_A-01', date '2026-12-01', 28000000, 28000000);
  hrm_owner.pkg_leave.sp_luu_han_muc_phep('NV_B', 2026, 12, 1, 'TC-52 thưởng thâm niên', true);
  commit;
  dbms_output.put_line('Da COMMIT thay doi cua U_HR01');
end;
/
