-- =============================================================================
-- TC-38: mot nhan vien net am - chay bang U_PAY01
--   Khong ghi gi ca ky (ket qua cu giu nguyen), tra danh sach nhan vien loi.
-- =============================================================================
set feedback off
declare
  v_so    number;
  v_loi   clob;
  v_truoc number;
  v_sau   number;
  v_id1   number;
  v_id2   number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select sum(tong_net), min(phieu_luong_id) into v_truoc, v_id1
    from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1;
  hrm_owner.pkg_payroll.sp_tinh_luong_ky(1, 2026, v_so, v_loi);
  dbms_output.put_line('  Danh sach loi: ' || rtrim(v_loi, chr(10)));
  dat('TC-38 Tinh ky co net am: ' || v_so || ' loi, co NET_AM | NV_C',
      v_so = 1 and v_loi like 'NET_AM | NV_C |%');
  select sum(tong_net), min(phieu_luong_id) into v_sau, v_id2
    from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1;
  dat('TC-38 Khong phieu nao cua ky bi ghi lai (ket qua cu giu nguyen)', v_sau = v_truoc and v_id1 = v_id2);
  rollback;
end;
/
