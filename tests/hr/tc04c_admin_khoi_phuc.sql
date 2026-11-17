-- =============================================================================
-- TC-04 buoc 3 - chay bang U_ADMIN: cap lai HR cho nv006, kiem tra audit
--   scripts/run.sh U_ADMIN tests/hr/tc04c_admin_khoi_phuc.sql
-- =============================================================================
set feedback off
declare
  v_xoa number;
  v_them number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  hrm_owner.pkg_admin.sp_gan_vai_tro('nv006', 'HR');
  commit;

  -- Audit cua lan thu hoi (DELETE) va cap lai (INSERT) do U_ADMIN thuc hien
  select count(case when thao_tac = 'DELETE' then 1 end),
         count(case when thao_tac = 'INSERT' then 1 end)
    into v_xoa, v_them
    from hrm_owner.vw_nhat_ky
   where doi_tuong = 'TAI_KHOAN_VAI_TRO' and ten_dang_nhap = 'admin';
  dat('TC-04 Audit thu hoi vai tro (DELETE, nguoi = admin)', v_xoa >= 1);
  dat('TC-04 Audit cap lai vai tro (INSERT, nguoi = admin)', v_them >= 1);
end;
/
