-- =============================================================================
-- TC-56 (bo sung v2.3, GD 7) - chay bang HRM_APP: kenh web khong lo du lieu
--   Cap SELECT tren view cho HRM_APP chi an toan neu MOI view tu loc theo
--   HRM_CTX. Kiem tra:
--   1. Chua co danh tinh: 14 view deu 0 dong; doc danh muc bi tu choi (-20003);
--      bang goc khong doc duoc (ORA-00942).
--   2. Danh tinh nhan vien NV_A: chi thay dong cua minh o VW-01; 0 dong o view
--      cua HR / Payroll / Admin; doc VAI_TRO bi tu choi (-20009).
--   3. Danh tinh Admin: thay VW-09, VW-13, VAI_TRO; khong thay ho so (TC-08).
--   4. Sau xoa_phien (tra ket noi ve pool): lai 0 dong o ca 14 view.
--   5. Tai khoan KHOA khong nhan duoc danh tinh (-20001); ten khong ton tai
--      tra toan NULL (khong lo ten nao co that).
-- Chay: scripts/run.sh HRM_APP tests/web/tc56_hrm_app.sql
-- =============================================================================
set feedback off
set linesize 250
declare
  type t_ds is table of varchar2(40);
  c_view constant t_ds := t_ds(
    'VW_HO_SO_NHAN_VIEN', 'VW_PHEP_CON_LAI', 'VW_CONG_THANG', 'VW_NHAN_SU_PHONG',
    'VW_DON_CHO_DUYET', 'VW_YEU_CAU_CUA_TOI', 'VW_TAI_KHOAN_QUAN_TRI', 'VW_NHAT_KY',
    'VW_BANG_LUONG_TONG_HOP', 'VW_PHIEU_LUONG_CA_NHAN', 'VW_HOP_DONG_SAP_HET_HAN',
    'VW_QUA_TRINH_CONG_TAC', 'VW_NGHI_PHEP_CHI_TIET', 'VW_DANH_BA_NHAN_VIEN');
  v_tk    number;
  v_hash  varchar2(255);
  v_tt    varchar2(20);
  v_n     number;
  v_khac  number;

  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;

  function dem(p_view varchar2) return number is
    v number;
  begin
    execute immediate 'select count(*) from hrm_owner.' || p_view into v;
    return v;
  end;

  -- Tong so dong cua ca 14 view (de kiem tra "khong thay gi")
  function tong_14 return number is
    v number := 0;
  begin
    for i in 1 .. c_view.count loop
      v := v + dem(c_view(i));
    end loop;
    return v;
  end;

  -- So dong danh muc tra ve; -SQLCODE neu bi tu choi (vd 20009)
  function dem_danh_muc(p_loai varchar2, p_nam number default null) return number is
    rc  sys_refcursor;
    cur integer;
    v   number := 0;
  begin
    hrm_owner.pkg_danh_muc.sp_tra_danh_muc(p_loai, rc, p_nam);
    cur := dbms_sql.to_cursor_number(rc);
    while dbms_sql.fetch_rows(cur) > 0 loop
      v := v + 1;
    end loop;
    dbms_sql.close_cursor(cur);
    return v;
  exception
    when others then return sqlcode;
  end;

  function id_tk(p_ten varchar2) return number is
  begin
    hrm_owner.pkg_auth.lay_thong_tin_xac_thuc(p_ten, v_tk, v_hash, v_tt);
    return v_tk;
  end;
