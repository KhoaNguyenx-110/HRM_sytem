-- =============================================================================
-- Truoc khi tinh ky 01/2026 - chay bang U_PAY01, COMMIT
--   TC-35b: tinh ky 12/2025 (da chot cong) khi chua co chinh sach -> tu choi
--   TC-33 : phu cap chong cung loai -> tu choi; phu cap het hieu luc 31/01
--   TC-45 : chuyen thuong 001/2026 vao ky 01; chuyen lan hai; thuong chua duyet
--   TC-34a: phat sinh chua duyet (se kiem tra: khong vao phieu)
-- =============================================================================
set feedback off
declare
  v_so    number;
  v_loi   clob;
  v_id    number;
  v_phieu number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure bi_chan(p_ten varchar2, p_ma number) is
  begin
    dat(p_ten || ' bi tu choi (' || sqlcode || '): ' || substr(sqlerrm, 12, 90), sqlcode = p_ma);
  end;
begin
  -- TC-35b
  begin
    hrm_owner.pkg_payroll.sp_tinh_luong_ky(12, 2025, v_so, v_loi);
    dat('TC-35 Tinh ky thieu chinh sach -> khong bi chan', false);
  exception when others then bi_chan('TC-35 Tinh ky 12/2025 thieu chinh sach', -20513);
  end;
  select count(*) into v_phieu from hrm_owner.vw_bang_luong_tong_hop where nam = 2025;
  dat('TC-35 Khong co phieu 12/2025 nao: ' || v_phieu, v_phieu = 0);

  -- TC-33
  begin
    hrm_owner.pkg_payroll.sp_luu_phu_cap('NV_B', 'PC_AN_TRUA', 800000, date '2026-02-01');
    dat('TC-33 Phu cap an trua chong khoang -> khong bi chan', false);
  exception when others then bi_chan('TC-33 Phu cap chong cung loai', -20518);
  end;
  begin
    hrm_owner.pkg_payroll.sp_luu_phu_cap('NV_B', 'PC_TRACH_NHIEM', 2000000, date '2026-01-15');
    dat('TC-33 Phu cap tu giua thang -> khong bi chan', false);
  exception when others then bi_chan('TC-33 Phu cap khong tron thang', -20527);
  end;
  begin
    hrm_owner.pkg_payroll.sp_luu_phu_cap('NV_B', 'LUONG_CONG', 2000000, date '2026-01-01');
    dat('TC-33 Ghi LUONG_CONG nhu phu cap -> khong bi chan', false);
  exception when others then bi_chan('TC-33 Khoan khong phai phu cap', -20519);
  end;
  hrm_owner.pkg_payroll.sp_luu_phu_cap('NV_B', 'PC_TRACH_NHIEM', 2000000, date '2026-01-01', date '2026-01-31');
  dat('TC-33 Phu cap trach nhiem NV_B chi trong thang 01/2026', true);

  -- TC-45
  hrm_owner.pkg_payroll.sp_chuyen_thuong('001/2026/QĐ-KT', 1, 2026, v_id);
  dat('TC-45 Chuyen thuong 001/2026 (12.000.000) vao ky 01/2026', v_id is not null);
  begin
    hrm_owner.pkg_payroll.sp_chuyen_thuong('001/2026/QĐ-KT', 2, 2026, v_id);
    dat('TC-45 Chuyen thuong lan hai -> khong bi chan', false);
  exception when others then bi_chan('TC-45 Chuyen thuong lan hai', -20507);
  end;
  begin
    hrm_owner.pkg_payroll.sp_chuyen_thuong('003/2026/QĐ-KT', 3, 2026, v_id);
    dat('TC-45 Chuyen thuong chua duyet -> khong bi chan', false);
  exception when others then bi_chan('TC-45 Chuyen thuong chua duyet', -20508);
  end;

  -- TC-34a: phat sinh CHO_DUYET (khong duoc tinh); kiem tra dau vao phat sinh
  hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_B', 1, 2026, 'THUONG', 1500000,
    'TC-34 thưởng chưa duyệt', null, v_id);
  dat('TC-34 Ghi phat sinh cho NV_B (CHO_DUYET)', v_id is not null);
  begin
    hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_B', 1, 2026, 'KHAU_TRU', 0, 'TC-34', null, v_id);
    dat('TC-34 Phat sinh 0 dong -> khong bi chan', false);
  exception when others then bi_chan('TC-34 Phat sinh so tien 0', -20522);
  end;
  begin
    hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_B', 1, 2026, 'BHXH_NLD', 100000, 'TC-34', null, v_id);
    dat('TC-34 Phat sinh khoan bao hiem -> khong bi chan', false);
  exception when others then bi_chan('TC-34 Phat sinh khoan khong THEO_PHAT_SINH', -20519);
  end;
  commit;
end;
/
