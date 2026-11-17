-- =============================================================================
-- TC-43: nhan vien xem phieu - chay bang U_NV_A
--   Phieu cua minh o ky DA_KHOA: thay; phieu cua NV_B: 0 dong;
--   phieu ky chua khoa (02/2026 DA_TINH): 0 dong; VW-04 va pkg_payroll: khong co quyen.
-- =============================================================================
set feedback off
declare
  v_n   number;
  v_net number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select count(*), max(tong_net) into v_n, v_net from hrm_owner.vw_phieu_luong_ca_nhan
   where ma_nhan_vien = 'NV_A' and nam = 2026 and thang = 1;
  dat('TC-43 NV_A xem phieu 01/2026 (da khoa): ' || v_n || ' dong, net '
      || to_char(v_net, 'FM999G999G999'), v_n > 0 and v_net = 35635200);

  select count(*) into v_n from hrm_owner.vw_phieu_luong_ca_nhan where ma_nhan_vien = 'NV_B';
  dat('TC-43 Xem phieu cua NV_B: ' || v_n || ' dong', v_n = 0);
  select count(*) into v_n from hrm_owner.vw_phieu_luong_ca_nhan where ma_nhan_vien <> 'NV_A';
  dat('TC-43 Moi dong VW-05 deu cua chinh minh (dong cua nguoi khac: ' || v_n || ')', v_n = 0);
  select count(*) into v_n from hrm_owner.vw_phieu_luong_ca_nhan where nam = 2026 and thang = 2;
  dat('TC-43 Xem phieu ky 02/2026 chua khoa: ' || v_n || ' dong', v_n = 0);

  begin
    execute immediate 'select count(*) from hrm_owner.vw_bang_luong_tong_hop' into v_n;
    dat('TC-43 NV xem VW-04 quy luong -> khong bi chan', false);
  exception when others then
    dat('TC-43 NV xem VW-04 quy luong: khong co quyen (' || sqlcode || ')', sqlcode = -942);
  end;
  begin
    execute immediate 'begin hrm_owner.pkg_payroll.sp_khoa_ky_luong(2, 2026); end;';
    dat('TC-43 NV goi pkg_payroll -> khong bi chan', false);
  exception when others then
    dat('TC-43 NV goi pkg_payroll: khong co quyen (' || sqlcode || ')', sqlcode in (-6550, -942));
  end;
end;
/
