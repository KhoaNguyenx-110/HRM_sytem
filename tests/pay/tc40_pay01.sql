-- =============================================================================
-- TC-40: loi giua lan tinh lai - chay bang U_PAY01 (sau tc40_setup_owner.sql)
--   Ket qua lan truoc con nguyen (cung ID phieu, cung tong), khong co phieu do,
--   ky van DA_TINH (BR-22, NFR-10).
-- =============================================================================
set feedback off
declare
  v_so   number;
  v_loi  clob;
  v_tt   varchar2(10);
  type r_chup is record (so_phieu number, net number, id_nho number, id_lon number, so_dong number);
  v_truoc r_chup;
  v_sau   r_chup;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  function chup return r_chup is
    v r_chup;
  begin
    select count(*), sum(tong_net), min(phieu_luong_id), max(phieu_luong_id)
      into v.so_phieu, v.net, v.id_nho, v.id_lon
      from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1;
    select count(*) into v.so_dong from hrm_owner.vw_phieu_luong_ca_nhan where nam = 2026 and thang = 1;
    return v;
  end;
begin
  v_truoc := chup;
  begin
    hrm_owner.pkg_payroll.sp_tinh_luong_ky(1, 2026, v_so, v_loi);
    dat('TC-40 Tinh lai khi co loi giua chung -> khong bao loi', false);
  exception when others then
    dat('TC-40 Tinh lai gap loi giua chung (' || sqlcode || '): ' || substr(sqlerrm, 12, 60), sqlcode = -20999);
  end;
  v_sau := chup;
  dat('TC-40 Ket qua cu con nguyen: ' || v_sau.so_phieu || ' phieu, ' || v_sau.so_dong || ' dong, ID '
      || v_sau.id_nho || '..' || v_sau.id_lon,
      v_sau.so_phieu = v_truoc.so_phieu and v_sau.net = v_truoc.net and v_sau.so_dong = v_truoc.so_dong
      and v_sau.id_nho = v_truoc.id_nho and v_sau.id_lon = v_truoc.id_lon);
  select trang_thai into v_tt from hrm_owner.ky_luong where nam = 2026 and thang = 1;
  dat('TC-40 Ky van ' || v_tt, v_tt = 'DA_TINH');
  rollback;
end;
/
