-- =============================================================================
-- 08_pkg_hr.sql - Nghiep vu nhan su (vai tro HR)
--   To chuc   : SP-25 sp_luu_phong_ban, sp_luu_chuc_vu, sp_ngung_danh_muc (FR-ORG-01,02,04)
--   Ho so     : SP-01 sp_them_nhan_vien, SP-24 sp_cap_nhat_nhan_vien     (FR-EMP-01,02)
--   Hop dong  : SP-02 sp_luu_hop_dong, sp_dieu_chinh_luong              (FR-EMP-03)
--   Cong tac  : SP-03 sp_dieu_chuyen, sp_chi_dinh_truong_phong          (FR-EMP-05, FR-ORG-03)
--   Nghi viec : SP-18 sp_nghi_viec                                      (FR-EMP-06)
--   Phu thuoc : SP-23 sp_luu_nguoi_phu_thuoc, sp_xac_minh_nguoi_phu_thuoc (FR-EMP-04)
--   Quyet dinh: SP-19 sp_luu_khen_thuong, sp_duyet_khen_thuong; SP-20 sp_ghi_ky_luat
--
-- Quy uoc chung:
--   * Moi thu tuc dat SAVEPOINT dau tien; loi thi ROLLBACK TO roi doi sang loi
--     nghiep vu (pkg_chung.dich_loi). Khong COMMIT: noi goi ket thuc transaction.
--   * Thu tu khoa dong (muc 8.5): KY_LUONG -> PHONG_BAN (ID tang dan) -> NHAN_VIEN.
--     KY_LUONG duoc khoa ben trong pkg_payroll.danh_dau_tinh_lai.
--   * Moi duong ghi dau vao luong goi danh_dau_tinh_lai trong cung transaction (BR-38).
--   * Truong phong suy ra tu phan cong co chuc vu LA_QUAN_LY (FN-07); vai tro
--     MANAGER cua tai khoan duoc dong bo theo phan cong (TX-03).
-- =============================================================================

create or replace package pkg_hr
  authid definer
as
  -- To chuc ------------------------------------------------------------------
  -- p_..._id NULL: them moi (ma trung -> -20101/-20102); co ID: sua ban ghi do.
  -- Doi ten/ma khong doi ID nen phan cong va phieu luong cu van tro dung (TC-09).
  procedure sp_luu_phong_ban(
    p_ma           in varchar2,
    p_ten          in varchar2,
    p_mo_ta        in varchar2 default null,
    p_phong_ban_id in number   default null);
  procedure sp_luu_chuc_vu(
    p_ma         in varchar2,
    p_ten        in varchar2,
    p_la_quan_ly in boolean default false,
    p_chuc_vu_id in number  default null);
  -- p_loai: PHONG_BAN | CHUC_VU
  procedure sp_ngung_danh_muc(p_loai in varchar2, p_ma in varchar2);

  -- Ho so ---------------------------------------------------------------------
  procedure sp_them_nhan_vien(
    p_ma_nhan_vien  in  varchar2,
    p_ho_ten        in  varchar2,
    p_ngay_sinh     in  date,
    p_so_dinh_danh  in  varchar2,
    p_ma_so_thue    in  varchar2,
    p_email         in  varchar2,
    p_so_dien_thoai in  varchar2,
    p_dia_chi       in  varchar2,
    p_ngay_vao_lam  in  date,
    p_ma_phong_ban  in  varchar2,
    p_ma_chuc_vu    in  varchar2,
    o_nhan_vien_id  out number);

  -- Tham so NULL = giu nguyen gia tri cu. Ma nhan vien khong sua duoc (BR-34).
  procedure sp_cap_nhat_nhan_vien(
    p_ma_nhan_vien  in varchar2,
    p_ho_ten        in varchar2 default null,
    p_email         in varchar2 default null,
    p_so_dien_thoai in varchar2 default null,
    p_dia_chi       in varchar2 default null,
    p_so_dinh_danh  in varchar2 default null,
    p_ma_so_thue    in varchar2 default null);

  -- Hop dong + muc luong dau tien ---------------------------------------------
  procedure sp_luu_hop_dong(
    p_ma_nhan_vien         in varchar2,
    p_so_hop_dong          in varchar2,
    p_ma_loai              in varchar2,
    p_ngay_bat_dau         in date,
    p_ngay_ket_thuc        in date,
    p_luong_co_ban         in number,
    p_can_cu_dong_bao_hiem in number);

  -- Muc luong moi cua hop dong dang co, hieu luc tu ngay 1 (BR-39)
  procedure sp_dieu_chinh_luong(
    p_so_hop_dong          in varchar2,
    p_tu_ngay              in date,
    p_luong_co_ban         in number,
    p_can_cu_dong_bao_hiem in number);

  -- Cong tac --------------------------------------------------------------------
  -- Phan cong cu ket thuc ngay truoc, phan cong moi bat dau ngay 1 (FR-EMP-05)
  procedure sp_dieu_chuyen(
    p_ma_nhan_vien  in varchar2,
    p_ma_phong_ban  in varchar2,
    p_ma_chuc_vu    in varchar2,
    p_ngay_hieu_luc in date,
    p_can_cu        in varchar2);

  -- Nguoi duoc chi dinh phai dang thuoc phong (FR-ORG-03, TC-10)
  procedure sp_chi_dinh_truong_phong(
    p_ma_nhan_vien  in varchar2,
    p_ma_phong_ban  in varchar2,
    p_ngay_hieu_luc in date,
    p_can_cu        in varchar2,
    p_ma_chuc_vu    in varchar2 default 'TRUONG_PHONG');

  procedure sp_nghi_viec(p_ma_nhan_vien in varchar2, p_ngay_nghi_viec in date);

  -- Nguoi phu thuoc --------------------------------------------------------------
  procedure sp_luu_nguoi_phu_thuoc(
    p_ma_nhan_vien in  varchar2,
    p_ho_ten       in  varchar2,
    p_quan_he      in  varchar2,
    p_dinh_danh    in  varchar2,
    p_tu_ngay      in  date,
    p_den_ngay     in  date,
    o_id           out number);

  -- p_ket_qua: DA_XAC_MINH | TU_CHOI
  procedure sp_xac_minh_nguoi_phu_thuoc(p_nguoi_phu_thuoc_id in number, p_ket_qua in varchar2);

  -- Khen thuong, ky luat ------------------------------------------------------
  procedure sp_luu_khen_thuong(
    p_ma_nhan_vien    in varchar2,
    p_so_quyet_dinh   in varchar2,
    p_ngay_quyet_dinh in date,
    p_ly_do           in varchar2,
    p_hinh_thuc       in varchar2,
    p_so_tien         in number default null);

  -- p_ket_qua: DA_DUYET | TU_CHOI (TU_CHOI bat buoc co ly do)
  procedure sp_duyet_khen_thuong(
    p_so_quyet_dinh in varchar2,
    p_ket_qua       in varchar2,
    p_ly_do_tu_choi in varchar2 default null);

  procedure sp_ghi_ky_luat(
    p_ma_nhan_vien        in varchar2,
    p_so_quyet_dinh       in varchar2,
    p_ngay_quyet_dinh     in date,
    p_ly_do               in varchar2,
    p_hinh_thuc           in varchar2,
    p_ten_nguoi_phe_duyet in varchar2 default null);

  -- Duyet phat sinh luong do Payroll lap (BO SUNG giai doan 4c): HR khac nguoi
  -- lap, khong duyet phat sinh cua chinh minh. p_ket_qua: DA_DUYET | TU_CHOI.
  -- Duyet lam thay doi dau vao luong -> danh dau tinh lai ky (BR-38).
  procedure sp_duyet_phat_sinh(
    p_phat_sinh_id in number,
    p_ket_qua      in varchar2);

  -- QR-07 (giai doan 5): nguoi phu thuoc DA_XAC_MINH con hieu luc trong thang.
  -- Tra tap ket qua qua SYS_REFCURSOR (dac ta: "bang qua procedure HR").
  -- p_ma_nhan_vien NULL = tat ca. Khong tra so dinh danh day du (chi 4 so cuoi).
  procedure sp_tra_nguoi_phu_thuoc(
    p_thang        in  number,
    p_nam          in  number,
    p_ma_nhan_vien in  varchar2 default null,
    o_ket_qua      out sys_refcursor);
