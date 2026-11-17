-- =============================================================================
-- TC-42 khoa ky; TC-34b, TC-45b sau khoa - chay bang U_PAY01, COMMIT
--   Khoa khi phien ban lech -> tu choi; tinh lai roi khoa -> DA_KHOA.
--   Sau khoa: tinh lai, ghi phat sinh, chuyen thuong, sua phu cap ky 01 -> tu choi;
--   Payroll khong co quyen DML truc tiep tren bang chi tiet.
-- =============================================================================
set feedback off
declare
  v_so  number;
  v_loi clob;
  v_id  number;
  v_goc number;
  v_ky  hrm_owner.ky_luong%rowtype;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure bi_chan(p_ten varchar2, p_ma number) is
  begin
    dat(p_ten || ' bi tu choi (' || sqlcode || '): ' || substr(sqlerrm, 12, 90), sqlcode = p_ma);
  end;
begin
  select * into v_ky from hrm_owner.ky_luong where nam = 2026 and thang = 1;
  begin
    hrm_owner.pkg_payroll.sp_khoa_ky_luong(1, 2026);
    dat('TC-42 Khoa ky khi phien ban lech -> khong bi chan', false);
  exception when others then
    bi_chan('TC-42 Khoa ky phien ban lech (' || v_ky.phien_ban_dau_vao || ' <> ' || v_ky.phien_ban_da_tinh || ')', -20504);
  end;

  hrm_owner.pkg_payroll.sp_tinh_luong_ky(1, 2026, v_so, v_loi);
  dat('TC-42 Tinh lai ky 01 sau khi go phat sinh loi: ' || v_so || ' loi', v_so = 0);
  hrm_owner.pkg_payroll.sp_khoa_ky_luong(1, 2026);
  select * into v_ky from hrm_owner.ky_luong where nam = 2026 and thang = 1;
  dat('TC-42 Khoa ky 01/2026: ' || v_ky.trang_thai, v_ky.trang_thai = 'DA_KHOA');
  commit;

  -- Sau khi khoa
  begin
    hrm_owner.pkg_payroll.sp_tinh_luong_ky(1, 2026, v_so, v_loi);
    dat('TC-42 Tinh lai ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('TC-42 Tinh lai ky da khoa', -20501);
  end;
  begin
    hrm_owner.pkg_payroll.sp_khoa_ky_luong(1, 2026);
    dat('TC-42 Khoa lai ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('TC-42 Khoa lai ky da khoa', -20501);
  end;
  begin
    hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_A', 1, 2026, 'DIEU_CHINH_TANG', 200000, 'TC-34 vào kỳ đã khóa', null, v_id);
    dat('TC-34 Ghi phat sinh vao ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('TC-34 Ghi phat sinh vao ky da khoa', -20501);
  end;
  begin
    hrm_owner.pkg_payroll.sp_chuyen_thuong('TC45/2026/QĐ-KT', 1, 2026, v_id);
    dat('TC-45 Chuyen thuong vao ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('TC-45 Chuyen thuong vao ky da khoa', -20501);
  end;
  begin
    hrm_owner.pkg_payroll.sp_luu_phu_cap('NV_B', 'PC_TRACH_NHIEM', 2500000, date '2026-01-01', date '2026-01-31', true);
    dat('BR-38 Sua phu cap thuoc ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('BR-38 Sua phu cap thuoc ky da khoa', -20501);
  end;
  begin
    execute immediate 'update hrm_owner.chi_tiet_phieu_luong set he_so = 2 where rownum = 1';
    dat('TC-42 Payroll sua truc tiep chi tiet phieu -> khong bi chan', false);
  exception when others then
    dat('TC-42 Payroll sua truc tiep chi tiet phieu: khong co quyen (' || sqlcode || ')', sqlcode in (-942, -1031));
  end;

  -- Dieu chinh dung cach cho ky da khoa: ghi o ky chua khoa, tham chieu phieu goc (BR-32)
  select phieu_luong_id into v_goc from hrm_owner.vw_bang_luong_tong_hop
   where nam = 2026 and thang = 1 and ma_nhan_vien = 'NV_A';
  begin
    hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_B', 2, 2026, 'DIEU_CHINH_TANG', 200000, 'TC-34 phiếu gốc người khác', v_goc, v_id);
    dat('BR-32 Phieu goc cua nguoi khac -> khong bi chan', false);
  exception when others then bi_chan('BR-32 Phieu goc cua nguoi khac', -20521);
  end;
  hrm_owner.pkg_payroll.sp_luu_phat_sinh('NV_A', 2, 2026, 'DIEU_CHINH_TANG', 200000,
    'Truy lĩnh chênh lệch kỳ 01/2026', v_goc, v_id);
  dat('BR-32 Dieu chinh ky 01 (da khoa) ghi o ky 02, tham chieu phieu goc', v_id is not null);

  -- Thuong TC45 vao ky 02 (chua khoa) - TC-41 kiem tra tren phieu thang 02
  hrm_owner.pkg_payroll.sp_chuyen_thuong('TC45/2026/QĐ-KT', 2, 2026, v_id);
  dat('TC-45 Chuyen thuong TC45/2026 vao ky 02/2026', v_id is not null);
  commit;
end;
/
