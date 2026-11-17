-- =============================================================================
-- Kenh 1 (web) qua HRM_APP: SP-27, SP-28, TC-02, TC-06 (dac ta muc 8.1)
-- Chay bang: scripts/run.sh HRM_APP tests/security/tc_kenh_web.sql
-- TC-02 khoa that tai khoan nv_c (autonomous COMMIT); tests/security/restore.sql
-- mo lai bang HRM_OWNER sau khi chay.
-- =============================================================================
set feedback off
declare
  v_id   number; v_hash varchar2(255); v_tt varchar2(10);
  v_id_khoa number;

  procedure kq(p_ten varchar2, p_dat boolean) is
  begin
    dbms_output.put_line(case when p_dat then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  -- SP-27: lay thong tin xac thuc, khong phan biet hoa/thuong (IX-02)
  hrm_owner.pkg_auth.lay_thong_tin_xac_thuc('NV_B', v_id, v_hash, v_tt);
  kq('SP-27 Lay hash theo ten (khong phan biet hoa/thuong)', v_id is not null and v_hash like '$2%');
  kq('SP-27 Trang thai HOAT_DONG', v_tt = 'HOAT_DONG');

  declare x number; y varchar2(255); z varchar2(10);
  begin
    hrm_owner.pkg_auth.lay_thong_tin_xac_thuc('khong_ton_tai', x, y, z);
    kq('SP-27 Ten khong ton tai tra NULL, khong bao loi rieng', x is null and y is null and z is null);
  end;

  -- SP-28: gan phien, doc, xoa
  hrm_owner.pkg_ctx.dat_phien(v_id);
  kq('SP-28 dat_phien nap dung tai khoan', sys_context('HRM_CTX', 'TAI_KHOAN_ID') = to_char(v_id));
  kq('SP-28 dat_phien nap vai tro EMPLOYEE', instr(sys_context('HRM_CTX', 'VAI_TRO'), ',EMPLOYEE,') > 0);
  kq('SP-28 Kenh WEB', sys_context('HRM_CTX', 'KENH') = 'WEB');

  -- TC-06: doi mat khau sang chuoi ro bi CHECK chan; trung mat khau cu bi chan
  begin
    hrm_owner.pkg_auth.sp_doi_mat_khau(v_hash, 'matkhau_ro_123');
    kq('TC-06 Luu mat khau ro -> khong bi chan', false);
  exception when others then
    kq('TC-06 Luu mat khau ro bi chan (' || sqlcode || ')', sqlcode = -20006);
  end;
  begin
    hrm_owner.pkg_auth.sp_doi_mat_khau(v_hash, v_hash);
    kq('TC-06 Mat khau moi trung cu -> khong bi chan', false);
  exception when others then
    kq('TC-06 Mat khau moi trung cu bi chan (' || sqlcode || ')', sqlcode = -20005);
  end;
  rollback;

  hrm_owner.pkg_ctx.xoa_phien;
  kq('SP-28 xoa_phien xoa het danh tinh (IT-04)',
     sys_context('HRM_CTX', 'TAI_KHOAN_ID') is null and sys_context('HRM_CTX', 'VAI_TRO') is null);

  -- BR-04: tai khoan KHOA va tai khoan khong ton tai khong nhan danh tinh
  hrm_owner.pkg_auth.lay_thong_tin_xac_thuc('nv_khoa', v_id_khoa, v_hash, v_tt);
  begin
    hrm_owner.pkg_ctx.dat_phien(v_id_khoa);
    kq('BR-04 dat_phien tai khoan KHOA -> khong bi chan', false);
  exception when others then
    kq('BR-04 dat_phien tai khoan KHOA bi tu choi (' || sqlcode || ')',
       sqlcode = -20001 and sys_context('HRM_CTX', 'TAI_KHOAN_ID') is null);
  end;
  begin
    hrm_owner.pkg_ctx.dat_phien(-1);
    kq('BR-04 dat_phien tai khoan khong ton tai -> khong bi chan', false);
  exception when others then
    kq('BR-04 dat_phien tai khoan khong ton tai bi tu choi (' || sqlcode || ')', sqlcode = -20001);
  end;

  -- TC-02: sai 5 lan lien tiep => KHOA
  for i in 1 .. 4 loop
    hrm_owner.pkg_auth.ghi_that_bai('nv_c');
  end loop;
  hrm_owner.pkg_auth.lay_thong_tin_xac_thuc('nv_c', v_id, v_hash, v_tt);
  kq('TC-02 Sai 4 lan van HOAT_DONG', v_tt = 'HOAT_DONG');
  hrm_owner.pkg_auth.ghi_that_bai('nv_c');
  hrm_owner.pkg_auth.lay_thong_tin_xac_thuc('nv_c', v_id, v_hash, v_tt);
  kq('TC-02 Sai lan thu 5 chuyen KHOA', v_tt = 'KHOA');
end;
/
