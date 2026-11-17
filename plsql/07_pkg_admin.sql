-- =============================================================================
-- 07_pkg_admin.sql - Quan tri tai khoan (SP-13, SP-14; FR-AUTH-02..04)
-- Vai tro: ADMIN. Admin khong duyet nghiep vu, khong xem luong (muc 2.3).
--
-- SP-13 sp_quan_ly_tai_khoan duoc tach thanh cac thu tuc ro nghia:
--   sp_tao_tai_khoan, sp_khoa_tai_khoan, sp_mo_tai_khoan, sp_anh_xa_oracle
-- SP-14 sp_gan_vai_tro: sp_gan_vai_tro, sp_thu_hoi_vai_tro
--
-- Tach biet nhiem vu: Admin khong tu gan / thu hoi vai tro cho chinh minh va
-- khong tu khoa minh (neu khong, Admin tu cap PAYROLL de xem luong).
-- Thay doi vai tro co hieu luc tu phien moi (pkg_ctx nap vai tro luc dang nhap);
-- TR-01 ghi audit TAI_KHOAN, TAI_KHOAN_VAI_TRO.
-- Vai tro Oracle R_* cua user demo dong bo bang security/20_demo_users.sql.
--
-- Ma loi: -20010..-20017 (xem pkg_chung.dich_loi), -20013 khong co vai tro de
-- thu hoi, -20014 tu thao tac tren chinh minh, -20018 tai khoan khong ton tai,
-- -20019 nhan vien khong ton tai.
-- Khong COMMIT: noi goi ket thuc transaction.
-- =============================================================================

create or replace package pkg_admin
  authid definer
as
  procedure sp_tao_tai_khoan(
    p_ten_dang_nhap   in  varchar2,
    p_mat_khau_bam    in  varchar2,
    p_ma_nhan_vien    in  varchar2 default null,   -- NULL: tai khoan ky thuat
    p_oracle_username in  varchar2 default null,
    o_tai_khoan_id    out number);

  procedure sp_khoa_tai_khoan(p_ten_dang_nhap in varchar2);
  procedure sp_mo_tai_khoan(p_ten_dang_nhap in varchar2);
  procedure sp_anh_xa_oracle(p_ten_dang_nhap in varchar2, p_oracle_username in varchar2);

  procedure sp_gan_vai_tro(p_ten_dang_nhap in varchar2, p_ma_vai_tro in varchar2);
  procedure sp_thu_hoi_vai_tro(p_ten_dang_nhap in varchar2, p_ma_vai_tro in varchar2);
end pkg_admin;
/
show errors

