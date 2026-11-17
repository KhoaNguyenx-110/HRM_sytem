-- =============================================================================
-- 12_pkg_att.sql - Cham cong va lam them gio
--   SP-26 sp_luu_lich_lam_viec   (HR, FR-ATT-01)
--   SP-15 sp_luu_cham_cong       (HR, FR-ATT-02)
--   SP-17 sp_dang_ky_ot          (nhan vien cho chinh minh, FR-ATT-03)
--   SP-06 sp_duyet_ot            (TP/HR theo muc 2.4, FR-ATT-04)
--   SP-07 sp_chot_cong           (HR, FR-ATT-05)
--
-- Thu tu khoa dong: KY_LUONG (pkg_chung.khoa_ky_mo) -> NHAN_VIEN -> ban ghi.
-- Moi duong ghi khoa dong ky cua thang lien quan, giong sp_chot_cong, nen khong
-- co du lieu moi chen vao trong luc chot cong kiem tra (TX-07, muc 8.5).
-- Ma loi -203xx. Khong COMMIT.
-- =============================================================================

create or replace package pkg_att
  authid definer
as
  -- p_sua FALSE: them ngay moi (trung ngay -> -20302); TRUE: sua ngay da co.
  -- Gio la gio thap phan trong ngay (13,5 = 13:30). p_gio_quy_doi NULL:
  -- LAM_VIEC = gio chuan, NGHI_TUAN = 0, LE = 8.
  procedure sp_luu_lich_lam_viec(
    p_ngay               in date,
    p_loai_ngay          in varchar2,
    p_gio_bat_dau_sang   in number   default null,
    p_gio_ket_thuc_sang  in number   default null,
    p_gio_bat_dau_chieu  in number   default null,
    p_gio_ket_thuc_chieu in number   default null,
    p_gio_quy_doi        in number   default null,
    p_ten_ngay_le        in varchar2 default null,
    p_sua                in boolean  default false);

  -- p_sua FALSE: them (trung nguoi/ngay -> -20304); TRUE: sua ban ghi da co
  procedure sp_luu_cham_cong(
    p_ma_nhan_vien in varchar2,
    p_ngay         in date,
    p_so_gio       in number,
    p_sua          in boolean default false);

  -- Nhan vien dang ky OT cho chinh minh; khoang [bat dau, ket thuc)
  procedure sp_dang_ky_ot(
    p_bat_dau  in  timestamp,
    p_ket_thuc in  timestamp,
    p_ly_do    in  varchar2,
    o_id       out number);

  -- p_ket_qua: DA_DUYET | TU_CHOI. p_so_gio_duyet NULL = ca khoang dang ky.
  procedure sp_duyet_ot(
    p_tang_ca_id   in number,
    p_ket_qua      in varchar2,
    p_so_gio_duyet in number default null);

  -- Chay QR-14 (thieu cong), QR-15 (cong + nghi vuot chuan), dem don cho.
  -- 0 loi: ky sang CHOT_CONG. Co loi: KHONG doi trang thai, tra so loi va danh
  -- sach tung dong (khong nem ngoai le, de giao dien hien danh sach).
  procedure sp_chot_cong(
    p_thang   in  number,
    p_nam     in  number,
    o_so_loi  out number,
    o_ds_loi  out clob);
end pkg_att;
/
show errors

