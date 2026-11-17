-- =============================================================================
-- TC-34c, chuan bi TC-38 - chay bang U_PAY01, COMMIT
--   TC-34c: them phat sinh sau khi tinh -> ky ve CHOT_CONG, PhienBanDauVao tang
--   TC-38 : khau tru 100 trieu cho NV_C (U_HR02 duyet o buoc sau) -> net am
-- =============================================================================
set feedback off
declare
  v_truoc hrm_owner.ky_luong%rowtype;
  v_sau   hrm_owner.ky_luong%rowtype;
  v_id    number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select * into v_truoc from hrm_owner.ky_luong where nam = 2026 and thang = 1;
  hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_C', 1, 2026, 'KHAU_TRU', 100000000,
    'TC-38 khấu trừ vượt lương (dữ liệu kiểm thử)', null, v_id);
  select * into v_sau from hrm_owner.ky_luong where nam = 2026 and thang = 1;
  dat('TC-34 Them phat sinh sau khi tinh: ' || v_truoc.trang_thai || ' -> ' || v_sau.trang_thai
      || ', phien ban dau vao ' || v_truoc.phien_ban_dau_vao || ' -> ' || v_sau.phien_ban_dau_vao,
      v_truoc.trang_thai = 'DA_TINH' and v_sau.trang_thai = 'CHOT_CONG'
      and v_sau.phien_ban_dau_vao = v_truoc.phien_ban_dau_vao + 1);
  commit;
end;
/