create or replace package body pkg_admin
as
  -- Khoa dong tai khoan theo ten (khong phan biet hoa/thuong); khong tim thay -> -20018
  function khoa_tai_khoan(p_ten in varchar2) return tai_khoan%rowtype
  is
    v tai_khoan%rowtype;
  begin
    select * into v from tai_khoan
     where upper(ten_dang_nhap) = upper(trim(p_ten))
       for update;
    return v;
  exception
    when no_data_found then
      raise_application_error(-20018, 'Tài khoản "' || p_ten || '" không tồn tại.');
  end khoa_tai_khoan;

  procedure khong_phai_chinh_minh(p_tai_khoan_id in number)
  is
  begin
    if p_tai_khoan_id = pkg_chung.tai_khoan then
      raise_application_error(-20014, 'Không được tự thao tác trên tài khoản của chính mình.');
    end if;
  end khong_phai_chinh_minh;

  procedure sp_tao_tai_khoan(
    p_ten_dang_nhap   in  varchar2,
    p_mat_khau_bam    in  varchar2,
    p_ma_nhan_vien    in  varchar2 default null,
    p_oracle_username in  varchar2 default null,
    o_tai_khoan_id    out number)
  is
    v_nv number;
  begin
    savepoint sp_tao_tk;
    pkg_chung.yeu_cau_vai_tro('ADMIN');

    if p_ma_nhan_vien is not null then
      begin
        select nhan_vien_id into v_nv from nhan_vien where ma_nhan_vien = p_ma_nhan_vien;
      exception
        when no_data_found then
          raise_application_error(-20019, 'Nhân viên "' || p_ma_nhan_vien || '" không tồn tại.');
      end;
    end if;

    -- IX-02 chan trung ten khong phan biet hoa/thuong; UK_TAI_KHOAN_NV chan tai khoan thu hai
    insert into tai_khoan (ten_dang_nhap, mat_khau_bam, nhan_vien_id, oracle_username)
    values (trim(p_ten_dang_nhap), p_mat_khau_bam, v_nv, upper(p_oracle_username))
    returning tai_khoan_id into o_tai_khoan_id;

    -- Tai khoan cua nhan vien mac dinh co vai tro EMPLOYEE
    if v_nv is not null then
      insert into tai_khoan_vai_tro (tai_khoan_id, vai_tro_id, nguoi_gan)
      select o_tai_khoan_id, vai_tro_id, pkg_chung.tai_khoan from vai_tro where ma_vai_tro = 'EMPLOYEE';
    end if;
  exception
    when others then
      rollback to sp_tao_tk;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_tao_tai_khoan;

  procedure sp_khoa_tai_khoan(p_ten_dang_nhap in varchar2)
  is
    v tai_khoan%rowtype;
  begin
    pkg_chung.yeu_cau_vai_tro('ADMIN');
    v := khoa_tai_khoan(p_ten_dang_nhap);
    khong_phai_chinh_minh(v.tai_khoan_id);
    update tai_khoan set trang_thai = 'KHOA' where tai_khoan_id = v.tai_khoan_id;
  end sp_khoa_tai_khoan;

  procedure sp_mo_tai_khoan(p_ten_dang_nhap in varchar2)
  is
    v tai_khoan%rowtype;
    v_nghi date;
  begin
    pkg_chung.yeu_cau_vai_tro('ADMIN');
    v := khoa_tai_khoan(p_ten_dang_nhap);
    if v.nhan_vien_id is not null then
      select ngay_nghi_viec into v_nghi from nhan_vien where nhan_vien_id = v.nhan_vien_id;
      if v_nghi is not null and v_nghi < trunc(sysdate) then
        raise_application_error(-20015, 'Không mở tài khoản của nhân viên đã nghỉ việc.');
      end if;
    end if;
    update tai_khoan
       set trang_thai = 'HOAT_DONG', so_lan_dang_nhap_sai = 0
     where tai_khoan_id = v.tai_khoan_id;
  end sp_mo_tai_khoan;

  procedure sp_anh_xa_oracle(p_ten_dang_nhap in varchar2, p_oracle_username in varchar2)
  is
    v tai_khoan%rowtype;
  begin
    savepoint sp_anh_xa;
    pkg_chung.yeu_cau_vai_tro('ADMIN');
    v := khoa_tai_khoan(p_ten_dang_nhap);
    update tai_khoan set oracle_username = upper(p_oracle_username) where tai_khoan_id = v.tai_khoan_id;
  exception
    when others then
      rollback to sp_anh_xa;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_anh_xa_oracle;

  procedure sp_gan_vai_tro(p_ten_dang_nhap in varchar2, p_ma_vai_tro in varchar2)
  is
    v    tai_khoan%rowtype;
    v_vt number;
  begin
    savepoint sp_gan_vt;
    pkg_chung.yeu_cau_vai_tro('ADMIN');
    v := khoa_tai_khoan(p_ten_dang_nhap);
    khong_phai_chinh_minh(v.tai_khoan_id);
    begin
      select vai_tro_id into v_vt from vai_tro where ma_vai_tro = upper(p_ma_vai_tro);
    exception
      when no_data_found then
        raise_application_error(-20020, 'Vai trò "' || p_ma_vai_tro || '" không tồn tại.');
    end;
    -- PK ghep chan gan trung (BR-03)
    insert into tai_khoan_vai_tro (tai_khoan_id, vai_tro_id, nguoi_gan)
    values (v.tai_khoan_id, v_vt, pkg_chung.tai_khoan);
  exception
    when others then
      rollback to sp_gan_vt;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_gan_vai_tro;

  procedure sp_thu_hoi_vai_tro(p_ten_dang_nhap in varchar2, p_ma_vai_tro in varchar2)
  is
    v tai_khoan%rowtype;
  begin
    pkg_chung.yeu_cau_vai_tro('ADMIN');
    v := khoa_tai_khoan(p_ten_dang_nhap);
    khong_phai_chinh_minh(v.tai_khoan_id);
    delete from tai_khoan_vai_tro
     where tai_khoan_id = v.tai_khoan_id
       and vai_tro_id = (select vai_tro_id from vai_tro where ma_vai_tro = upper(p_ma_vai_tro));
    if sql%rowcount = 0 then
      raise_application_error(-20013, 'Tài khoản không có vai trò "' || p_ma_vai_tro || '" để thu hồi.');
    end if;
  end sp_thu_hoi_vai_tro;
end pkg_admin;
/
show errors
