-- =============================================================================
-- TC-47 (U_HR01): nhan su tai mot ngay trong qua khu; hop dong het han nguong 30 ngay
--   * NV023 (dieu chuyen 01/02/2026): 15/01 thuoc KINH_DOANH, 15/02 thuoc KY_THUAT
--   * Tong theo phong tai ngay = so nguoi dang lam tai ngay (tong khop chi tiet)
--   * VW-06 nguong 30 ngay tu 15/11/2026: NV009, NV022; loai hop dong da huy
--     (TC47-HUY) va hop dong khong thoi han
--   * Chuan bi QR-05: them nhan vien moi NV051 (chua co tai khoan) - COMMIT
-- =============================================================================
set feedback off
declare
  v_pb1   varchar2(20);
  v_pb2   varchar2(20);
  v_tong  number;
  v_ct    number;
  v_dang  number;
  v_ds    varchar2(200);
  v_huy   number;
  v_null  number;
  v_id    number;
  c_ngay  constant date := date '2026-01-15';
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select ma_phong_ban into v_pb1 from hrm_owner.vw_qua_trinh_cong_tac
   where ma_nhan_vien = 'NV023' and date '2026-01-15' between ngay_bat_dau and nvl(ngay_ket_thuc, date '9999-12-31');
  select ma_phong_ban into v_pb2 from hrm_owner.vw_qua_trinh_cong_tac
   where ma_nhan_vien = 'NV023' and date '2026-02-15' between ngay_bat_dau and nvl(ngay_ket_thuc, date '9999-12-31');
  dat('TC-47 NV023 tai 15/01: ' || v_pb1 || '; tai 15/02: ' || v_pb2 || ' (dung lich su, khong dung phong hien tai)',
      v_pb1 = 'KINH_DOANH' and v_pb2 = 'KY_THUAT');

  -- Tong theo phong (nhu QR-02) khop chi tiet va khop so nguoi dang lam (VW-01)
  select sum(so) into v_tong from (
    select ma_phong_ban, count(*) as so from hrm_owner.vw_qua_trinh_cong_tac
     where c_ngay between ngay_bat_dau and nvl(ngay_ket_thuc, date '9999-12-31')
     group by ma_phong_ban);
  select count(*) into v_ct from hrm_owner.vw_qua_trinh_cong_tac
   where c_ngay between ngay_bat_dau and nvl(ngay_ket_thuc, date '9999-12-31');
  select count(*) into v_dang from hrm_owner.vw_ho_so_nhan_vien
   where ngay_vao_lam <= c_ngay and (ngay_nghi_viec is null or ngay_nghi_viec >= c_ngay);
  dat('TC-47 Tai 15/01/2026: tong theo phong ' || v_tong || ' = chi tiet ' || v_ct
      || ' = nguoi dang lam ' || v_dang, v_tong = v_ct and v_ct = v_dang);

  -- VW-06 nguong 30 ngay
  select listagg(ma_nhan_vien, ',') within group (order by ma_nhan_vien),
         count(case when so_hop_dong = 'TC47-HUY' then 1 end)
    into v_ds, v_huy
    from hrm_owner.vw_hop_dong_sap_het_han
   where ngay_ket_thuc between date '2026-11-15' and date '2026-11-15' + 30;
  dat('TC-47 Hop dong het han trong 30 ngay tu 15/11/2026: ' || v_ds, v_ds = 'NV009,NV022');
  dat('TC-47 Hop dong da huy TC47-HUY (het han 25/11) bi loai', v_huy = 0);
  select count(*) into v_null from hrm_owner.vw_hop_dong_sap_het_han where ngay_ket_thuc is null;
  dat('TC-47 Hop dong khong thoi han khong co trong VW-06: ' || v_null, v_null = 0);

  -- Chuan bi QR-05
  hrm_owner.pkg_hr.sp_them_nhan_vien('NV051', 'Trần Thị Mới', date '2000-05-05', '079200000051',
    '079200000051', 'nv051@hrm.example.com', '0901234051', 'Số 51, Quận 1, TP. Hồ Chí Minh',
    date '2026-11-02', 'NHAN_SU', 'NHAN_VIEN', v_id);
  dat('QR-05 chuan bi: HR them NV051 vao lam 02/11/2026 (chua co tai khoan)', v_id is not null);
  commit;
end;
/
