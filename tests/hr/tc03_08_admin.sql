-- =============================================================================
-- TC-03, TC-04 (buoc 1), TC-08 - chay bang U_ADMIN
--   scripts/run.sh U_ADMIN tests/hr/tc03_08_admin.sql
-- Buoc cuoi thu hoi vai tro HR cua nv006 (U_HR02) va COMMIT de TC-04 buoc 2
-- kiem tra "phien moi mat quyen"; tc04c_admin_khoi_phuc.sql cap lai.
-- =============================================================================
set feedback off
declare
  v_id  number;
  v_dem number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure mong(p_ten varchar2, p_ma number, p_mong number) is
  begin
    dat(p_ten || ' (' || p_ma || ')', p_ma = p_mong);
  end;
begin
  -- TC-03: ten trung khac hoa/thuong; tai khoan thu hai cho mot nhan vien
  begin
    hrm_owner.pkg_admin.sp_tao_tai_khoan('NV_B', '$2b$12$test', null, null, v_id);
    dat('TC-03 Ten trung khac hoa/thuong -> khong bi chan', false);
  exception when others then mong('TC-03 Ten trung khac hoa/thuong bi tu choi', sqlcode, -20010);
  end;
  begin
    hrm_owner.pkg_admin.sp_tao_tai_khoan('nv_c_2', '$2b$12$test', 'NV_C', null, v_id);
    dat('TC-03 Tai khoan thu hai cho NV_C -> khong bi chan', false);
  exception when others then mong('TC-03 Tai khoan thu hai cho NV_C bi tu choi', sqlcode, -20011);
  end;
  begin
    hrm_owner.pkg_admin.sp_tao_tai_khoan('ky_thuat_1', 'matkhauro', null, null, v_id);
    dat('NFR-04 Tao tai khoan voi mat khau ro -> khong bi chan', false);
  exception when others then mong('NFR-04 Tao tai khoan voi mat khau ro bi tu choi', sqlcode, -20006);
  end;

  -- TC-04: gan vai tro trung; tu gan cho chinh minh
  begin
    hrm_owner.pkg_admin.sp_gan_vai_tro('nv_a', 'EMPLOYEE');
    dat('TC-04 Gan vai tro trung -> khong bi chan', false);
  exception when others then mong('TC-04 Gan vai tro trung bi tu choi', sqlcode, -20012);
  end;
  begin
    hrm_owner.pkg_admin.sp_gan_vai_tro('admin', 'PAYROLL');
    dat('Tach nhiem vu: Admin tu cap PAYROLL -> khong bi chan', false);
  exception when others then mong('Tach nhiem vu: Admin tu cap PAYROLL bi tu choi', sqlcode, -20014);
  end;

  -- TC-08: Admin khong xem ho so/luong, khong goi nghiep vu HR
  begin
    execute immediate 'select count(*) from hrm_owner.vw_ho_so_nhan_vien' into v_dem;
    dat('TC-08 Admin doc ho so nhan vien -> khong bi chan', false);
  exception when others then mong('TC-08 Admin doc ho so nhan vien bi tu choi', sqlcode, -942);
  end;
  begin
    execute immediate q'[begin hrm_owner.pkg_hr.sp_duyet_khen_thuong('003/2026/QĐ-KT', 'DA_DUYET'); end;]';
    dat('TC-08 Admin goi duyet quyet dinh -> khong bi chan', false);
  exception when others then mong('TC-08 Admin goi duyet quyet dinh bi tu choi', sqlcode, -6550);
  end;

  -- VW-09: Admin thay tai khoan, khong co cot hash mat khau
  select count(*) into v_dem from hrm_owner.vw_tai_khoan_quan_tri;
  dat('VW-09 Admin thay 51 tai khoan (' || v_dem || ')', v_dem = 51);
  select count(*) into v_dem from all_tab_columns
   where owner = 'HRM_OWNER' and table_name = 'VW_TAI_KHOAN_QUAN_TRI' and column_name like 'MAT_KHAU%';
  dat('VW-09 Khong co cot mat khau', v_dem = 0);
  rollback;

  -- TC-04 buoc 1: thu hoi HR cua nv006 va COMMIT
  hrm_owner.pkg_admin.sp_thu_hoi_vai_tro('nv006', 'HR');
  commit;
  dat('TC-04 Thu hoi HR cua nv006 va COMMIT', true);
end;
/
