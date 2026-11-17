-- =============================================================================
-- TC-48 (U_TP_KT): bao cao cong/phep/OT co don tu choi va don da rut
--   * Chi thay phong Ky thuat (VW-03, VW-14)
--   * NV039 (don TU_CHOI 24/02) va NV040 (don DA_RUT 02/03): van thay trong VW-14 de
--     doi chieu, nhung KHONG duoc cong vao bao cao (QR-11) hay cong thang (VW-03)
--   * Tong buoi nghi da duyet phong Ky thuat quy 1/2026 = 7 buoi
--     (NV_B 2 ngay = 4 buoi, NV037 om 1 ngay = 2 buoi, NV038 chieu 20/03 = 1 buoi)
-- =============================================================================
set feedback off
declare
  v_n    number;
  v_tc   number;
  v_rut  number;
  v_buoi number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select count(*) into v_n from hrm_owner.vw_cong_thang where nvl(ma_phong_ban, '?') <> 'KY_THUAT';
  dat('TC-48 VW-03: dong ngoai phong Ky thuat = ' || v_n, v_n = 0);
  select count(*) into v_n from hrm_owner.vw_nghi_phep_chi_tiet where nvl(ma_phong_ban, '?') <> 'KY_THUAT';
  dat('TC-48 VW-14: dong ngoai phong Ky thuat = ' || v_n, v_n = 0);
  select count(*) into v_n from hrm_owner.vw_nghi_phep_chi_tiet where ma_nhan_vien = 'NV_C';
  dat('TC-48 Khong thay don nghi cua NV_C (phong Kinh doanh): ' || v_n, v_n = 0);

  select count(case when trang_thai_don = 'TU_CHOI' then 1 end),
         count(case when trang_thai_don = 'DA_RUT' then 1 end)
    into v_tc, v_rut
    from hrm_owner.vw_nghi_phep_chi_tiet where ma_nhan_vien in ('NV039', 'NV040');
  dat('TC-48 Doi chieu duoc: ' || v_tc || ' buoi don tu choi, ' || v_rut || ' buoi don da rut', v_tc > 0 and v_rut > 0);

  -- QR-11 chi cong DA_DUYET
  select count(*) into v_n from hrm_owner.vw_nghi_phep_chi_tiet
   where trang_thai_don = 'DA_DUYET' and ma_nhan_vien in ('NV039', 'NV040');
  dat('TC-48 QR-11 khong cong buoi cua don tu choi / da rut: ' || v_n, v_n = 0);
  select count(*) into v_buoi from hrm_owner.vw_nghi_phep_chi_tiet
   where trang_thai_don = 'DA_DUYET' and ngay between date '2026-01-01' and date '2026-03-31';
  dat('TC-48 QR-11 tong buoi nghi da duyet phong Ky thuat quy 1: ' || v_buoi, v_buoi = 7);

  select nvl(sum(ngay_nghi_huong_luong + ngay_nghi_khong_luong), 0) into v_n from hrm_owner.vw_cong_thang
   where (ma_nhan_vien = 'NV039' and thang = 2) or (ma_nhan_vien = 'NV040' and thang = 3);
  dat('TC-48 VW-03 ngay nghi cua NV039 (02) va NV040 (03): ' || v_n, v_n = 0);
end;
/
