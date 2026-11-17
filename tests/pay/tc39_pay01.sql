-- =============================================================================
-- TC-39: tinh lai hai lan voi cung dau vao - chay bang U_PAY01, COMMIT
--   So phieu, tong gross, tong net khong doi; phieu duoc ghi lai (ID moi),
--   khong trung phieu (UNIQUE(KY, NV) - BR-19, BR-23).
-- =============================================================================
set feedback off
declare
  v_so   number;
  v_loi  clob;
  type r_chup is record (so_phieu number, gross number, net number, bh number, thue number, id_nho number);
  v_truoc r_chup;
  v_sau   r_chup;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  function chup return r_chup is
    v r_chup;
  begin
    select count(*), sum(tong_gross), sum(tong_net), sum(bao_hiem_nld + bao_hiem_nsdld), sum(thue_tncn),
           min(phieu_luong_id)
      into v.so_phieu, v.gross, v.net, v.bh, v.thue, v.id_nho
      from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1;
    return v;
  end;
begin
  v_truoc := chup;
  for lan in 1 .. 2 loop
    hrm_owner.pkg_payroll.sp_tinh_luong_ky(1, 2026, v_so, v_loi);
    v_sau := chup;
    dat('TC-39 Tinh lai lan ' || lan || ': ' || v_sau.so_phieu || ' phieu, gross '
        || to_char(v_sau.gross, 'FM999G999G999G990') || ', net ' || to_char(v_sau.net, 'FM999G999G999G990')
        || ' (truoc: ' || v_truoc.so_phieu || ' phieu, net ' || to_char(v_truoc.net, 'FM999G999G999G990') || ')',
        v_so = 0 and v_sau.so_phieu = v_truoc.so_phieu and v_sau.gross = v_truoc.gross
        and v_sau.net = v_truoc.net and v_sau.bh = v_truoc.bh and v_sau.thue = v_truoc.thue);
    dat('TC-39 Lan ' || lan || ' ghi lai phieu moi (ID nho nhat ' || v_truoc.id_nho || ' -> ' || v_sau.id_nho
        || '), khong giu phieu cu', v_sau.id_nho > v_truoc.id_nho);
    v_truoc := v_sau;
  end loop;
  commit;
end;
/
