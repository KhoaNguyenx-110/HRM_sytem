-- =============================================================================
-- 03_pkg_auth.sql - SP-27: dang nhap va doi mat khau (dac ta muc 8.1, AUTH-01, AUTH-05)
--
-- CSDL khong bao gio thay mat khau ro. Backend:
--   1. goi lay_thong_tin_xac_thuc(ten) lay hash + trang thai;
--   2. kiem tra mat khau bang bcrypt/Argon2 (NFR-04);
--   3. sai -> ghi_that_bai(ten) (autonomous; du 5 lan lien tiep thi KHOA);
--      dung -> ghi_thanh_cong(tai_khoan_id) de dat lai bo dem, roi cap token.
--
-- lay_thong_tin_xac_thuc, ghi_that_bai, ghi_thanh_cong chi HRM_APP goi duoc:
-- R_EMPLOYEE co EXECUTE tren package (de doi mat khau) nhung khong doc duoc hash
-- hay khoa tai khoan nguoi khac.
--
-- Ma loi: -20002 sai kenh goi; -20003 chua co danh tinh phien;
--         -20004 mat khau hien tai khong khop; -20005 mat khau moi trung cu;
--         -20006 mat khau moi khong phai chuoi bam hop le.
-- Bo sung so voi dac ta: ghi_thanh_cong (can de dem "5 lan LIEN TIEP").
-- =============================================================================

create or replace package pkg_auth
  authid definer
as
  c_so_lan_sai_toi_da constant pls_integer := 5;

  -- Khong tim thay ten dang nhap: ca ba OUT deu NULL (khong lo ten nao ton tai)
  procedure lay_thong_tin_xac_thuc(
    p_ten_dang_nhap in  varchar2,
    o_tai_khoan_id  out number,
    o_mat_khau_bam  out varchar2,
    o_trang_thai    out varchar2);

  -- Autonomous transaction: tu COMMIT, khong anh huong transaction cua request
  procedure ghi_that_bai(p_ten_dang_nhap in varchar2);

  procedure ghi_thanh_cong(p_tai_khoan_id in number);

  -- p_mat_khau_bam_cu: hash backend doc duoc o buoc dang nhap va da doi chieu voi
  -- mat khau cu nguoi dung nhap; CSDL kiem tra hash nay con khop gia tri hien tai.
  procedure sp_doi_mat_khau(
    p_mat_khau_bam_cu  in varchar2,
    p_mat_khau_bam_moi in varchar2);
end pkg_auth;
/
show errors

create or replace package body pkg_auth
as
  procedure chi_ung_dung
  is
  begin
    if sys_context('USERENV', 'SESSION_USER') <> 'HRM_APP' then
      raise_application_error(-20002, 'Chỉ ứng dụng (HRM_APP) được gọi chức năng xác thực này.');
    end if;
  end chi_ung_dung;

  procedure lay_thong_tin_xac_thuc(
    p_ten_dang_nhap in  varchar2,
    o_tai_khoan_id  out number,
    o_mat_khau_bam  out varchar2,
    o_trang_thai    out varchar2)
  is
  begin
    chi_ung_dung;
    select tai_khoan_id, mat_khau_bam, trang_thai
      into o_tai_khoan_id, o_mat_khau_bam, o_trang_thai
      from tai_khoan
     where upper(ten_dang_nhap) = upper(trim(p_ten_dang_nhap));   -- dung IX-02
  exception
    when no_data_found then
      o_tai_khoan_id := null;
      o_mat_khau_bam := null;
      o_trang_thai   := null;
  end lay_thong_tin_xac_thuc;

  procedure ghi_that_bai(p_ten_dang_nhap in varchar2)
  is
    pragma autonomous_transaction;
  begin
    chi_ung_dung;
    update tai_khoan
       set so_lan_dang_nhap_sai = so_lan_dang_nhap_sai + 1,
           trang_thai = case when so_lan_dang_nhap_sai + 1 >= c_so_lan_sai_toi_da
                             then 'KHOA' else trang_thai end
     where upper(ten_dang_nhap) = upper(trim(p_ten_dang_nhap))
       and trang_thai = 'HOAT_DONG';
    commit;
  exception
    when others then
      rollback;
      raise;
  end ghi_that_bai;

  procedure ghi_thanh_cong(p_tai_khoan_id in number)
  is
  begin
    chi_ung_dung;
    update tai_khoan
       set so_lan_dang_nhap_sai = 0
     where tai_khoan_id = p_tai_khoan_id
       and so_lan_dang_nhap_sai <> 0;
  end ghi_thanh_cong;

  procedure sp_doi_mat_khau(
    p_mat_khau_bam_cu  in varchar2,
    p_mat_khau_bam_moi in varchar2)
  is
    v_tk          number := fn_tai_khoan_hien_tai;
    v_hien_tai    tai_khoan.mat_khau_bam%type;
    e_check       exception;
    pragma exception_init(e_check, -2290);
  begin
    if v_tk is null then
      raise_application_error(-20003, 'Chưa có danh tính phiên hoặc tài khoản đã bị khóa.');
    end if;

    -- Khoa dong tai khoan de hai lan doi mat khau dong thoi khong ghi de nhau
    select mat_khau_bam into v_hien_tai
      from tai_khoan where tai_khoan_id = v_tk
       for update;

    if p_mat_khau_bam_cu is null or p_mat_khau_bam_cu <> v_hien_tai then
      raise_application_error(-20004, 'Mật khẩu hiện tại không đúng.');
    end if;
    if p_mat_khau_bam_moi = v_hien_tai then
      raise_application_error(-20005, 'Mật khẩu mới phải khác mật khẩu hiện tại.');
    end if;

    update tai_khoan set mat_khau_bam = p_mat_khau_bam_moi where tai_khoan_id = v_tk;
  exception
    when e_check then   -- CK_TAI_KHOAN_MAT_KHAU: chan luu mat khau ro (NFR-04)
      raise_application_error(-20006, 'Mật khẩu mới phải là chuỗi băm bcrypt hoặc Argon2.');
  end sp_doi_mat_khau;
end pkg_auth;
/
show errors