begin
  -- 1. Chua co danh tinh -------------------------------------------------------
  hrm_owner.pkg_ctx.xoa_phien;
  dat('TC-56 Chua co danh tinh: tong so dong cua 14 view = ' || tong_14, tong_14 = 0);
  v_n := dem_danh_muc('PHONG_BAN');
  dat('TC-56 Chua co danh tinh: doc danh muc bi tu choi (' || v_n || ')', v_n = -20003);
  begin
    execute immediate 'select count(*) from hrm_owner.phong_ban' into v_n;
    dat('TC-56 HRM_APP doc duoc bang goc PHONG_BAN', false);
  exception when others then
    dat('TC-56 HRM_APP khong doc duoc bang goc (' || sqlcode || ')', sqlcode = -942);
  end;
  begin
    execute immediate 'delete from hrm_owner.vw_nhat_ky';
    dat('TC-56 HRM_APP xoa duoc qua view nhat ky', false);
  exception when others then
    dat('TC-56 HRM_APP khong ghi duoc qua view (' || sqlcode || ')', sqlcode in (-1031, -41900, -42399));
  end;
  rollback;

  -- 2. Nhan vien NV_A ----------------------------------------------------------
  hrm_owner.pkg_ctx.dat_phien(id_tk('nv_a'));
  execute immediate q'[select count(*), count(case when ma_nhan_vien <> 'NV_A' then 1 end)
                         from hrm_owner.vw_ho_so_nhan_vien]' into v_n, v_khac;
  dat('TC-56 NV_A: VW-01 ' || v_n || ' dong, ' || v_khac || ' dong cua nguoi khac', v_n = 1 and v_khac = 0);
  v_n := dem('VW_BANG_LUONG_TONG_HOP') + dem('VW_TAI_KHOAN_QUAN_TRI') + dem('VW_DANH_BA_NHAN_VIEN')
       + dem('VW_DON_CHO_DUYET') + dem('VW_HOP_DONG_SAP_HET_HAN') + dem('VW_NHAN_SU_PHONG')
       + dem('VW_NHAT_KY');
  dat('TC-56 NV_A: 0 dong o VW-04, 09, 13, 08, 06, 07, 10 (thay ' || v_n || ')', v_n = 0);
  execute immediate q'[select count(*) from hrm_owner.vw_qua_trinh_cong_tac
                        where ma_nhan_vien <> 'NV_A']' into v_n;
  dat('TC-56 NV_A: VW-12 khong co dong cua nguoi khac (' || v_n || ')', v_n = 0);
  v_n := dem_danh_muc('PHONG_BAN');
  dat('TC-56 NV_A: doc duoc danh muc phong ban (' || v_n || ' dong)', v_n > 0);
  v_n := dem_danh_muc('VAI_TRO');
  dat('TC-56 NV_A: doc danh muc VAI_TRO bi tu choi (' || v_n || ')', v_n = -20009);
  v_n := dem_danh_muc('KY_LUONG');
  dat('TC-56 NV_A: doc KY_LUONG bi tu choi (' || v_n || ')', v_n = -20009);

  -- 3. Admin ---------------------------------------------------------------------
  hrm_owner.pkg_ctx.dat_phien(id_tk('admin'));   -- dat_phien tu xoa danh tinh cu truoc
  v_n := dem('VW_TAI_KHOAN_QUAN_TRI');
  dat('TC-56 Admin: VW-09 co ' || v_n || ' tai khoan', v_n > 0);
  v_n := dem('VW_DANH_BA_NHAN_VIEN');
  dat('TC-56 Admin: VW-13 co ' || v_n || ' dong', v_n > 0);
  v_n := dem('VW_HO_SO_NHAN_VIEN') + dem('VW_BANG_LUONG_TONG_HOP');
  dat('TC-56 Admin: khong thay ho so, bang luong (TC-08) (' || v_n || ')', v_n = 0);
  v_n := dem_danh_muc('VAI_TRO');
  dat('TC-56 Admin: doc danh muc VAI_TRO (' || v_n || ' dong)', v_n > 0);
  v_n := dem_danh_muc('PHONG_BAN');
  dat('TC-56 Admin: doc PHONG_BAN bi tu choi theo ma tran 8.2 (' || v_n || ')', v_n = -20009);

  -- 4. Tra ket noi ve pool ---------------------------------------------------------
  hrm_owner.pkg_ctx.xoa_phien;
  dat('TC-56 Sau xoa_phien: tong so dong cua 14 view = ' || tong_14, tong_14 = 0);

  -- 5. Tai khoan khoa, ten khong ton tai --------------------------------------------
  v_tk := id_tk('nv_khoa');
  dat('TC-56 lay_thong_tin_xac_thuc tra trang thai KHOA cho nv_khoa', v_tt = 'KHOA');
  begin
    hrm_owner.pkg_ctx.dat_phien(v_tk);
    dat('TC-56 Tai khoan KHOA van nhan duoc danh tinh', false);
  exception when others then
    dat('TC-56 Tai khoan KHOA khong nhan duoc danh tinh (' || sqlcode || ')', sqlcode = -20001);
  end;
  dat('TC-56 Sau lan gan that bai: 14 view van 0 dong', tong_14 = 0);
  v_tk := id_tk('khong_ton_tai');
  dat('TC-56 Ten dang nhap khong ton tai: id, hash, trang thai deu NULL',
      v_tk is null and v_hash is null and v_tt is null);
end;
/
