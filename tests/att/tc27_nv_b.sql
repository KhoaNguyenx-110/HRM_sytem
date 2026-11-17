-- =============================================================================
-- TC-27: rut don - chay bang U_NV_B
--   scripts/run.sh U_NV_B tests/att/tc27_nv_b.sql
-- Ma don lay tu VW-11 (yeu cau cua toi).
-- =============================================================================
set feedback off
declare
  v_da_duyet number;
  v_moi      number;
  v_tt       varchar2(20);
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select ma_yeu_cau into v_da_duyet from hrm_owner.vw_yeu_cau_cua_toi
   where loai_yeu_cau = 'NGHI_PHEP' and trang_thai = 'DA_DUYET';
  begin
    hrm_owner.pkg_leave.sp_xu_ly_don_nghi(v_da_duyet, 'RUT');
    dat('TC-27 Rut don da duyet -> khong bi chan', false);
  exception when others then
    dat('TC-27 Rut don da duyet bi tu choi (' || sqlcode || ')', sqlcode = -20406);
  end;

  hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-04-21', date '2026-04-21', 'CA_NGAY', 'Việc riêng', v_moi);
  hrm_owner.pkg_leave.sp_xu_ly_don_nghi(v_moi, 'RUT');
  select trang_thai into v_tt from hrm_owner.vw_yeu_cau_cua_toi where loai_yeu_cau = 'NGHI_PHEP' and ma_yeu_cau = v_moi;
  dat('TC-27 Rut don cho cua minh: trang thai ' || v_tt, v_tt = 'DA_RUT');

  -- Buoi da rut duoc giai phong khoi IX-14: dang ky lai cung buoi duoc
  hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-04-21', date '2026-04-21', 'CA_NGAY', 'Đăng ký lại', v_moi);
  dat('BR-16 Dang ky lai buoi cua don da rut', v_moi is not null);
  rollback;
end;
/
