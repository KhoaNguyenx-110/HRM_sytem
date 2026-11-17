-- =============================================================================
-- TC-22, TC-29: truong phong Kinh doanh duyet don/OT cua phong Ky thuat
--   scripts/run.sh U_TP_KD tests/att/tc22_29_tp_kd.sql
-- Ma don lay tu VW-11 khong duoc (khong phai cua minh) va VW-08 (khong hien) ->
-- doc ma qua ban danh muc khong duoc; dung SQL dong de thu tung ma 1..200.
-- =============================================================================
set feedback off
declare
  v_dem     number;
  v_ot_ok   number := 0;
  v_don_ok  number := 0;
  v_sai     number := 0;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select count(*) into v_dem from hrm_owner.vw_don_cho_duyet where ma_nhan_vien in ('NV_A', 'NV_B');
  dat('VW-08 TP_KD khong thay don cua phong Ky thuat', v_dem = 0);

  -- Thu duyet moi OT va don nghi dang cho (ma 1..50): ket qua phai la -20313/-20407
  -- cho don phong khac, khong lan nao duyet duoc
  for i in 1 .. 50 loop
    begin
      hrm_owner.pkg_att.sp_duyet_ot(i, 'DA_DUYET');
      v_ot_ok := v_ot_ok + 1;
    exception when others then
      if sqlcode not in (-20313, -20312, -20321) then v_sai := v_sai + 1; end if;
    end;
    begin
      hrm_owner.pkg_leave.sp_xu_ly_don_nghi(i, 'DUYET');
      v_don_ok := v_don_ok + 1;
    exception when others then
      if sqlcode not in (-20407, -20406, -20414) then v_sai := v_sai + 1; end if;
    end;
  end loop;
  dat('TC-22 TP_KD khong duyet duoc OT phong khac (OT duyet duoc: ' || v_ot_ok || ')', v_ot_ok = 0);
  dat('TC-29 TP_KD khong duyet duoc don nghi phong khac (don duyet duoc: ' || v_don_ok || ')', v_don_ok = 0);
  dat('Moi lan bi tu choi deu dung ma loi nghiep vu', v_sai = 0);
  rollback;
end;
/
