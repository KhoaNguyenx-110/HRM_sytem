-- =============================================================================
-- TC-22 (duyet OT), TC-27 (rut don nguoi khac), TC-29 (tu choi khong ly do)
-- chay bang U_TP_KT (truong phong Ky thuat)
--   scripts/run.sh U_TP_KT tests/att/tc22_29_tp_kt.sql
-- =============================================================================
set feedback off
declare
  v_id     number;
  v_ot_b   number;
  v_don_a  number;
  v_dem    number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure mong(p_ten varchar2, p_ma number, p_mong number) is
  begin
    dat(p_ten || ' (' || p_ma || ')', p_ma = p_mong);
  end;
begin
  -- VW-08: TP Ky thuat thay don cho cua phong minh
  select max(case when loai_yeu_cau = 'OT' and ma_nhan_vien = 'NV_B' then ma_yeu_cau end),
         max(case when loai_yeu_cau = 'NGHI_PHEP' and ma_nhan_vien = 'NV_A' then ma_yeu_cau end),
         count(*)
    into v_ot_b, v_don_a, v_dem
    from hrm_owner.vw_don_cho_duyet;
  dat('VW-08 TP_KT thay OT cho cua NV_B va don nghi cho cua NV_A', v_ot_b is not null and v_don_a is not null);

  -- TC-22: tu duyet OT cua minh
  hrm_owner.pkg_att.sp_dang_ky_ot(timestamp '2026-04-20 18:00:00', timestamp '2026-04-20 20:00:00', 'OT của TP', v_id);
  begin
    hrm_owner.pkg_att.sp_duyet_ot(v_id, 'DA_DUYET');
    dat('TC-22 Tu duyet OT -> khong bi chan', false);
  exception when others then mong('TC-22 Tu duyet OT bi tu choi', sqlcode, -20313);
  end;

  -- TC-22: gio duyet vuot gio dang ky (NV_B dang ky 2 gio)
  begin
    hrm_owner.pkg_att.sp_duyet_ot(v_ot_b, 'DA_DUYET', 3);
    dat('TC-22 Gio duyet vuot dang ky -> khong bi chan', false);
  exception when others then mong('TC-22 Gio duyet vuot dang ky bi tu choi', sqlcode, -20316);
  end;
  hrm_owner.pkg_att.sp_duyet_ot(v_ot_b, 'DA_DUYET', 1.5);
  dat('TC-22 Duyet 1,5 gio <= dang ky 2 gio', true);

  -- TC-27: nguoi khac (ke ca truong phong) khong rut duoc don cua NV_A
  begin
    hrm_owner.pkg_leave.sp_xu_ly_don_nghi(v_don_a, 'RUT');
    dat('TC-27 Rut don cua nguoi khac -> khong bi chan', false);
  exception when others then mong('TC-27 Rut don cua nguoi khac bi tu choi', sqlcode, -20405);
  end;

  -- TC-29: tu choi khong ly do
  begin
    hrm_owner.pkg_leave.sp_xu_ly_don_nghi(v_don_a, 'TU_CHOI');
    dat('TC-29 Tu choi khong ly do -> khong bi chan', false);
  exception when others then mong('TC-29 Tu choi khong ly do bi tu choi', sqlcode, -20408);
  end;
  hrm_owner.pkg_leave.sp_xu_ly_don_nghi(v_don_a, 'DUYET');
  dat('FR-LEV-04 TP duyet don nghi cua nhan vien phong minh', true);

  rollback;
  dbms_output.put_line('      (da ROLLBACK moi thay doi thu)');
end;
/