create or replace package body pkg_att
as
  c_xa constant date := pkg_chung.c_ngay_xa;

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

  function lay_lich(p_ngay in date) return lich_lam_viec%rowtype
  is
    v lich_lam_viec%rowtype;
  begin
    select * into v from lich_lam_viec where ngay = trunc(p_ngay);
    return v;
  exception
    when no_data_found then
      raise_application_error(-20318, 'Ngày ' || to_char(p_ngay, 'DD/MM/YYYY') || ' chưa có trong lịch làm việc.');
  end lay_lich;

  procedure yeu_cau_dang_lam(p_nv in nhan_vien%rowtype, p_ngay in date)
  is
  begin
    if trunc(p_ngay) < p_nv.ngay_vao_lam or trunc(p_ngay) > nvl(p_nv.ngay_nghi_viec, c_xa) then
      raise_application_error(-20217, 'Ngày ' || to_char(p_ngay, 'DD/MM/YYYY')
        || ' nằm ngoài thời gian làm việc của nhân viên ' || p_nv.ma_nhan_vien || ' (BR-09).');
    end if;
  end yeu_cau_dang_lam;

  -- Gio nghi da duyet cua mot nguoi trong mot ngay (theo gio cua tung buoi)
  function gio_nghi_da_duyet(p_nv in number, p_ngay in date) return number
  is
    v number;
  begin
    select nvl(sum(case c.buoi when 'SANG' then l.gio_ket_thuc_sang - l.gio_bat_dau_sang
                               else l.gio_ket_thuc_chieu - l.gio_bat_dau_chieu end), 0)
      into v
      from chi_tiet_nghi_phep c
      join don_nghi_phep d on d.don_nghi_id = c.don_nghi_id and d.trang_thai = 'DA_DUYET'
      join lich_lam_viec l on l.ngay = c.ngay
     where c.nhan_vien_id = p_nv and c.ngay = trunc(p_ngay);
    return v;
  end gio_nghi_da_duyet;

  -- ===========================================================================
  -- SP-26
  -- ===========================================================================
  procedure sp_luu_lich_lam_viec(
    p_ngay               in date,
    p_loai_ngay          in varchar2,
    p_gio_bat_dau_sang   in number   default null,
    p_gio_ket_thuc_sang  in number   default null,
    p_gio_bat_dau_chieu  in number   default null,
    p_gio_ket_thuc_chieu in number   default null,
    p_gio_quy_doi        in number   default null,
    p_ten_ngay_le        in varchar2 default null,
    p_sua                in boolean  default false)
  is
    v_loai   varchar2(10) := upper(p_loai_ngay);
    v_chuan  number := nvl(p_gio_ket_thuc_sang - p_gio_bat_dau_sang, 0)
                     + nvl(p_gio_ket_thuc_chieu - p_gio_bat_dau_chieu, 0);
    v_qd     number;
    v_xung   number;
  begin
    savepoint sp_lich;
    pkg_chung.yeu_cau_vai_tro('HR');
    -- Lich doi thi Hc doi: khoa ky (phai con MO) va tang phien ban dau vao
    pkg_chung.khoa_ky_mo(p_ngay, p_ngay);
    pkg_payroll.danh_dau_tinh_lai(p_ngay, p_ngay);

    v_qd := nvl(p_gio_quy_doi, case v_loai when 'LAM_VIEC' then v_chuan when 'NGHI_TUAN' then 0 else 8 end);

    if p_sua then
      -- Khong de lich moi mau thuan voi cong/nghi da ghi cua ngay do (BR-11, BR-12)
      select count(*) into v_xung
        from cham_cong where ngay = trunc(p_ngay) and (v_loai <> 'LAM_VIEC' or so_gio_lam_thuc_te > v_chuan);
      select v_xung + count(*) into v_xung
        from chi_tiet_nghi_phep where ngay = trunc(p_ngay) and con_hieu_luc = 1 and v_loai <> 'LAM_VIEC';
      if v_xung > 0 then
        raise_application_error(-20303, 'Lịch mới mâu thuẫn với ' || v_xung || ' bản ghi công/nghỉ đã có của ngày này.');
      end if;

      update lich_lam_viec
         set loai_ngay = v_loai,
             gio_bat_dau_sang = p_gio_bat_dau_sang, gio_ket_thuc_sang = p_gio_ket_thuc_sang,
             gio_bat_dau_chieu = p_gio_bat_dau_chieu, gio_ket_thuc_chieu = p_gio_ket_thuc_chieu,
             gio_quy_doi_luong = v_qd, ten_ngay_le = p_ten_ngay_le
       where ngay = trunc(p_ngay);
      if sql%rowcount = 0 then
        raise_application_error(-20318, 'Ngày ' || to_char(p_ngay, 'DD/MM/YYYY') || ' chưa có trong lịch làm việc.');
      end if;
    else
      insert into lich_lam_viec (ngay, loai_ngay, gio_bat_dau_sang, gio_ket_thuc_sang,
                                 gio_bat_dau_chieu, gio_ket_thuc_chieu, gio_quy_doi_luong, ten_ngay_le)
      values (trunc(p_ngay), v_loai, p_gio_bat_dau_sang, p_gio_ket_thuc_sang,
              p_gio_bat_dau_chieu, p_gio_ket_thuc_chieu, v_qd, p_ten_ngay_le);
    end if;
  exception
    when others then
      rollback to sp_lich;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_lich_lam_viec;

  -- ===========================================================================
  -- SP-15
  -- ===========================================================================
  procedure sp_luu_cham_cong(
    p_ma_nhan_vien in varchar2,
    p_ngay         in date,
    p_so_gio       in number,
    p_sua          in boolean default false)
  is
    v_nv   nhan_vien%rowtype;
    v_lich lich_lam_viec%rowtype;
    v_nghi number;
  begin
    savepoint sp_cc;
    pkg_chung.yeu_cau_vai_tro('HR');
    pkg_chung.khoa_ky_mo(p_ngay, p_ngay);                     -- 1. KY_LUONG
    v_nv   := khoa_nhan_vien(id_nhan_vien(p_ma_nhan_vien));   -- 2. NHAN_VIEN
    yeu_cau_dang_lam(v_nv, p_ngay);
    v_lich := lay_lich(p_ngay);

    if v_lich.loai_ngay <> 'LAM_VIEC' then
      raise_application_error(-20305, 'Ngày ' || to_char(p_ngay, 'DD/MM/YYYY') || ' là ' || v_lich.loai_ngay
        || ': không nhập công (làm việc ngày này ghi bằng OT).');
    end if;
    if p_so_gio < 0 or p_so_gio > v_lich.so_gio_chuan then
      raise_application_error(-20306, 'Giờ công phải trong [0, ' || v_lich.so_gio_chuan || '] (BR-11).');
    end if;
    v_nghi := gio_nghi_da_duyet(v_nv.nhan_vien_id, p_ngay);
    if p_so_gio + v_nghi > v_lich.so_gio_chuan then
      raise_application_error(-20307, 'Giờ công ' || p_so_gio || ' + giờ nghỉ đã duyệt ' || v_nghi
        || ' vượt giờ chuẩn ' || v_lich.so_gio_chuan || ' (BR-12).');
    end if;

    if p_sua then
      update cham_cong
         set so_gio_lam_thuc_te = p_so_gio,
             trang_thai_xac_nhan = 'DA_XAC_NHAN', nguoi_xac_nhan = pkg_chung.tai_khoan
       where nhan_vien_id = v_nv.nhan_vien_id and ngay = trunc(p_ngay);
      if sql%rowcount = 0 then
        raise_application_error(-20319, 'Chưa có bản ghi công để sửa.');
      end if;
    else
      insert into cham_cong (nhan_vien_id, ngay, so_gio_lam_thuc_te, trang_thai_xac_nhan, nguoi_xac_nhan)
      values (v_nv.nhan_vien_id, trunc(p_ngay), p_so_gio, 'DA_XAC_NHAN', pkg_chung.tai_khoan);
    end if;
  exception
    when others then
      rollback to sp_cc;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_cham_cong;

  -- ===========================================================================
  -- SP-17
  -- ===========================================================================
  procedure sp_dang_ky_ot(
    p_bat_dau  in  timestamp,
    p_ket_thuc in  timestamp,
    p_ly_do    in  varchar2,
    o_id       out number)
  is
    v_nv_id number;
    v_nv    nhan_vien%rowtype;
    v_ngay  date := trunc(cast(p_bat_dau as date));
    v_lich  lich_lam_viec%rowtype;
    v_tu    number;   -- gio thap phan trong ngay
    v_den   number;
    v_chong number;
  begin
    savepoint sp_dk_ot;
    pkg_chung.yeu_cau_vai_tro('EMPLOYEE');
    v_nv_id := pkg_chung.nhan_vien;

    if p_ket_thuc <= p_bat_dau then
      raise_application_error(-20308, 'Giờ kết thúc OT phải sau giờ bắt đầu.');
    end if;

    pkg_chung.khoa_ky_mo(v_ngay, v_ngay);
    v_nv := khoa_nhan_vien(v_nv_id);
    yeu_cau_dang_lam(v_nv, v_ngay);
    v_lich := lay_lich(v_ngay);

    -- Ngoai gio lam thuong: [tu, den) khong giao buoi sang/chieu (BR-13)
    v_tu  := (cast(p_bat_dau  as date) - v_ngay) * 24;
    v_den := (cast(p_ket_thuc as date) - v_ngay) * 24;
    if (v_lich.gio_bat_dau_sang is not null and v_tu < v_lich.gio_ket_thuc_sang and v_lich.gio_bat_dau_sang < v_den)
       or (v_lich.gio_bat_dau_chieu is not null and v_tu < v_lich.gio_ket_thuc_chieu and v_lich.gio_bat_dau_chieu < v_den)
    then
      raise_application_error(-20310, 'Khoảng OT trùng giờ làm việc thường của ngày (BR-13).');
    end if;

    -- Khong chong khoang voi OT cho/da duyet cua chinh minh; [a, b) tiep giap duoc phep
    select count(*) into v_chong
      from dang_ky_tang_ca
     where nhan_vien_id = v_nv_id
       and trang_thai in ('CHO_DUYET', 'DA_DUYET')
       and bat_dau < p_ket_thuc and p_bat_dau < ket_thuc;
    if v_chong > 0 then
      raise_application_error(-20311, 'Khoảng OT chồng với đăng ký OT khác đang chờ hoặc đã duyệt (BR-13).');
    end if;

    insert into dang_ky_tang_ca (nhan_vien_id, bat_dau, ket_thuc, ly_do)
    values (v_nv_id, p_bat_dau, p_ket_thuc, p_ly_do)
    returning tang_ca_id into o_id;
  exception
    when others then
      rollback to sp_dk_ot;
      o_id := null;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_dang_ky_ot;

  -- ===========================================================================
  -- SP-06
  -- ===========================================================================
  procedure sp_duyet_ot(
    p_tang_ca_id   in number,
    p_ket_qua      in varchar2,
    p_so_gio_duyet in number default null)
  is
    v_ot      dang_ky_tang_ca%rowtype;
    v_nv      nhan_vien%rowtype;
    v_gio     number;
    v_cs      chinh_sach_luong%rowtype;
    v_ngay_da number;
    v_thang_da number;
    v_nam_da  number;
  begin
    savepoint sp_duyet_ot;
    pkg_chung.yeu_cau_vai_tro('MANAGER,HR');
    if upper(p_ket_qua) not in ('DA_DUYET', 'TU_CHOI') then
      raise_application_error(-20320, 'Kết quả duyệt phải là DA_DUYET hoặc TU_CHOI.');
    end if;

    begin
      select * into v_ot from dang_ky_tang_ca where tang_ca_id = p_tang_ca_id;
    exception
      when no_data_found then
        raise_application_error(-20321, 'Đăng ký OT không tồn tại.');
    end;

    pkg_chung.khoa_ky_mo(v_ot.ngay, v_ot.ngay);                 -- 1. KY_LUONG
    v_nv := khoa_nhan_vien(v_ot.nhan_vien_id);                  -- 2. NHAN_VIEN
    select * into v_ot from dang_ky_tang_ca where tang_ca_id = p_tang_ca_id for update;

    if v_ot.trang_thai <> 'CHO_DUYET' then
      raise_application_error(-20312, 'Đăng ký OT đã được xử lý (' || v_ot.trang_thai || ').');
    end if;
    if not fn_nguoi_duyet_hop_le(v_ot.nhan_vien_id, v_ot.ngay) then
      raise_application_error(-20313, 'Bạn không phải người duyệt hợp lệ của đăng ký này (mục 2.4, BR-15).');
    end if;

    if upper(p_ket_qua) = 'TU_CHOI' then
      update dang_ky_tang_ca
         set trang_thai = 'TU_CHOI', nguoi_duyet = pkg_chung.tai_khoan, thoi_diem_duyet = systimestamp
       where tang_ca_id = p_tang_ca_id;
      return;
    end if;

    v_gio := nvl(p_so_gio_duyet, (cast(v_ot.ket_thuc as date) - cast(v_ot.bat_dau as date)) * 24);

    -- Han muc OT ngay/thang/nam theo chinh sach hieu luc (BR-14); nhan vien da
    -- bi khoa dong nen hai phien duyet dong thoi khong cung vuot han muc
    begin
      select * into v_cs from chinh_sach_luong
       where v_ot.ngay between tu_ngay and nvl(den_ngay, c_xa);
    exception
      when no_data_found then
        raise_application_error(-20322, 'Chưa có chính sách lương hiệu lực cho ngày OT.');
    end;
    select nvl(sum(case when ngay = v_ot.ngay then so_gio_duoc_duyet end), 0),
           nvl(sum(case when trunc(ngay, 'MM') = trunc(v_ot.ngay, 'MM') then so_gio_duoc_duyet end), 0),
           nvl(sum(so_gio_duoc_duyet), 0)
      into v_ngay_da, v_thang_da, v_nam_da
      from dang_ky_tang_ca
     where nhan_vien_id = v_ot.nhan_vien_id
       and trang_thai = 'DA_DUYET'
       and trunc(ngay, 'YYYY') = trunc(v_ot.ngay, 'YYYY');
    if v_ngay_da + v_gio > v_cs.han_muc_ot_ngay
       or v_thang_da + v_gio > v_cs.han_muc_ot_thang
       or v_nam_da + v_gio > v_cs.han_muc_ot_nam then
      raise_application_error(-20314, 'Vượt hạn mức OT (ngày ' || v_cs.han_muc_ot_ngay || ', tháng '
        || v_cs.han_muc_ot_thang || ', năm ' || v_cs.han_muc_ot_nam || ' giờ) (BR-14).');
    end if;

    update dang_ky_tang_ca
       set trang_thai = 'DA_DUYET', so_gio_duoc_duyet = v_gio,
           nguoi_duyet = pkg_chung.tai_khoan, thoi_diem_duyet = systimestamp
     where tang_ca_id = p_tang_ca_id;   -- CK_OT_GIO_DUYET: gio duyet <= dang ky
  exception
    when others then
      rollback to sp_duyet_ot;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_duyet_ot;

  -- ===========================================================================
  -- SP-07
  -- ===========================================================================
  procedure sp_chot_cong(
    p_thang   in  number,
    p_nam     in  number,
    o_so_loi  out number,
    o_ds_loi  out clob)
  is
    v_ky   ky_luong%rowtype;
    v_tu   date := to_date(p_nam || '-' || p_thang || '-01', 'YYYY-MM-DD');
    v_den  date := last_day(to_date(p_nam || '-' || p_thang || '-01', 'YYYY-MM-DD'));
  begin
    savepoint sp_chot;
    pkg_chung.yeu_cau_vai_tro('HR');
    o_so_loi := 0;

    begin
      select * into v_ky from ky_luong where nam = p_nam and thang = p_thang for update;
    exception
      when no_data_found then
        raise_application_error(-20323, 'Chưa có kỳ lương ' || lpad(p_thang, 2, '0') || '/' || p_nam || '.');
    end;
    if v_ky.trang_thai <> 'MO' then
      raise_application_error(-20315, 'Kỳ đang ở trạng thái ' || v_ky.trang_thai || ', chỉ chốt công kỳ MO.');
    end if;

    for e in (
      -- QR-14: nguoi/ngay phai lam ma thieu ban ghi cong
      select 'THIEU_CONG' as loai, n.ma_nhan_vien, l.ngay, null as chi_tiet
        from nhan_vien n
        join lich_lam_viec l
          on l.loai_ngay = 'LAM_VIEC' and l.ngay between v_tu and v_den
         and l.ngay >= n.ngay_vao_lam and l.ngay <= nvl(n.ngay_nghi_viec, c_xa)
       where not exists (select 1 from cham_cong c where c.nhan_vien_id = n.nhan_vien_id and c.ngay = l.ngay)
      union all
      -- QR-15: cong + nghi da duyet vuot chuan ngay (BR-12)
      select 'CONG_NGHI_VUOT_CHUAN', n.ma_nhan_vien, c.ngay,
             'công ' || c.so_gio_lam_thuc_te || ' + nghỉ ' || x.gio_nghi || ' > chuẩn ' || l.so_gio_chuan
        from cham_cong c
        join nhan_vien n on n.nhan_vien_id = c.nhan_vien_id
        join lich_lam_viec l on l.ngay = c.ngay
        join (select ct.nhan_vien_id, ct.ngay,
                     sum(case ct.buoi when 'SANG' then l2.gio_ket_thuc_sang - l2.gio_bat_dau_sang
                                      else l2.gio_ket_thuc_chieu - l2.gio_bat_dau_chieu end) as gio_nghi
                from chi_tiet_nghi_phep ct
                join don_nghi_phep d on d.don_nghi_id = ct.don_nghi_id and d.trang_thai = 'DA_DUYET'
                join lich_lam_viec l2 on l2.ngay = ct.ngay
               group by ct.nhan_vien_id, ct.ngay) x
          on x.nhan_vien_id = c.nhan_vien_id and x.ngay = c.ngay
       where c.ngay between v_tu and v_den
         and c.so_gio_lam_thuc_te + x.gio_nghi > l.so_gio_chuan
      union all
      -- Don nghi con cho duyet trong ky
      select 'DON_NGHI_CHO_DUYET', n.ma_nhan_vien, min(ct.ngay), 'đơn ' || d.don_nghi_id
        from don_nghi_phep d
        join chi_tiet_nghi_phep ct on ct.don_nghi_id = d.don_nghi_id
        join nhan_vien n on n.nhan_vien_id = d.nhan_vien_id
       where d.trang_thai = 'CHO_DUYET' and ct.ngay between v_tu and v_den
       group by n.ma_nhan_vien, d.don_nghi_id
      union all
      -- OT con cho duyet trong ky
      select 'OT_CHO_DUYET', n.ma_nhan_vien, o.ngay, 'đăng ký OT ' || o.tang_ca_id
        from dang_ky_tang_ca o
        join nhan_vien n on n.nhan_vien_id = o.nhan_vien_id
       where o.trang_thai = 'CHO_DUYET' and o.ngay between v_tu and v_den
       order by 1, 2, 3)
    loop
      o_so_loi := o_so_loi + 1;
      o_ds_loi := o_ds_loi || e.loai || ' | ' || e.ma_nhan_vien || ' | '
                  || to_char(e.ngay, 'DD/MM/YYYY') || nvl2(e.chi_tiet, ' | ' || e.chi_tiet, '') || chr(10);
    end loop;

    if o_so_loi = 0 then
      update ky_luong
         set trang_thai = 'CHOT_CONG', nguoi_chot_cong = pkg_chung.tai_khoan, thoi_diem_chot_cong = systimestamp
       where ky_luong_id = v_ky.ky_luong_id;
    end if;
  exception
    when others then
      rollback to sp_chot;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_chot_cong;
end pkg_att;
/
show errors
