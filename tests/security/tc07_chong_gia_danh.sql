-- =============================================================================
-- TC-07 (AUTH-06, BR-37): user demo tu gan danh tinh de gia danh nguoi khac
-- Chay bang: scripts/run.sh U_NV_A tests/security/tc07_chong_gia_danh.sql
-- Kem TC-06 (mot phan): doi mat khau voi mat khau hien tai sai.
-- =============================================================================
set feedback off
declare
  v_tk_goc varchar2(40) := sys_context('HRM_CTX', 'TAI_KHOAN_ID');
  v_dummy_id number; v_dummy_hash varchar2(255); v_dummy_tt varchar2(10);

  procedure kq(p_ten varchar2, p_dat boolean) is
  begin
    dbms_output.put_line(case when p_dat then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure mong_loi(p_ten varchar2, p_sql varchar2, p_ma number) is
  begin
    execute immediate p_sql;
    kq(p_ten || ' -> khong bi chan', false);
  exception when others then
    kq(p_ten || ' (' || sqlcode || ')', sqlcode = p_ma);
  end;
begin
  dbms_output.put_line('[U_NV_A] TEN_DANG_NHAP=' || sys_context('HRM_CTX', 'TEN_DANG_NHAP'));

  -- 1. Goi thang pkg_ctx: khong co EXECUTE => PLS-00201 trong ORA-06550
  mong_loi('TC-07 Goi pkg_ctx.dat_phien de gia danh',
           'begin hrm_owner.pkg_ctx.dat_phien(1); end;', -6550);

  -- 2. Ghi thang vao context: context gan voi pkg_ctx => ORA-01031
  mong_loi('TC-07 DBMS_SESSION.SET_CONTEXT tren HRM_CTX',
           'begin dbms_session.set_context(''HRM_CTX'', ''TAI_KHOAN_ID'', ''1''); end;', -1031);

  -- 3. Thu tuc chi danh cho HRM_APP
  begin
    hrm_owner.pkg_auth.lay_thong_tin_xac_thuc('nv_b', v_dummy_id, v_dummy_hash, v_dummy_tt);
    kq('TC-07 Doc hash mat khau nguoi khac -> khong bi chan', false);
  exception when others then
    kq('TC-07 Doc hash mat khau nguoi khac (' || sqlcode || ')', sqlcode = -20002);
  end;
  begin
    hrm_owner.pkg_auth.ghi_that_bai('nv_b');
    kq('TC-07 Tu khoa tai khoan nguoi khac -> khong bi chan', false);
  exception when others then
    kq('TC-07 Tu khoa tai khoan nguoi khac (' || sqlcode || ')', sqlcode = -20002);
  end;

  -- 4. Danh tinh khong doi sau cac lan thu
  kq('TC-07 Danh tinh phien giu nguyen', sys_context('HRM_CTX', 'TAI_KHOAN_ID') = v_tk_goc);

  -- TC-06: mat khau hien tai sai => khong cap nhat
  begin
    hrm_owner.pkg_auth.sp_doi_mat_khau('$2b$12$KHONG.DUNG.HASH.HIEN.TAI', '$2b$12$MOI');
    kq('TC-06 Doi mat khau voi mat khau cu sai -> khong bi chan', false);
  exception when others then
    kq('TC-06 Doi mat khau voi mat khau cu sai (' || sqlcode || ')', sqlcode = -20004);
  end;
  rollback;
end;
/
