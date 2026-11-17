-- =============================================================================
-- 02_pkg_ctx.sql - SP-28: gan va xoa danh tinh phien trong HRM_CTX (muc 8.1)
--
-- CREATE CONTEXT hrm_ctx USING hrm_owner.pkg_ctx => chi package nay goi duoc
-- DBMS_SESSION.SET_CONTEXT cho HRM_CTX. Nguoi dung goi truc tiep se nhan ORA-01031.
--
-- Hai kenh vao, cung mot cach nap danh tinh:
--   Kenh 1 (web)    : HRM_APP goi dat_phien(tai_khoan_id) dau moi request,
--                     xoa_phien trong khoi finally truoc khi tra ket noi ve pool.
--   Kenh 2 (DBeaver): TR-05 goi dat_phien_dang_nhap khi user demo dang nhap.
-- Moi lan gan deu doc lai TRANG_THAI va vai tro tu bang: tai khoan KHOA khong
-- nhan duoc danh tinh, nen view tra 0 dong va procedure tu choi (BR-04).
--
-- Thuoc tinh trong HRM_CTX:
--   TAI_KHOAN_ID, NHAN_VIEN_ID, TEN_DANG_NHAP,
--   VAI_TRO (dang ',EMPLOYEE,HR,'), KENH (WEB | DBEAVER)
-- Ma loi: -20001 tai khoan khong hop le/khoa; -20002 sai kenh goi.
-- =============================================================================

create or replace package pkg_ctx
  authid definer
as
  -- Kenh 1: chi HRM_APP; backend da xac thuc mat khau va token truoc khi goi
  procedure dat_phien(p_tai_khoan_id in number);

  -- Kenh 2: chi TR-05 goi; tim tai khoan co ORACLE_USERNAME = SESSION_USER
  procedure dat_phien_dang_nhap;

  -- Xoa toan bo danh tinh cua phien hien tai
  procedure xoa_phien;
end pkg_ctx;
/
show errors

create or replace package body pkg_ctx
as
  c_ctx constant varchar2(30) := 'HRM_CTX';

  -- Nap danh tinh cua mot tai khoan da kiem tra la HOAT_DONG
  procedure nap(p_tk in tai_khoan%rowtype, p_kenh in varchar2)
  is
    v_vai_tro varchar2(400);
  begin
    select ',' || listagg(r.ma_vai_tro, ',') within group (order by r.ma_vai_tro) || ','
      into v_vai_tro
      from tai_khoan_vai_tro tv
      join vai_tro r on r.vai_tro_id = tv.vai_tro_id
     where tv.tai_khoan_id = p_tk.tai_khoan_id;

    dbms_session.set_context(c_ctx, 'TAI_KHOAN_ID',  p_tk.tai_khoan_id);
    dbms_session.set_context(c_ctx, 'NHAN_VIEN_ID',  p_tk.nhan_vien_id);
    dbms_session.set_context(c_ctx, 'TEN_DANG_NHAP', p_tk.ten_dang_nhap);
    dbms_session.set_context(c_ctx, 'VAI_TRO',       v_vai_tro);
    dbms_session.set_context(c_ctx, 'KENH',          p_kenh);
  end nap;

  procedure xoa_phien
  is
  begin
    dbms_session.clear_all_context(c_ctx);
  end xoa_phien;

  procedure dat_phien(p_tai_khoan_id in number)
  is
    v_tk tai_khoan%rowtype;
  begin
    xoa_phien;   -- khong de danh tinh cu sot lai du gan that bai

    if sys_context('USERENV', 'SESSION_USER') <> 'HRM_APP' then
      raise_application_error(-20002, 'Chỉ ứng dụng (HRM_APP) được gán phiên theo tài khoản.');
    end if;

    begin
      select * into v_tk from tai_khoan where tai_khoan_id = p_tai_khoan_id;
    exception
      when no_data_found then
        raise_application_error(-20001, 'Tài khoản không hợp lệ hoặc đã bị khóa.');
    end;

    if v_tk.trang_thai <> 'HOAT_DONG' then
      raise_application_error(-20001, 'Tài khoản không hợp lệ hoặc đã bị khóa.');
    end if;

    nap(v_tk, 'WEB');
  end dat_phien;

  procedure dat_phien_dang_nhap
  is
    v_tk tai_khoan%rowtype;
  begin
    xoa_phien;
    select * into v_tk
      from tai_khoan
     where oracle_username = sys_context('USERENV', 'SESSION_USER');

    if v_tk.trang_thai = 'HOAT_DONG' then
      nap(v_tk, 'DBEAVER');
    end if;
  exception
    when no_data_found then
      null;   -- user Oracle khong anh xa tai khoan nghiep vu: khong co danh tinh
  end dat_phien_dang_nhap;
end pkg_ctx;
/
show errors
