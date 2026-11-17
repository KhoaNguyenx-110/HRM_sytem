-- =============================================================================
-- TC-21 (dang ky OT), TC-26 (dang ky nghi), TC-30 (tra cuu phep) - chay bang U_NV_A
--   scripts/run.sh U_NV_A tests/att/tc21_26_30_nv_a.sql
-- Ngay 20/04/2026 (thu Hai) chua co ky luong. ROLLBACK o cuoi.
-- =============================================================================
set feedback off
declare
  v_id  number;
  v_cap number; v_dung number; v_cho number; v_con number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure mong(p_ten varchar2, p_ma number, p_mong number) is
  begin
    dat(p_ten || ' (' || p_ma || ')', p_ma = p_mong);
  end;
begin
  -- ---------------------------------------------------------------- TC-21
  begin
    hrm_owner.pkg_att.sp_dang_ky_ot(timestamp '2026-04-20 20:00:00', timestamp '2026-04-20 19:00:00', 'Thử', v_id);
    dat('TC-21 OT ket thuc truoc bat dau -> khong bi chan', false);
  exception when others then mong('TC-21 OT ket thuc truoc bat dau bi tu choi', sqlcode, -20308);
  end;
  begin
    hrm_owner.pkg_att.sp_dang_ky_ot(timestamp '2026-04-20 20:00:00', timestamp '2026-04-21 01:00:00', 'Thử', v_id);
    dat('TC-21 OT qua ngay -> khong bi chan', false);
  exception when others then mong('TC-21 OT qua ngay bi tu choi', sqlcode, -20309);
  end;
  begin
    hrm_owner.pkg_att.sp_dang_ky_ot(timestamp '2026-04-20 22:00:00', timestamp '2026-04-20 23:00:00', 'Thử', v_id);
    dat('TC-21 OT ban dem -> khong bi chan', false);
  exception when others then mong('TC-21 OT ban dem bi tu choi', sqlcode, -20309);
  end;
  begin
    hrm_owner.pkg_att.sp_dang_ky_ot(timestamp '2026-04-20 16:00:00', timestamp '2026-04-20 18:00:00', 'Thử', v_id);
    dat('BR-13 OT trung gio lam thuong -> khong bi chan', false);
  exception when others then mong('BR-13 OT trung gio lam thuong bi tu choi', sqlcode, -20310);
  end;
  hrm_owner.pkg_att.sp_dang_ky_ot(timestamp '2026-04-20 18:00:00', timestamp '2026-04-20 20:00:00', 'Khoảng 1', v_id);
  begin
    hrm_owner.pkg_att.sp_dang_ky_ot(timestamp '2026-04-20 19:00:00', timestamp '2026-04-20 21:00:00', 'Thử', v_id);
    dat('TC-21 OT chong khoang -> khong bi chan', false);
  exception when others then mong('TC-21 OT chong khoang bi tu choi', sqlcode, -20311);
  end;
  hrm_owner.pkg_att.sp_dang_ky_ot(timestamp '2026-04-20 20:00:00', timestamp '2026-04-20 22:00:00', 'Khoảng 2', v_id);
  dat('TC-21 Hai khoang tiep giap [18,20) va [20,22) duoc chap nhan', v_id is not null);

  -- ---------------------------------------------------------------- TC-26
  begin
    hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-04-14', date '2026-04-14', 'SANG', 'Thử', v_id);
    dat('TC-26 Don trung buoi voi don cho -> khong bi chan', false);
  exception when others then mong('TC-26 Don trung buoi voi don cho bi tu choi', sqlcode, -20404);
  end;
  begin
    hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-04-18', date '2026-04-18', 'CA_NGAY', 'Thử', v_id);
    dat('TC-26 Nghi vao ngay nghi tuan -> khong bi chan', false);
  exception when others then mong('TC-26 Nghi vao ngay nghi tuan bi tu choi', sqlcode, -20403);
  end;

  -- ---------------------------------------------------------------- TC-30
  select so_ngay_duoc_cap, so_ngay_da_dung, so_ngay_cho_duyet, so_ngay_con_lai
    into v_cap, v_dung, v_cho, v_con
    from hrm_owner.vw_phep_con_lai where nam = 2026;
  dat('TC-30 NV_A: cap ' || v_cap || ', da dung ' || v_dung || ', cho ' || v_cho || ', con ' || v_con
      || ' (don cho tach rieng, khong tru)', v_cap = 12 and v_dung = 0 and v_cho = 2 and v_con = 12);

  rollback;
  dbms_output.put_line('      (da ROLLBACK moi thay doi thu)');
end;
/
