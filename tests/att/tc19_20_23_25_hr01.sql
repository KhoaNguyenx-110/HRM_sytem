-- =============================================================================
-- TC-19, TC-20, TC-23 (thieu cong, don cho), TC-25 - chay bang U_HR01
--   scripts/run.sh U_HR01 tests/att/tc19_20_23_25_hr01.sql
-- ROLLBACK o cuoi.
-- =============================================================================
set feedback off
declare
  v_id    number;
  v_so    number;
  v_ds    clob;
  v_txt   varchar2(100);
  v_chuan number;
  v_qd    number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure mong(p_ten varchar2, p_ma number, p_mong number) is
  begin
    dat(p_ten || ' (' || p_ma || ')', p_ma = p_mong);
  end;
begin
  -- ---------------------------------------------------------------- TC-19
  begin
    hrm_owner.pkg_att.sp_luu_lich_lam_viec(date '2026-01-05', 'LAM_VIEC', 8, 12, 13, 17);
    dat('TC-19 Lich trung ngay -> khong bi chan', false);
  exception when others then mong('TC-19 Lich trung ngay bi tu choi', sqlcode, -20302);
  end;
  select so_gio_chuan, gio_quy_doi_luong into v_chuan, v_qd from hrm_owner.lich_lam_viec where ngay = date '2026-01-01';
  dat('TC-19 Ngay le: chuan 0, quy doi 8', v_chuan = 0 and v_qd = 8);
  select so_gio_chuan, gio_quy_doi_luong into v_chuan, v_qd from hrm_owner.lich_lam_viec where ngay = date '2026-01-03';
  dat('TC-19 Nghi tuan: chuan 0, quy doi 0', v_chuan = 0 and v_qd = 0);

  -- Chot cong thang 3 (du lieu sach) roi thu sua lich thang 3
  hrm_owner.pkg_att.sp_chot_cong(3, 2026, v_so, v_ds);
  dat('TC-23 Chot cong 03/2026 khi du lieu day du (' || v_so || ' loi)', v_so = 0);
  begin
    hrm_owner.pkg_att.sp_luu_lich_lam_viec(date '2026-03-05', 'LE', p_ten_ngay_le => 'Thử', p_sua => true);
    dat('TC-19 Sua lich cua ky da chot cong -> khong bi chan', false);
  exception when others then mong('TC-19 Sua lich cua ky da chot cong bi tu choi', sqlcode, -20301);
  end;
  begin
    hrm_owner.pkg_att.sp_luu_cham_cong('NV_A', date '2026-03-05', 7, true);
    dat('BR-25 Sua cong cua ky da chot -> khong bi chan', false);
  exception when others then mong('BR-25 Sua cong cua ky da chot bi tu choi', sqlcode, -20301);
  end;

  -- ---------------------------------------------------------------- TC-20
  begin
    hrm_owner.pkg_att.sp_luu_cham_cong('NV_A', date '2026-01-05', 8);
    dat('TC-20 Cong trung nguoi/ngay -> khong bi chan', false);
  exception when others then mong('TC-20 Cong trung nguoi/ngay bi tu choi', sqlcode, -20304);
  end;
  begin
    hrm_owner.pkg_att.sp_luu_cham_cong('NV_A', date '2026-01-05', 9, true);
    dat('TC-20 Gio lon hon chuan -> khong bi chan', false);
  exception when others then mong('TC-20 Gio lon hon chuan bi tu choi', sqlcode, -20306);
  end;
  begin
    hrm_owner.pkg_att.sp_luu_cham_cong('NV_B', date '2026-02-02', 2, true);
    hrm_owner.pkg_att.sp_luu_cham_cong('NV_C', date '2026-02-05', 6, true);
    dat('BR-12 NV_C nghi buoi sang 05/02 ma nhap 6 gio cong -> khong bi chan', false);
  exception when others then mong('BR-12 Cong + nghi vuot chuan bi tu choi', sqlcode, -20307);
  end;
  begin
    hrm_owner.pkg_att.sp_luu_cham_cong('NV_A', date '2026-01-03', 4, true);
    dat('FR-ATT-02 Nhap cong ngay nghi tuan -> khong bi chan', false);
  exception when others then mong('FR-ATT-02 Nhap cong ngay nghi tuan bi tu choi', sqlcode, -20305);
  end;
  hrm_owner.pkg_att.sp_luu_cham_cong('NV_A', date '2026-01-06', 7.5, true);
  dat('TC-20 Sua cong hop le trong [0, chuan]', true);

  -- ---------------------------------------------------------------- TC-23
  -- Tao loi trong transaction: don nghi cho cua chinh HR01 va nhan vien moi chua co cong
  hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-01-28', date '2026-01-28', 'SANG', 'Việc riêng', v_id);
  hrm_owner.pkg_hr.sp_them_nhan_vien('NV_TC23', 'Nhân viên thiếu công', date '1998-01-01', '079288888888', null,
    null, null, null, date '2026-01-26', 'KINH_DOANH', 'NHAN_VIEN', v_id);
  hrm_owner.pkg_att.sp_chot_cong(1, 2026, v_so, v_ds);
  dat('TC-23 Chot cong 01/2026 co loi: tra ' || v_so || ' dong loi', v_so = 6);
  dat('TC-23 Danh sach co dong THIEU_CONG cua NV_TC23', instr(v_ds, 'THIEU_CONG | NV_TC23 | 26/01/2026') > 0);
  dat('TC-23 Danh sach co dong DON_NGHI_CHO_DUYET cua NV005', instr(v_ds, 'DON_NGHI_CHO_DUYET | NV005') > 0);
  select max(trang_thai_ky) into v_txt from hrm_owner.vw_cong_thang where thang = 1 and nam = 2026;
  dat('TC-23 Co loi thi ky van MO (' || v_txt || ')', v_txt = 'MO');

  -- ---------------------------------------------------------------- TC-25
  begin
    hrm_owner.pkg_leave.sp_luu_han_muc_phep('NV_A', 2026, 12);
    dat('TC-25 Han muc trung nguoi/nam -> khong bi chan', false);
  exception when others then mong('TC-25 Han muc trung nguoi/nam bi tu choi', sqlcode, -20401);
  end;
  begin
    hrm_owner.pkg_leave.sp_luu_han_muc_phep('NV_B', 2026, 1, 0, null, true);
    dat('TC-25 Giam han muc duoi so da dung -> khong bi chan', false);
  exception when others then mong('TC-25 Giam han muc duoi so da dung (2 ngay) bi tu choi', sqlcode, -20402);
  end;

  rollback;
  dbms_output.put_line('      (da ROLLBACK moi thay doi thu)');
end;
/