end pkg_hr;
/
show errors

create or replace package body pkg_hr
as
  c_xa constant date := pkg_chung.c_ngay_xa;

  -- ===========================================================================
  -- Tra cuu va khoa dong
  -- ===========================================================================
  function lay_phong_ban(p_ma in varchar2) return phong_ban%rowtype
  is
    v phong_ban%rowtype;
  begin
    select * into v from phong_ban where ma_phong_ban = upper(p_ma);
    return v;
  exception
    when no_data_found then
      raise_application_error(-20108, 'Phòng ban "' || p_ma || '" không tồn tại.');
  end lay_phong_ban;

  function lay_chuc_vu(p_ma in varchar2) return chuc_vu%rowtype
  is
    v chuc_vu%rowtype;
  begin
    select * into v from chuc_vu where ma_chuc_vu = upper(p_ma);
    return v;
  exception
    when no_data_found then
      raise_application_error(-20108, 'Chức vụ "' || p_ma || '" không tồn tại.');
  end lay_chuc_vu;

  function id_nhan_vien(p_ma in varchar2) return number
  is
    v number;
  begin
    select nhan_vien_id into v from nhan_vien where ma_nhan_vien = upper(p_ma);
    return v;
  exception
    when no_data_found then
      raise_application_error(-20216, 'Nhân viên "' || p_ma || '" không tồn tại.');
  end id_nhan_vien;

  function khoa_nhan_vien(p_id in number) return nhan_vien%rowtype
  is
    v nhan_vien%rowtype;
  begin
    select * into v from nhan_vien where nhan_vien_id = p_id for update;
    return v;
  end khoa_nhan_vien;

  -- Khoa 1 hoac 2 phong theo ID tang dan (muc 8.5)
  procedure khoa_phong_ban(p_id1 in number, p_id2 in number default null)
  is
  begin
    for r in (select phong_ban_id from phong_ban
               where phong_ban_id in (p_id1, nvl(p_id2, p_id1))
               order by phong_ban_id
                 for update) loop
      null;
    end loop;
  end khoa_phong_ban;

  procedure yeu_cau_dang_hoat_dong(p_trang_thai in varchar2, p_ten in varchar2)
  is
  begin
    if p_trang_thai <> 'HOAT_DONG' then
      raise_application_error(-20106, p_ten || ' đã ngừng sử dụng, không nhận phân công mới (BR-05).');
    end if;
  end yeu_cau_dang_hoat_dong;

  -- Ngay p_ngay phai nam trong thoi gian lam viec cua nhan vien (BR-09)
  procedure yeu_cau_dang_lam(p_nv in nhan_vien%rowtype, p_ngay in date)
  is
  begin
    if p_ngay < p_nv.ngay_vao_lam or p_ngay > nvl(p_nv.ngay_nghi_viec, c_xa) then
      raise_application_error(-20217, 'Ngày ' || to_char(p_ngay, 'DD/MM/YYYY')
        || ' nằm ngoài thời gian làm việc của nhân viên ' || p_nv.ma_nhan_vien || '.');
    end if;
  end yeu_cau_dang_lam;

  -- Phong da co nguoi giu chuc vu quan ly giao voi [p_tu, vo han) (BR-06)
  procedure yeu_cau_phong_trong_truong_phong(p_phong_ban_id in number, p_tu in date, p_tru_nv in number)
  is
    v_dem number;
  begin
    select count(*) into v_dem
      from qua_trinh_cong_tac q
      join chuc_vu c on c.chuc_vu_id = q.chuc_vu_id
     where q.phong_ban_id = p_phong_ban_id
       and c.la_quan_ly
       and q.nhan_vien_id <> p_tru_nv
       and nvl(q.ngay_ket_thuc, c_xa) >= p_tu;
    if v_dem > 0 then
      raise_application_error(-20104, 'Phòng đã có người giữ chức vụ quản lý trong khoảng này (BR-06).');
    end if;
  end yeu_cau_phong_trong_truong_phong;

  -- Vai tro MANAGER cua tai khoan = dang (hoac se) giu chuc vu quan ly (TX-03)
  procedure dong_bo_vai_tro_manager(p_nhan_vien_id in number)
  is
    v_tk  number;
    v_ql  number;
    v_vt  number;
  begin
    begin
      select tai_khoan_id into v_tk from tai_khoan where nhan_vien_id = p_nhan_vien_id;
    exception
      when no_data_found then return;   -- nhan vien chua co tai khoan
    end;
    select vai_tro_id into v_vt from vai_tro where ma_vai_tro = 'MANAGER';
    select count(*) into v_ql
      from qua_trinh_cong_tac q join chuc_vu c on c.chuc_vu_id = q.chuc_vu_id
     where q.nhan_vien_id = p_nhan_vien_id
       and c.la_quan_ly
       and nvl(q.ngay_ket_thuc, c_xa) >= trunc(sysdate);

    if v_ql > 0 then
      insert into tai_khoan_vai_tro (tai_khoan_id, vai_tro_id, nguoi_gan)
      select v_tk, v_vt, fn_tai_khoan_hien_tai from dual
       where not exists (select 1 from tai_khoan_vai_tro where tai_khoan_id = v_tk and vai_tro_id = v_vt);
    else
      delete from tai_khoan_vai_tro where tai_khoan_id = v_tk and vai_tro_id = v_vt;
    end if;
  end dong_bo_vai_tro_manager;

  -- ===========================================================================
  -- To chuc (SP-25)
  -- ===========================================================================
  procedure sp_luu_phong_ban(
    p_ma           in varchar2,
    p_ten          in varchar2,
    p_mo_ta        in varchar2 default null,
    p_phong_ban_id in number   default null)
  is
  begin
    savepoint sp_pb;
    pkg_chung.yeu_cau_vai_tro('HR');
    if p_phong_ban_id is null then
      insert into phong_ban (ma_phong_ban, ten_phong_ban, mo_ta) values (upper(p_ma), p_ten, p_mo_ta);
    else
      khoa_phong_ban(p_phong_ban_id);
      update phong_ban set ma_phong_ban = upper(p_ma), ten_phong_ban = p_ten, mo_ta = p_mo_ta
       where phong_ban_id = p_phong_ban_id;
      if sql%rowcount = 0 then
        raise_application_error(-20108, 'Phòng ban ID ' || p_phong_ban_id || ' không tồn tại.');
      end if;
    end if;
  exception
    when others then
      rollback to sp_pb;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_phong_ban;

  procedure sp_luu_chuc_vu(
    p_ma         in varchar2,
    p_ten        in varchar2,
    p_la_quan_ly in boolean default false,
    p_chuc_vu_id in number  default null)
  is
    v      chuc_vu%rowtype;
    v_dung number;
  begin
    savepoint sp_cv;
    pkg_chung.yeu_cau_vai_tro('HR');
    if p_chuc_vu_id is null then
      insert into chuc_vu (ma_chuc_vu, ten_chuc_vu, la_quan_ly) values (upper(p_ma), p_ten, p_la_quan_ly);
      return;
    end if;

    begin
      select * into v from chuc_vu where chuc_vu_id = p_chuc_vu_id for update;
    exception
      when no_data_found then
        raise_application_error(-20108, 'Chức vụ ID ' || p_chuc_vu_id || ' không tồn tại.');
    end;
    -- Doi co quan ly cua chuc vu da dung se lam sai lich su truong phong (BR-06)
    if v.la_quan_ly <> p_la_quan_ly then
      select count(*) into v_dung from qua_trinh_cong_tac where chuc_vu_id = v.chuc_vu_id;
      if v_dung > 0 then
        raise_application_error(-20109, 'Không đổi cờ quản lý của chức vụ đã được phân công.');
      end if;
    end if;
    update chuc_vu set ma_chuc_vu = upper(p_ma), ten_chuc_vu = p_ten, la_quan_ly = p_la_quan_ly
     where chuc_vu_id = v.chuc_vu_id;
  exception
    when others then
      rollback to sp_cv;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_chuc_vu;

  procedure sp_ngung_danh_muc(p_loai in varchar2, p_ma in varchar2)
  is
    v_id   number;
    v_dung number;
  begin
    savepoint sp_ngung;
    pkg_chung.yeu_cau_vai_tro('HR');
    if upper(p_loai) = 'PHONG_BAN' then
      v_id := lay_phong_ban(p_ma).phong_ban_id;
      khoa_phong_ban(v_id);
      select count(*) into v_dung from qua_trinh_cong_tac
       where phong_ban_id = v_id and nvl(ngay_ket_thuc, c_xa) >= trunc(sysdate);
    elsif upper(p_loai) = 'CHUC_VU' then
      v_id := lay_chuc_vu(p_ma).chuc_vu_id;
      select chuc_vu_id into v_id from chuc_vu where chuc_vu_id = v_id for update;
      select count(*) into v_dung from qua_trinh_cong_tac
       where chuc_vu_id = v_id and nvl(ngay_ket_thuc, c_xa) >= trunc(sysdate);
    else
      raise_application_error(-20110, 'Loại danh mục phải là PHONG_BAN hoặc CHUC_VU.');
    end if;

    if v_dung > 0 then
      raise_application_error(-20105, 'Không ngừng được: còn ' || v_dung
        || ' phân công hiện tại hoặc tương lai (FR-ORG-04).');
    end if;

    if upper(p_loai) = 'PHONG_BAN' then
      update phong_ban set trang_thai = 'NGUNG' where phong_ban_id = v_id;
    else
      update chuc_vu set trang_thai = 'NGUNG' where chuc_vu_id = v_id;
    end if;
  exception
    when others then
      rollback to sp_ngung;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_ngung_danh_muc;

  -- ===========================================================================
  -- Ho so (SP-01, SP-24)
  -- ===========================================================================
  procedure sp_them_nhan_vien(
    p_ma_nhan_vien  in  varchar2,
    p_ho_ten        in  varchar2,
    p_ngay_sinh     in  date,
    p_so_dinh_danh  in  varchar2,
    p_ma_so_thue    in  varchar2,
    p_email         in  varchar2,
    p_so_dien_thoai in  varchar2,
    p_dia_chi       in  varchar2,
    p_ngay_vao_lam  in  date,
    p_ma_phong_ban  in  varchar2,
    p_ma_chuc_vu    in  varchar2,
    o_nhan_vien_id  out number)
  is
    v_pb phong_ban%rowtype;
    v_cv chuc_vu%rowtype;
  begin
    savepoint sp_them_nv;
    pkg_chung.yeu_cau_vai_tro('HR');

    -- Nhan vien moi lam thay doi tap nguoi duoc tinh luong tu ngay vao lam
    pkg_payroll.danh_dau_tinh_lai(p_ngay_vao_lam, null);

    v_pb := lay_phong_ban(p_ma_phong_ban);
    v_cv := lay_chuc_vu(p_ma_chuc_vu);
    yeu_cau_dang_hoat_dong(v_pb.trang_thai, 'Phòng ' || v_pb.ma_phong_ban);
    yeu_cau_dang_hoat_dong(v_cv.trang_thai, 'Chức vụ ' || v_cv.ma_chuc_vu);

    insert into nhan_vien (ma_nhan_vien, ho_ten, ngay_sinh, so_dinh_danh, ma_so_thue,
                           email, so_dien_thoai, dia_chi, ngay_vao_lam)
    values (upper(p_ma_nhan_vien), p_ho_ten, p_ngay_sinh, p_so_dinh_danh, p_ma_so_thue,
            p_email, p_so_dien_thoai, p_dia_chi, p_ngay_vao_lam)
    returning nhan_vien_id into o_nhan_vien_id;

    if v_cv.la_quan_ly then
      khoa_phong_ban(v_pb.phong_ban_id);
      yeu_cau_phong_trong_truong_phong(v_pb.phong_ban_id, p_ngay_vao_lam, o_nhan_vien_id);
    end if;

    -- Ho so va phan cong dau tien la mot don vi nguyen tu (TX-01)
    insert into qua_trinh_cong_tac (nhan_vien_id, phong_ban_id, chuc_vu_id, ngay_bat_dau)
    values (o_nhan_vien_id, v_pb.phong_ban_id, v_cv.chuc_vu_id, p_ngay_vao_lam);
  exception
    when others then
      rollback to sp_them_nv;
      o_nhan_vien_id := null;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_them_nhan_vien;

  procedure sp_cap_nhat_nhan_vien(
    p_ma_nhan_vien  in varchar2,
    p_ho_ten        in varchar2 default null,
    p_email         in varchar2 default null,
    p_so_dien_thoai in varchar2 default null,
    p_dia_chi       in varchar2 default null,
    p_so_dinh_danh  in varchar2 default null,
    p_ma_so_thue    in varchar2 default null)
  is
    v nhan_vien%rowtype;
  begin
    savepoint sp_cap_nhat_nv;
    pkg_chung.yeu_cau_vai_tro('HR');
    v := khoa_nhan_vien(id_nhan_vien(p_ma_nhan_vien));
    update nhan_vien
       set ho_ten        = nvl(p_ho_ten, ho_ten),
           email         = nvl(p_email, email),
           so_dien_thoai = nvl(p_so_dien_thoai, so_dien_thoai),
           dia_chi       = nvl(p_dia_chi, dia_chi),
           so_dinh_danh  = nvl(p_so_dinh_danh, so_dinh_danh),
           ma_so_thue    = nvl(p_ma_so_thue, ma_so_thue)
     where nhan_vien_id = v.nhan_vien_id;   -- TR-01 ghi truoc/sau (TC-13)
  exception
    when others then
      rollback to sp_cap_nhat_nv;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_cap_nhat_nhan_vien;

  -- ===========================================================================
  -- Hop dong va muc luong (SP-02)
  -- ===========================================================================
  procedure sp_luu_hop_dong(
    p_ma_nhan_vien         in varchar2,
    p_so_hop_dong          in varchar2,
    p_ma_loai              in varchar2,
    p_ngay_bat_dau         in date,
    p_ngay_ket_thuc        in date,
    p_luong_co_ban         in number,
    p_can_cu_dong_bao_hiem in number)
  is
    v_nv     nhan_vien%rowtype;
    v_loai   loai_hop_dong%rowtype;
    v_chong  number;
    v_hd     number;
  begin
    savepoint sp_hd;
    pkg_chung.yeu_cau_vai_tro('HR');

    if p_ngay_ket_thuc is not null and p_ngay_ket_thuc <= p_ngay_bat_dau then
      raise_application_error(-20206, 'Ngày kết thúc hợp đồng phải sau ngày bắt đầu.');
    end if;

    -- Khoa ky truoc, nhan vien sau (muc 8.5)
    pkg_payroll.danh_dau_tinh_lai(p_ngay_bat_dau, p_ngay_ket_thuc);
    v_nv := khoa_nhan_vien(id_nhan_vien(p_ma_nhan_vien));
    yeu_cau_dang_lam(v_nv, p_ngay_bat_dau);

    begin
      select * into v_loai from loai_hop_dong where ma_loai = upper(p_ma_loai);
    exception
      when no_data_found then
        raise_application_error(-20108, 'Loại hợp đồng "' || p_ma_loai || '" không tồn tại.');
    end;
    if v_loai.yeu_cau_ngay_ket_thuc and p_ngay_ket_thuc is null then
      raise_application_error(-20218, 'Hợp đồng ' || v_loai.ten_loai || ' phải có ngày kết thúc.');
    end if;

    -- BR-39: hop dong moi cua nguoi dang lam co hieu luc tu ngay 1 cua ky
    if p_ngay_bat_dau <> v_nv.ngay_vao_lam and p_ngay_bat_dau <> trunc(p_ngay_bat_dau, 'MM') then
      raise_application_error(-20207, 'Hợp đồng mới của người đang làm phải bắt đầu từ ngày 1 của tháng (BR-39).');
    end if;

    -- BR-07: khong chong hieu luc voi hop dong khong huy cua cung nguoi
    select count(*) into v_chong
      from hop_dong
     where nhan_vien_id = v_nv.nhan_vien_id
       and not da_huy
       and ngay_bat_dau <= nvl(p_ngay_ket_thuc, c_xa)
       and nvl(ngay_ket_thuc, c_xa) >= p_ngay_bat_dau;
    if v_chong > 0 then
      raise_application_error(-20205, 'Hợp đồng chồng hiệu lực với hợp đồng hiện có của nhân viên (BR-07).');
    end if;

    insert into hop_dong (so_hop_dong, nhan_vien_id, loai_hop_dong_id, ngay_bat_dau, ngay_ket_thuc)
    values (p_so_hop_dong, v_nv.nhan_vien_id, v_loai.loai_hop_dong_id, p_ngay_bat_dau, p_ngay_ket_thuc)
    returning hop_dong_id into v_hd;

    insert into muc_luong_hop_dong (hop_dong_id, tu_ngay, den_ngay, luong_co_ban, can_cu_dong_bao_hiem)
    values (v_hd, trunc(p_ngay_bat_dau, 'MM'), p_ngay_ket_thuc, p_luong_co_ban, p_can_cu_dong_bao_hiem);
  exception
    when others then
      rollback to sp_hd;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_hop_dong;

  procedure sp_dieu_chinh_luong(
    p_so_hop_dong          in varchar2,
    p_tu_ngay              in date,
    p_luong_co_ban         in number,
    p_can_cu_dong_bao_hiem in number)
  is
    v_hd      hop_dong%rowtype;
    v_nv      nhan_vien%rowtype;
    v_tu_cuoi date;
  begin
    savepoint sp_luong;
    pkg_chung.yeu_cau_vai_tro('HR');

    begin
      select * into v_hd from hop_dong where so_hop_dong = p_so_hop_dong;
    exception
      when no_data_found then
        raise_application_error(-20220, 'Hợp đồng "' || p_so_hop_dong || '" không tồn tại.');
    end;
    if p_tu_ngay <> trunc(p_tu_ngay, 'MM') then
      raise_application_error(-20207, 'Mức lương mới phải có hiệu lực từ ngày 1 của tháng (BR-39).');
    end if;
    if v_hd.da_huy or p_tu_ngay > nvl(v_hd.ngay_ket_thuc, c_xa) then
      raise_application_error(-20221, 'Ngày hiệu lực nằm ngoài hợp đồng hoặc hợp đồng đã hủy.');
    end if;

    pkg_payroll.danh_dau_tinh_lai(p_tu_ngay, v_hd.ngay_ket_thuc);
    v_nv := khoa_nhan_vien(v_hd.nhan_vien_id);

    select max(tu_ngay) into v_tu_cuoi from muc_luong_hop_dong where hop_dong_id = v_hd.hop_dong_id;
    if p_tu_ngay <= v_tu_cuoi then
      raise_application_error(-20221, 'Mức lương mới phải bắt đầu sau mức hiện tại ('
        || to_char(v_tu_cuoi, 'DD/MM/YYYY') || ').');
    end if;

    update muc_luong_hop_dong
       set den_ngay = p_tu_ngay - 1
     where hop_dong_id = v_hd.hop_dong_id and tu_ngay = v_tu_cuoi;

    insert into muc_luong_hop_dong (hop_dong_id, tu_ngay, den_ngay, luong_co_ban, can_cu_dong_bao_hiem)
    values (v_hd.hop_dong_id, p_tu_ngay, v_hd.ngay_ket_thuc, p_luong_co_ban, p_can_cu_dong_bao_hiem);
  exception
    when others then
      rollback to sp_luong;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_dieu_chinh_luong;

  -- ===========================================================================
  -- Cong tac (SP-03)
  -- ===========================================================================
  -- Dung chung cho dieu chuyen va chi dinh truong phong (TX-03)
  procedure dieu_chuyen_noi_bo(
    p_nv_id   in number,
    p_pb_moi  in phong_ban%rowtype,
    p_cv_moi  in chuc_vu%rowtype,
    p_ngay    in date,
    p_can_cu  in varchar2)
  is
    v_cu   qua_trinh_cong_tac%rowtype;
    v_nv   nhan_vien%rowtype;
    v_sau  number;
  begin
    if p_ngay is null or p_ngay <> trunc(p_ngay, 'MM') then
      raise_application_error(-20219, 'Phân công mới phải bắt đầu từ ngày 1 của tháng (FR-EMP-05).');
    end if;

    pkg_payroll.danh_dau_tinh_lai(p_ngay, null);                       -- 1. KY_LUONG

    begin
      select * into v_cu from qua_trinh_cong_tac
       where nhan_vien_id = p_nv_id
         and ngay_bat_dau < p_ngay
         and nvl(ngay_ket_thuc, c_xa) >= p_ngay;
    exception
      when no_data_found then
        raise_application_error(-20219, 'Nhân viên không có phân công hiệu lực trước ngày '
          || to_char(p_ngay, 'DD/MM/YYYY') || '.');
    end;
    select count(*) into v_sau from qua_trinh_cong_tac
     where nhan_vien_id = p_nv_id and ngay_bat_dau >= p_ngay;
    if v_sau > 0 then
      raise_application_error(-20219, 'Nhân viên đã có phân công bắt đầu từ ngày này trở về sau.');
    end if;

    khoa_phong_ban(v_cu.phong_ban_id, p_pb_moi.phong_ban_id);           -- 2. PHONG_BAN tang dan
    v_nv := khoa_nhan_vien(p_nv_id);                                     -- 3. NHAN_VIEN
    yeu_cau_dang_lam(v_nv, p_ngay);

    yeu_cau_dang_hoat_dong(p_pb_moi.trang_thai, 'Phòng ' || p_pb_moi.ma_phong_ban);
    yeu_cau_dang_hoat_dong(p_cv_moi.trang_thai, 'Chức vụ ' || p_cv_moi.ma_chuc_vu);

    if v_cu.phong_ban_id = p_pb_moi.phong_ban_id and v_cu.chuc_vu_id = p_cv_moi.chuc_vu_id then
      raise_application_error(-20219, 'Phân công mới trùng phân công hiện tại.');
    end if;
    if p_cv_moi.la_quan_ly then
      yeu_cau_phong_trong_truong_phong(p_pb_moi.phong_ban_id, p_ngay, p_nv_id);
    end if;

    update qua_trinh_cong_tac set ngay_ket_thuc = p_ngay - 1 where cong_tac_id = v_cu.cong_tac_id;
    insert into qua_trinh_cong_tac (nhan_vien_id, phong_ban_id, chuc_vu_id, ngay_bat_dau, can_cu_dieu_chuyen)
    values (p_nv_id, p_pb_moi.phong_ban_id, p_cv_moi.chuc_vu_id, p_ngay, p_can_cu);

    dong_bo_vai_tro_manager(p_nv_id);
  end dieu_chuyen_noi_bo;

  procedure sp_dieu_chuyen(
    p_ma_nhan_vien  in varchar2,
    p_ma_phong_ban  in varchar2,
    p_ma_chuc_vu    in varchar2,
    p_ngay_hieu_luc in date,
    p_can_cu        in varchar2)
  is
  begin
    savepoint sp_dc;
    pkg_chung.yeu_cau_vai_tro('HR');
    dieu_chuyen_noi_bo(id_nhan_vien(p_ma_nhan_vien), lay_phong_ban(p_ma_phong_ban),
                       lay_chuc_vu(p_ma_chuc_vu), p_ngay_hieu_luc, p_can_cu);
  exception
    when others then
      rollback to sp_dc;   -- loi buoc moi: giu nguyen phan cong cu (TC-16)
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_dieu_chuyen;

  procedure sp_chi_dinh_truong_phong(
    p_ma_nhan_vien  in varchar2,
    p_ma_phong_ban  in varchar2,
    p_ngay_hieu_luc in date,
    p_can_cu        in varchar2,
    p_ma_chuc_vu    in varchar2 default 'TRUONG_PHONG')
  is
    v_nv_id   number;
    v_pb      phong_ban%rowtype;
    v_cv      chuc_vu%rowtype;
    v_pb_hien number;
  begin
    savepoint sp_tp;
    pkg_chung.yeu_cau_vai_tro('HR');
    v_nv_id := id_nhan_vien(p_ma_nhan_vien);
    v_pb    := lay_phong_ban(p_ma_phong_ban);
    v_cv    := lay_chuc_vu(p_ma_chuc_vu);

    if not v_cv.la_quan_ly then
      raise_application_error(-20103, 'Chức vụ ' || v_cv.ma_chuc_vu || ' không phải chức vụ quản lý.');
    end if;

    -- Nguoi duoc chi dinh phai dang thuoc phong ngay truoc ngay hieu luc
    select max(phong_ban_id) into v_pb_hien from qua_trinh_cong_tac
     where nhan_vien_id = v_nv_id
       and p_ngay_hieu_luc - 1 between ngay_bat_dau and nvl(ngay_ket_thuc, c_xa);
    if v_pb_hien is null or v_pb_hien <> v_pb.phong_ban_id then
      raise_application_error(-20103, 'Người được chỉ định không thuộc phòng ' || v_pb.ma_phong_ban || ' (FR-ORG-03).');
    end if;

    dieu_chuyen_noi_bo(v_nv_id, v_pb, v_cv, p_ngay_hieu_luc, p_can_cu);
  exception
    when others then
      rollback to sp_tp;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_chi_dinh_truong_phong;

  -- ===========================================================================
  -- Nghi viec (SP-18)
  -- ===========================================================================
  procedure sp_nghi_viec(p_ma_nhan_vien in varchar2, p_ngay_nghi_viec in date)
  is
    v_nv_id number := null;
    v_nv    nhan_vien%rowtype;
    v_pb    number;
    v_sau   number;
  begin
    savepoint sp_nghi;
    pkg_chung.yeu_cau_vai_tro('HR');
    v_nv_id := id_nhan_vien(p_ma_nhan_vien);

    pkg_payroll.danh_dau_tinh_lai(p_ngay_nghi_viec, null);              -- 1. KY_LUONG
    select max(phong_ban_id) into v_pb from qua_trinh_cong_tac
     where nhan_vien_id = v_nv_id
       and p_ngay_nghi_viec between ngay_bat_dau and nvl(ngay_ket_thuc, c_xa);
    if v_pb is not null then
      khoa_phong_ban(v_pb);                                              -- 2. PHONG_BAN
    end if;
    v_nv := khoa_nhan_vien(v_nv_id);                                     -- 3. NHAN_VIEN

    if v_nv.ngay_nghi_viec is not null then
      raise_application_error(-20217, 'Nhân viên đã được ghi nghỉ việc ngày '
        || to_char(v_nv.ngay_nghi_viec, 'DD/MM/YYYY') || '.');
    end if;
    yeu_cau_dang_lam(v_nv, p_ngay_nghi_viec);

    -- Khong duoc con cong, OT, nghi hieu luc hay phan cong sau ngay nghi viec (BR-09)
    select (select count(*) from cham_cong where nhan_vien_id = v_nv_id and ngay > p_ngay_nghi_viec)
         + (select count(*) from dang_ky_tang_ca where nhan_vien_id = v_nv_id and ngay > p_ngay_nghi_viec
                                                   and trang_thai in ('CHO_DUYET', 'DA_DUYET'))
         + (select count(*) from chi_tiet_nghi_phep where nhan_vien_id = v_nv_id and ngay > p_ngay_nghi_viec
                                                      and con_hieu_luc = 1)
         + (select count(*) from qua_trinh_cong_tac where nhan_vien_id = v_nv_id and ngay_bat_dau > p_ngay_nghi_viec)
      into v_sau from dual;
    if v_sau > 0 then
      raise_application_error(-20208, 'Còn ' || v_sau || ' bản ghi công, OT, nghỉ hoặc phân công sau ngày nghỉ việc; '
        || 'xử lý các bản ghi này trước.');
    end if;

    update nhan_vien set ngay_nghi_viec = p_ngay_nghi_viec where nhan_vien_id = v_nv_id;

    update qua_trinh_cong_tac set ngay_ket_thuc = p_ngay_nghi_viec
     where nhan_vien_id = v_nv_id and nvl(ngay_ket_thuc, c_xa) > p_ngay_nghi_viec;

    -- Hop dong: ket thuc tai ngay nghi viec; hop dong bat dau dung ngay nghi bi huy
    update hop_dong
       set ngay_ket_thuc = case when ngay_bat_dau < p_ngay_nghi_viec then p_ngay_nghi_viec else ngay_ket_thuc end,
           da_huy        = case when ngay_bat_dau >= p_ngay_nghi_viec then true else da_huy end
     where nhan_vien_id = v_nv_id and not da_huy and nvl(ngay_ket_thuc, c_xa) > p_ngay_nghi_viec;

    update muc_luong_hop_dong set den_ngay = p_ngay_nghi_viec
     where hop_dong_id in (select hop_dong_id from hop_dong where nhan_vien_id = v_nv_id)
       and tu_ngay <= p_ngay_nghi_viec and nvl(den_ngay, c_xa) > p_ngay_nghi_viec;

    update khoan_luong_nhan_vien set den_ngay = p_ngay_nghi_viec
     where nhan_vien_id = v_nv_id and tu_ngay <= p_ngay_nghi_viec and nvl(den_ngay, c_xa) > p_ngay_nghi_viec;

    update tai_khoan set trang_thai = 'KHOA' where nhan_vien_id = v_nv_id;   -- FR-EMP-06

    dong_bo_vai_tro_manager(v_nv_id);
  exception
    when others then
      rollback to sp_nghi;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_nghi_viec;

  -- ===========================================================================
  -- Nguoi phu thuoc (SP-23)
  -- ===========================================================================
  function chuan_hoa_dinh_danh(p in varchar2) return varchar2
  is
  begin
    return upper(regexp_replace(p, '[^[:alnum:]]', ''));
  end chuan_hoa_dinh_danh;

  -- Khoa nguoi dung theo dinh danh: hai phien cung dang ky mot nguoi phu thuoc
  -- se cho nhau, nen kiem tra chong khoang khong bi bo qua (BR-10).
  -- Dung so khoa tu ORA_HASH thay vi ALLOCATE_UNIQUE vi ham do tu COMMIT.
  procedure khoa_dinh_danh(p_dinh_danh in varchar2)
  is
    v_kq integer;
    v_id integer;
  begin
    select 1000000 + ora_hash('HRM_NPT_' || p_dinh_danh, 999999999) into v_id from dual;
    v_kq := dbms_lock.request(
              id                => v_id,
              lockmode          => dbms_lock.x_mode,
              timeout           => 5,
              release_on_commit => true);
    if v_kq not in (0, 4) then   -- 0: thanh cong, 4: phien nay da giu khoa
      raise_application_error(-20224, 'Định danh người phụ thuộc đang được xử lý ở phiên khác, thử lại sau.');
    end if;
  end khoa_dinh_danh;

  procedure yeu_cau_khong_chong_dinh_danh(
    p_dinh_danh in varchar2, p_tu in date, p_den in date, p_tru_id in number)
  is
    v_dem number;
  begin
    select count(*) into v_dem
      from nguoi_phu_thuoc
     where dinh_danh_chuan_hoa = p_dinh_danh
       and trang_thai_xac_minh <> 'TU_CHOI'
       and nguoi_phu_thuoc_id <> nvl(p_tru_id, -1)
       and tu_ngay <= nvl(p_den, c_xa)
       and nvl(den_ngay, c_xa) >= p_tu;
    if v_dem > 0 then
      raise_application_error(-20210, 'Người phụ thuộc này đã được đăng ký giảm trừ trong khoảng thời gian giao nhau (BR-10).');
    end if;
  end yeu_cau_khong_chong_dinh_danh;

  procedure sp_luu_nguoi_phu_thuoc(
    p_ma_nhan_vien in  varchar2,
    p_ho_ten       in  varchar2,
    p_quan_he      in  varchar2,
    p_dinh_danh    in  varchar2,
    p_tu_ngay      in  date,
    p_den_ngay     in  date,
    o_id           out number)
  is
    v_nv_id number;
    v_dd    varchar2(20) := chuan_hoa_dinh_danh(p_dinh_danh);
  begin
    savepoint sp_npt;
    pkg_chung.yeu_cau_vai_tro('HR');
    v_nv_id := id_nhan_vien(p_ma_nhan_vien);
    if p_den_ngay < p_tu_ngay then
      raise_application_error(-20209, 'Khoảng giảm trừ không hợp lệ: ngày kết thúc trước ngày bắt đầu.');
    end if;

    khoa_dinh_danh(v_dd);
    yeu_cau_khong_chong_dinh_danh(v_dd, p_tu_ngay, p_den_ngay, null);

    -- Chua xac minh thi chua duoc giam tru nen chua anh huong luong
    insert into nguoi_phu_thuoc (nhan_vien_id, ho_ten, quan_he, dinh_danh_chuan_hoa, tu_ngay, den_ngay)
    values (v_nv_id, p_ho_ten, upper(p_quan_he), v_dd, p_tu_ngay, p_den_ngay)
    returning nguoi_phu_thuoc_id into o_id;
  exception
    when others then
      rollback to sp_npt;
      o_id := null;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_nguoi_phu_thuoc;

  procedure sp_xac_minh_nguoi_phu_thuoc(p_nguoi_phu_thuoc_id in number, p_ket_qua in varchar2)
  is
    v nguoi_phu_thuoc%rowtype;
  begin
    savepoint sp_xm;
    pkg_chung.yeu_cau_vai_tro('HR');
    if upper(p_ket_qua) not in ('DA_XAC_MINH', 'TU_CHOI') then
      raise_application_error(-20223, 'Kết quả xác minh phải là DA_XAC_MINH hoặc TU_CHOI.');
    end if;

    begin
      select * into v from nguoi_phu_thuoc where nguoi_phu_thuoc_id = p_nguoi_phu_thuoc_id;
    exception
      when no_data_found then
        raise_application_error(-20223, 'Đăng ký người phụ thuộc không tồn tại.');
    end;
    if v.nhan_vien_id = pkg_chung.nhan_vien then
      raise_application_error(-20222, 'Không tự xác minh người phụ thuộc của chính mình (BR-15).');
    end if;

    if upper(p_ket_qua) = 'DA_XAC_MINH' then
      pkg_payroll.danh_dau_tinh_lai(v.tu_ngay, v.den_ngay);   -- giam tru thay doi
    end if;
    khoa_dinh_danh(v.dinh_danh_chuan_hoa);
    select * into v from nguoi_phu_thuoc where nguoi_phu_thuoc_id = p_nguoi_phu_thuoc_id for update;
    if v.trang_thai_xac_minh <> 'CHO_XAC_MINH' then
      raise_application_error(-20223, 'Đăng ký đã được xử lý (' || v.trang_thai_xac_minh || ').');
    end if;
    if upper(p_ket_qua) = 'DA_XAC_MINH' then
      yeu_cau_khong_chong_dinh_danh(v.dinh_danh_chuan_hoa, v.tu_ngay, v.den_ngay, v.nguoi_phu_thuoc_id);
    end if;

    update nguoi_phu_thuoc set trang_thai_xac_minh = upper(p_ket_qua)
     where nguoi_phu_thuoc_id = v.nguoi_phu_thuoc_id;
  exception
    when others then
      rollback to sp_xm;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_xac_minh_nguoi_phu_thuoc;

  -- ===========================================================================
  -- Khen thuong, ky luat (SP-19, SP-20)
  -- ===========================================================================
  procedure sp_luu_khen_thuong(
    p_ma_nhan_vien    in varchar2,
    p_so_quyet_dinh   in varchar2,
    p_ngay_quyet_dinh in date,
    p_ly_do           in varchar2,
    p_hinh_thuc       in varchar2,
    p_so_tien         in number default null)
  is
    v_nv_id number;
  begin
    savepoint sp_kt;
    pkg_chung.yeu_cau_vai_tro('HR');
    v_nv_id := id_nhan_vien(p_ma_nhan_vien);
    insert into khen_thuong (nhan_vien_id, so_quyet_dinh, ngay_quyet_dinh, ly_do, hinh_thuc, so_tien, nguoi_tao)
    values (v_nv_id, p_so_quyet_dinh, p_ngay_quyet_dinh, p_ly_do,
            upper(p_hinh_thuc), p_so_tien, pkg_chung.tai_khoan);
  exception
    when others then
      rollback to sp_kt;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_khen_thuong;

  procedure sp_duyet_khen_thuong(
    p_so_quyet_dinh in varchar2,
    p_ket_qua       in varchar2,
    p_ly_do_tu_choi in varchar2 default null)
  is
    v khen_thuong%rowtype;
  begin
    savepoint sp_duyet_kt;
    pkg_chung.yeu_cau_vai_tro('HR');
    begin
      select * into v from khen_thuong where so_quyet_dinh = p_so_quyet_dinh for update;
    exception
      when no_data_found then
        raise_application_error(-20610, 'Quyết định "' || p_so_quyet_dinh || '" không tồn tại.');
    end;

    if v.trang_thai_duyet <> 'CHO_DUYET' then
      raise_application_error(-20603, 'Quyết định đã được xử lý (' || v.trang_thai_duyet || ').');
    end if;
    -- Muc 2.4: HR khac nguoi tao va khong phai nguoi duoc thuong (BR-15)
    if v.nguoi_tao = pkg_chung.tai_khoan then
      raise_application_error(-20604, 'Không được duyệt quyết định do chính mình tạo (BR-15).');
    end if;
    if v.nhan_vien_id = fn_nhan_vien_hien_tai then
      raise_application_error(-20608, 'Không được duyệt quyết định khen thưởng cho chính mình (BR-15).');
    end if;
    if upper(p_ket_qua) = 'TU_CHOI' and trim(p_ly_do_tu_choi) is null then
      raise_application_error(-20605, 'Từ chối phải ghi lý do.');
    end if;
    if upper(p_ket_qua) not in ('DA_DUYET', 'TU_CHOI') then
      raise_application_error(-20609, 'Kết quả duyệt phải là DA_DUYET hoặc TU_CHOI.');
    end if;

    update khen_thuong
       set trang_thai_duyet = upper(p_ket_qua),
           nguoi_duyet      = pkg_chung.tai_khoan,
           thoi_diem_duyet  = systimestamp,
           ly_do_tu_choi    = case when upper(p_ket_qua) = 'TU_CHOI' then p_ly_do_tu_choi end
     where khen_thuong_id = v.khen_thuong_id;
  exception
    when others then
      rollback to sp_duyet_kt;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_duyet_khen_thuong;

  procedure sp_ghi_ky_luat(
    p_ma_nhan_vien        in varchar2,
    p_so_quyet_dinh       in varchar2,
    p_ngay_quyet_dinh     in date,
    p_ly_do               in varchar2,
    p_hinh_thuc           in varchar2,
    p_ten_nguoi_phe_duyet in varchar2 default null)
  is
    v_pd    number;
    v_nv_id number;
  begin
    savepoint sp_kl;
    pkg_chung.yeu_cau_vai_tro('HR');
    v_nv_id := id_nhan_vien(p_ma_nhan_vien);
    if p_ten_nguoi_phe_duyet is not null then
      begin
        select tai_khoan_id into v_pd from tai_khoan
         where upper(ten_dang_nhap) = upper(trim(p_ten_nguoi_phe_duyet));
      exception
        when no_data_found then
          raise_application_error(-20018, 'Tài khoản "' || p_ten_nguoi_phe_duyet || '" không tồn tại.');
      end;
    end if;
    -- Ky luat khong co cot tien va khong ghi sang PHAT_SINH_LUONG (BR-31)
    insert into ky_luat (nhan_vien_id, so_quyet_dinh, ngay_quyet_dinh, ly_do, hinh_thuc, nguoi_tao, nguoi_phe_duyet)
    values (v_nv_id, p_so_quyet_dinh, p_ngay_quyet_dinh, p_ly_do,
            upper(p_hinh_thuc), pkg_chung.tai_khoan, v_pd);
  exception
    when others then
      rollback to sp_kl;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_ghi_ky_luat;

  procedure sp_duyet_phat_sinh(
    p_phat_sinh_id in number,
    p_ket_qua      in varchar2)
  is
    v      phat_sinh_luong%rowtype;
    v_ky   ky_luong%rowtype;
    v_tu   date;
    v_kq   varchar2(10) := upper(p_ket_qua);
  begin
    savepoint sp_duyet_ps;
    pkg_chung.yeu_cau_vai_tro('HR');
    if v_kq is null or v_kq not in ('DA_DUYET', 'TU_CHOI') then
      raise_application_error(-20523, 'Kết quả duyệt phải là DA_DUYET hoặc TU_CHOI.');
    end if;
    begin
      select * into v from phat_sinh_luong where phat_sinh_id = p_phat_sinh_id;
    exception
      when no_data_found then
        raise_application_error(-20523, 'Phát sinh ' || p_phat_sinh_id || ' không tồn tại.');
    end;
    select * into v_ky from ky_luong where ky_luong_id = v.ky_luong_id;
    v_tu := to_date(v_ky.nam || '-' || v_ky.thang || '-01', 'YYYY-MM-DD');

    -- Thu tu khoa: KY_LUONG truoc (ky DA_KHOA bi tu choi), roi ban ghi
    if v_kq = 'DA_DUYET' then
      pkg_payroll.danh_dau_tinh_lai(v_tu, last_day(v_tu));
    else
      select * into v_ky from ky_luong where ky_luong_id = v.ky_luong_id for update;
      if v_ky.trang_thai = 'DA_KHOA' then
        raise_application_error(-20501, 'Kỳ ' || lpad(v_ky.thang, 2, '0') || '/' || v_ky.nam || ' đã khóa.');
      end if;
    end if;
    select * into v from phat_sinh_luong where phat_sinh_id = p_phat_sinh_id for update;

    if v.trang_thai_duyet <> 'CHO_DUYET' then
      raise_application_error(-20523, 'Phát sinh ' || p_phat_sinh_id || ' đã được xử lý (' || v.trang_thai_duyet || ').');
    end if;
    if v.nguoi_tao = pkg_chung.tai_khoan or v.nhan_vien_id = fn_nhan_vien_hien_tai then
      raise_application_error(-20524, 'Không duyệt phát sinh do mình lập hoặc của chính mình (BR-15).');
    end if;

    update phat_sinh_luong
       set trang_thai_duyet = v_kq, nguoi_duyet = pkg_chung.tai_khoan
     where phat_sinh_id = p_phat_sinh_id;
  exception
    when others then
      rollback to sp_duyet_ps;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_duyet_phat_sinh;

  procedure sp_tra_nguoi_phu_thuoc(
    p_thang        in  number,
    p_nam          in  number,
    p_ma_nhan_vien in  varchar2 default null,
    o_ket_qua      out sys_refcursor)
  is
    v_tu  date;
    v_den date;
  begin
    pkg_chung.yeu_cau_vai_tro('HR');
    if p_thang is null or p_thang not between 1 and 12 or p_nam is null then
      raise_application_error(-20511, 'Tháng/năm không hợp lệ.');
    end if;
    v_tu  := to_date(p_nam || '-' || p_thang || '-01', 'YYYY-MM-DD');
    v_den := last_day(v_tu);

    -- Giao khoang [tu_ngay, den_ngay] voi thang: tu_ngay <= cuoi thang va den_ngay >= dau thang
    open o_ket_qua for
      select n.ma_nhan_vien,
             n.ho_ten,
             p.ho_ten                                   as nguoi_phu_thuoc,
             p.quan_he,
             '********' || substr(p.dinh_danh_chuan_hoa, -4) as dinh_danh,
             p.tu_ngay,
             p.den_ngay
        from nguoi_phu_thuoc p
        join nhan_vien n on n.nhan_vien_id = p.nhan_vien_id
       where p.trang_thai_xac_minh = 'DA_XAC_MINH'
         and p.tu_ngay <= v_den
         and nvl(p.den_ngay, c_xa) >= v_tu
         and (p_ma_nhan_vien is null or n.ma_nhan_vien = upper(p_ma_nhan_vien))
       order by n.ma_nhan_vien, p.tu_ngay;
  end sp_tra_nguoi_phu_thuoc;
end pkg_hr;
/
show errors
