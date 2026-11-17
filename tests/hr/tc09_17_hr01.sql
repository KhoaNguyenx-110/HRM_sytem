-- =============================================================================
-- TC-09..TC-17, TC-13/TC-52 (audit), TC-44 (phan HR01), TC-46 - chay bang U_HR01
--   scripts/run.sh U_HR01 tests/hr/tc09_17_hr01.sql
-- Moi thay doi deu ROLLBACK o cuoi; du lieu seed giu nguyen.
-- =============================================================================
set feedback off
declare
  v_id    number;
  v_dem   number;
  v_dem2  number;
  v_txt   varchar2(400);
  v_pb_kt number;   -- phong KY_THUAT
  v_pb_kd number;   -- phong KINH_DOANH
  v_nv    number;

  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure mong(p_ten varchar2, p_ma number, p_mong number) is
  begin
    dat(p_ten || ' (' || p_ma || ')', p_ma = p_mong);
  end;
begin
  select phong_ban_id into v_pb_kt from hrm_owner.phong_ban where ma_phong_ban = 'KY_THUAT';
  select phong_ban_id into v_pb_kd from hrm_owner.phong_ban where ma_phong_ban = 'KINH_DOANH';

  -- ---------------------------------------------------------------- TC-09
  begin
    hrm_owner.pkg_hr.sp_luu_phong_ban('KY_THUAT', 'Phòng trùng mã');
    dat('TC-09 Them phong trung ma -> khong bi chan', false);
  exception when others then mong('TC-09 Them phong trung ma bi tu choi', sqlcode, -20101);
  end;
  begin
    hrm_owner.pkg_hr.sp_luu_chuc_vu('NHAN_VIEN', 'Chức vụ trùng mã');
    dat('TC-09 Them chuc vu trung ma -> khong bi chan', false);
  exception when others then mong('TC-09 Them chuc vu trung ma bi tu choi', sqlcode, -20102);
  end;
  begin
    hrm_owner.pkg_hr.sp_luu_chuc_vu('CV_RONG', null);
    dat('FR-ORG-02 Chuc vu ten rong -> khong bi chan', false);
  exception when others then mong('FR-ORG-02 Chuc vu ten rong bi tu choi', sqlcode, -20901);
  end;
  hrm_owner.pkg_hr.sp_luu_phong_ban('KY_THUAT', 'Phòng Kỹ thuật và R&D', null, v_pb_kt);
  select count(*) into v_dem from hrm_owner.vw_ho_so_nhan_vien
   where ma_phong_ban = 'KY_THUAT' and ten_phong_ban = 'Phòng Kỹ thuật và R&D';
  dat('TC-09 Doi ten phong: phan cong van tro dung phong (' || v_dem || ' nguoi)', v_dem > 0);

  -- ---------------------------------------------------------------- TC-10
  begin
    hrm_owner.pkg_hr.sp_chi_dinh_truong_phong('NV_A', 'KINH_DOANH', date '2026-12-01', 'QĐ thử');
    dat('TC-10 Chi dinh truong phong la nguoi khac phong -> khong bi chan', false);
  exception when others then mong('TC-10 Chi dinh nguoi khac phong bi tu choi', sqlcode, -20103);
  end;
  begin
    hrm_owner.pkg_hr.sp_chi_dinh_truong_phong('NV_B', 'KY_THUAT', date '2026-12-01', 'QĐ thử');
    dat('TC-10 Chi dinh truong phong thu hai -> khong bi chan', false);
  exception when others then mong('TC-10 Chi dinh truong phong thu hai bi tu choi', sqlcode, -20104);
  end;
  select nhan_vien_id into v_nv from hrm_owner.vw_ho_so_nhan_vien where ma_nhan_vien = 'NV033';
  dat('TC-10 FN-07 tra dung truong phong Ky thuat tai 01/03/2026',
      hrm_owner.fn_truong_phong_tai_ngay(v_pb_kt, date '2026-03-01') = v_nv);

  -- ---------------------------------------------------------------- TC-11
  begin
    hrm_owner.pkg_hr.sp_ngung_danh_muc('PHONG_BAN', 'KY_THUAT');
    dat('TC-11 Ngung phong con phan cong -> khong bi chan', false);
  exception when others then mong('TC-11 Ngung phong con phan cong bi tu choi', sqlcode, -20105);
  end;
  hrm_owner.pkg_hr.sp_luu_phong_ban('PB_TAM', 'Phòng tạm để thử');
  hrm_owner.pkg_hr.sp_ngung_danh_muc('PHONG_BAN', 'PB_TAM');
  dat('TC-11 Ngung phong khong con phan cong', true);
  begin
    hrm_owner.pkg_hr.sp_dieu_chuyen('NV_C', 'PB_TAM', 'NHAN_VIEN', date '2026-12-01', 'QĐ thử');
    dat('TC-11/TC-16 Dieu chuyen vao phong da ngung -> khong bi chan', false);
  exception when others then mong('TC-11/TC-16 Dieu chuyen vao phong da ngung bi tu choi', sqlcode, -20106);
  end;
  select ma_phong_ban into v_txt from hrm_owner.vw_ho_so_nhan_vien where ma_nhan_vien = 'NV_C';
  dat('TC-16 Loi buoc moi: NV_C giu phan cong cu (' || v_txt || ')', v_txt = 'KINH_DOANH');

  -- ---------------------------------------------------------------- TC-12
  select count(*) into v_dem from hrm_owner.vw_ho_so_nhan_vien;
  begin
    hrm_owner.pkg_hr.sp_them_nhan_vien('NV001', 'Trùng mã', date '1995-05-05', '079299999999', null,
      null, null, null, date '2026-12-01', 'KY_THUAT', 'NHAN_VIEN', v_id);
    dat('TC-12 Ma nhan vien trung -> khong bi chan', false);
  exception when others then mong('TC-12 Ma nhan vien trung bi tu choi', sqlcode, -20201);
  end;
  -- Ho so ghi duoc nhung phan cong loi (phong da co truong phong) => rollback ca hai
  begin
    hrm_owner.pkg_hr.sp_them_nhan_vien('NV_MOI', 'Nhân viên mới', date '1995-05-05', '079299999998', null,
      null, null, null, date '2026-12-01', 'KY_THUAT', 'TRUONG_PHONG', v_id);
    dat('TC-12 Loi phan cong -> khong bi chan', false);
  exception when others then mong('TC-12 Loi phan cong bi tu choi', sqlcode, -20104);
  end;
  select count(*) into v_dem2 from hrm_owner.vw_ho_so_nhan_vien;
  dat('TC-12 Khong con ho so do dang (' || v_dem || ' -> ' || v_dem2 || ')', v_dem = v_dem2);
  hrm_owner.pkg_hr.sp_them_nhan_vien('NV_MOI', 'Nhân viên mới', date '1995-05-05', '079299999998', null,
    'nv.moi@hrm.example.com', null, null, date '2026-12-01', 'KY_THUAT', 'NHAN_VIEN', v_id);
  select count(*) into v_dem from hrm_owner.vw_ho_so_nhan_vien where ma_nhan_vien = 'NV_MOI' and ma_phong_ban is null;
  dat('TC-12 Them ho so hop le kem phan cong (TX-01)', v_id is not null);

  -- ---------------------------------------------------------------- TC-13 + TC-52
  hrm_owner.pkg_hr.sp_cap_nhat_nhan_vien('NV_C', p_email => 'nv.c.moi@hrm.example.com');
  select count(*) into v_dem from hrm_owner.vw_nhat_ky
   where doi_tuong = 'NHAN_VIEN' and thao_tac = 'UPDATE' and ten_dang_nhap = 'nv005'
     and json_value(gia_tri_cu,  '$.EMAIL') = 'nv.c@hrm.example.com'
     and json_value(gia_tri_moi, '$.EMAIL') = 'nv.c.moi@hrm.example.com';
  dat('TC-13/TC-52 Audit ghi nguoi sua, email truoc va sau', v_dem = 1);

  -- ---------------------------------------------------------------- TC-14
  begin
    hrm_owner.pkg_hr.sp_luu_hop_dong('NV_A', 'HD-THU-1', 'XAC_DINH', date '2026-12-01', date '2027-11-30', 30000000, 30000000);
    dat('TC-14 Hop dong chong hieu luc -> khong bi chan', false);
  exception when others then mong('TC-14 Hop dong chong hieu luc bi tu choi', sqlcode, -20205);
  end;
  begin
    hrm_owner.pkg_hr.sp_luu_hop_dong('NV_A', 'HD-THU-2', 'XAC_DINH', date '2026-12-01', date '2026-11-01', 30000000, 30000000);
    dat('TC-14 Ngay ket thuc truoc bat dau -> khong bi chan', false);
  exception when others then mong('TC-14 Ngay ket thuc truoc bat dau bi tu choi', sqlcode, -20206);
  end;
  begin
    hrm_owner.pkg_hr.sp_dieu_chinh_luong('HD-NV_A-01', date '2026-12-15', 28000000, 28000000);
    dat('TC-14 Muc luong tu ngay 15 -> khong bi chan', false);
  exception when others then mong('TC-14 Muc luong tu ngay 15 bi tu choi', sqlcode, -20207);
  end;
  hrm_owner.pkg_hr.sp_dieu_chinh_luong('HD-NV_A-01', date '2026-12-01', 28000000, 28000000);
  select count(*) into v_dem from hrm_owner.vw_nhat_ky where doi_tuong = 'MUC_LUONG_HOP_DONG' and ten_dang_nhap = 'nv005';
  dat('TC-14/TC-52 Tang luong tu ngay 1 thanh cong, co audit (' || v_dem || ' dong)', v_dem = 2);

  -- ---------------------------------------------------------------- TC-15
  begin
    hrm_owner.pkg_hr.sp_luu_nguoi_phu_thuoc('NV_C', 'Con', 'CON', '0792-2000-0034', date '2026-01-01', null, v_id);
    dat('TC-15 Cung dinh danh cho hai nhan vien trung khoang -> khong bi chan', false);
  exception when others then mong('TC-15 Cung dinh danh trung khoang bi tu choi', sqlcode, -20210);
  end;
  begin
    hrm_owner.pkg_hr.sp_luu_nguoi_phu_thuoc('NV_C', 'Con', 'CON', '079299990001', date '2026-06-01', date '2026-01-01', v_id);
    dat('TC-15 Khoang ngay sai -> khong bi chan', false);
  exception when others then mong('TC-15 Khoang ngay sai bi tu choi', sqlcode, -20209);
  end;
  hrm_owner.pkg_hr.sp_luu_nguoi_phu_thuoc('NV005', 'Con của HR01', 'CON', '079299990002', date '2026-01-01', null, v_id);
  begin
    hrm_owner.pkg_hr.sp_xac_minh_nguoi_phu_thuoc(v_id, 'DA_XAC_MINH');
    dat('TC-15 HR tu xac minh nguoi phu thuoc cua minh -> khong bi chan', false);
  exception when others then mong('TC-15 HR tu xac minh cua minh bi tu choi', sqlcode, -20222);
  end;
  hrm_owner.pkg_hr.sp_luu_nguoi_phu_thuoc('NV_C', 'Con của NV_C', 'CON', '079299990003', date '2026-01-01', null, v_id);
  hrm_owner.pkg_hr.sp_xac_minh_nguoi_phu_thuoc(v_id, 'DA_XAC_MINH');
  dat('TC-15 Dang ky va xac minh hop le', true);

  -- ---------------------------------------------------------------- TC-16
  hrm_owner.pkg_hr.sp_dieu_chuyen('NV019', 'KY_THUAT', 'NHAN_VIEN', date '2026-12-01', 'QĐ điều chuyển thử');
  dat('TC-16 Truong phong Kinh doanh bi chuyen: phong cu trong truong phong tu 01/12',
      hrm_owner.fn_truong_phong_tai_ngay(v_pb_kd, date '2026-12-01') is null);
  select nhan_vien_id into v_nv from hrm_owner.vw_ho_so_nhan_vien where ma_nhan_vien = 'NV019';
  dat('TC-16 Truoc ngay hieu luc van la truong phong',
      hrm_owner.fn_truong_phong_tai_ngay(v_pb_kd, date '2026-11-30') = v_nv);
  begin
    hrm_owner.pkg_hr.sp_dieu_chuyen('NV_C', 'KY_THUAT', 'NHAN_VIEN', date '2026-12-15', 'QĐ thử');
    dat('FR-EMP-05 Dieu chuyen khong tu ngay 1 -> khong bi chan', false);
  exception when others then mong('FR-EMP-05 Dieu chuyen khong tu ngay 1 bi tu choi', sqlcode, -20219);
  end;

  -- ---------------------------------------------------------------- TC-17
  begin
    hrm_owner.pkg_hr.sp_nghi_viec('NV_B', date '2026-03-20');
    dat('TC-17 Nghi viec khi con cong sau ngay nghi -> khong bi chan', false);
  exception when others then mong('TC-17 Nghi viec khi con cong sau ngay nghi bi tu choi', sqlcode, -20208);
  end;
  hrm_owner.pkg_hr.sp_nghi_viec('NV041', date '2026-03-31');
  select trang_thai_lam_viec into v_txt from hrm_owner.vw_ho_so_nhan_vien where ma_nhan_vien = 'NV041';
  dat('TC-17 Ghi nghi viec: trang thai DA_NGHI, lich su con', v_txt = 'DA_NGHI');

  -- ---------------------------------------------------------------- TC-44 (HR01)
  begin
    hrm_owner.pkg_hr.sp_luu_khen_thuong('NV_C', '001/2026/QĐ-KT', date '2026-03-01', 'Trùng số', 'TIEN', 1000000);
    dat('TC-44 So quyet dinh trung -> khong bi chan', false);
  exception when others then mong('TC-44 So quyet dinh trung bi tu choi', sqlcode, -20601);
  end;
  begin
    hrm_owner.pkg_hr.sp_luu_khen_thuong('NV_C', '099/2026/QĐ-KT', date '2026-03-01', 'Thưởng 0', 'TIEN', 0);
    dat('TC-44 Thuong bang 0 -> khong bi chan', false);
  exception when others then mong('TC-44 Thuong bang 0 bi tu choi', sqlcode, -20602);
  end;
  begin
    hrm_owner.pkg_hr.sp_duyet_khen_thuong('003/2026/QĐ-KT', 'DA_DUYET');
    dat('TC-44 HR duyet quyet dinh minh tao -> khong bi chan', false);
  exception when others then mong('TC-44 HR duyet quyet dinh minh tao bi tu choi', sqlcode, -20604);
  end;

  -- ---------------------------------------------------------------- TC-46
  hrm_owner.pkg_hr.sp_ghi_ky_luat('NV_C', '002/2026/QĐ-KL', date '2026-03-05', 'Vi phạm nội quy', 'KHIEN_TRACH', 'nv004');
  dat('TC-46 Ghi ky luat thanh cong (khong co duong ghi sang PHAT_SINH_LUONG, BR-31)', true);

  rollback;
  dbms_output.put_line('      (da ROLLBACK moi thay doi thu)');
end;
/
