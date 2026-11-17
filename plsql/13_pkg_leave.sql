-- =============================================================================
-- 13_pkg_leave.sql - Nghi phep
--   SP-16 sp_luu_han_muc_phep  (HR, FR-LEV-01)
--   SP-04 sp_dang_ky_nghi      (nhan vien cho chinh minh, FR-LEV-02)
--   SP-05 sp_xu_ly_don_nghi    (DUYET/TU_CHOI: TP/HR theo muc 2.4; RUT: chu don;
--                               FR-LEV-03, FR-LEV-04)
--
-- Duyet don (TX-02) khoa dong theo thu tu: KY_LUONG cac thang cua don (tang dan)
-- -> NHAN_VIEN -> HAN_MUC_PHEP_NAM (nam tang dan) -> don. So du duoc tinh lai SAU
-- khi khoa, nen hai phien duyet dong thoi khong cung vuot han muc (BR-17, TC-28).
-- Moi buoi nghi = 0,5 ngay. Don qua hai nam kiem tra han muc tung nam.
-- Ma loi -204xx. Khong COMMIT.
-- =============================================================================

create or replace package pkg_leave
  authid definer
as
  -- p_sua FALSE: cap moi (trung nguoi/nam -> -20401); TRUE: dieu chinh han muc da co
  procedure sp_luu_han_muc_phep(
    p_ma_nhan_vien       in varchar2,
    p_nam                in number,
    p_so_ngay_duoc_cap   in number,
    p_so_ngay_dieu_chinh in number   default 0,
    p_can_cu_dieu_chinh  in varchar2 default null,
    p_sua                in boolean  default false);

  -- Chi lay cac ngay LAM_VIEC trong [tu, den]; p_buoi: CA_NGAY | SANG | CHIEU
  procedure sp_dang_ky_nghi(
    p_ma_loai  in  varchar2,
    p_tu_ngay  in  date,
    p_den_ngay in  date,
    p_buoi     in  varchar2,
    p_ly_do    in  varchar2,
    o_don_id   out number);

  -- p_hanh_dong: DUYET | TU_CHOI (bat buoc y kien) | RUT (chi chu don, don CHO_DUYET)
  procedure sp_xu_ly_don_nghi(
    p_don_nghi_id in number,
    p_hanh_dong   in varchar2,
    p_y_kien      in varchar2 default null);
end pkg_leave;
/
show errors

create or replace package body pkg_leave
as
  c_xa constant date := pkg_chung.c_ngay_xa;

  function so_ngay_da_duyet(p_nv in number, p_nam in number, p_tru_don in number default null) return number
  is
    v number;
  begin
    select count(*) * 0.5 into v
      from chi_tiet_nghi_phep c
      join don_nghi_phep d  on d.don_nghi_id = c.don_nghi_id and d.trang_thai = 'DA_DUYET'
      join loai_nghi_phep t on t.loai_nghi_id = d.loai_nghi_id and t.tru_phep_nam
     where c.nhan_vien_id = p_nv
       -- khoang ngay (khong boc ham cot ngay) de dung IX-17 (TC-54)
       and c.ngay >= to_date(p_nam || '-01-01', 'YYYY-MM-DD')
       and c.ngay <  to_date((p_nam + 1) || '-01-01', 'YYYY-MM-DD')
       and d.don_nghi_id <> nvl(p_tru_don, -1);
    return v;
  end so_ngay_da_duyet;

  -- ===========================================================================
  -- SP-16
  -- ===========================================================================
  procedure sp_luu_han_muc_phep(
    p_ma_nhan_vien       in varchar2,
    p_nam                in number,
    p_so_ngay_duoc_cap   in number,
    p_so_ngay_dieu_chinh in number   default 0,
    p_can_cu_dieu_chinh  in varchar2 default null,
    p_sua                in boolean  default false)
  is
    v_nv    number;
    v_dung  number;
  begin
    savepoint sp_hm;
    pkg_chung.yeu_cau_vai_tro('HR');
    begin
      select nhan_vien_id into v_nv from nhan_vien where ma_nhan_vien = upper(p_ma_nhan_vien) for update;
    exception
      when no_data_found then
        raise_application_error(-20216, 'Nhân viên "' || p_ma_nhan_vien || '" không tồn tại.');
    end;

    if p_sua then
      update han_muc_phep_nam
         set so_ngay_duoc_cap = p_so_ngay_duoc_cap,
             so_ngay_dieu_chinh = p_so_ngay_dieu_chinh,
             can_cu_dieu_chinh = p_can_cu_dieu_chinh
       where nhan_vien_id = v_nv and nam = p_nam;
      if sql%rowcount = 0 then
        raise_application_error(-20410, 'Nhân viên chưa có hạn mức phép năm ' || p_nam || '.');
      end if;
      -- Khong giam duoi so ngay da duyet (FR-LEV-01, TC-25)
      v_dung := so_ngay_da_duyet(v_nv, p_nam);
      if p_so_ngay_duoc_cap + p_so_ngay_dieu_chinh < v_dung then
        raise_application_error(-20402, 'Hạn mức mới thấp hơn ' || v_dung || ' ngày phép đã duyệt.');
      end if;
    else
      insert into han_muc_phep_nam (nhan_vien_id, nam, so_ngay_duoc_cap, so_ngay_dieu_chinh, can_cu_dieu_chinh)
      values (v_nv, p_nam, p_so_ngay_duoc_cap, p_so_ngay_dieu_chinh, p_can_cu_dieu_chinh);
    end if;
  exception
    when others then
      rollback to sp_hm;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_han_muc_phep;

  -- ===========================================================================
  -- SP-04
  -- ===========================================================================
  procedure sp_dang_ky_nghi(
    p_ma_loai  in  varchar2,
    p_tu_ngay  in  date,
    p_den_ngay in  date,
    p_buoi     in  varchar2,
    p_ly_do    in  varchar2,
    o_don_id   out number)
  is
    v_nv_id  number;
    v_nv     nhan_vien%rowtype;
    v_loai   number;
    v_buoi   varchar2(10) := upper(p_buoi);
    v_so     number;
  begin
    savepoint sp_dk_nghi;
    pkg_chung.yeu_cau_vai_tro('EMPLOYEE');
    v_nv_id := pkg_chung.nhan_vien;

    if p_den_ngay < p_tu_ngay or v_buoi not in ('CA_NGAY', 'SANG', 'CHIEU') then
      raise_application_error(-20403, 'Khoảng ngày hoặc buổi nghỉ không hợp lệ.');
    end if;
    begin
      select loai_nghi_id into v_loai from loai_nghi_phep where ma_loai = upper(p_ma_loai);
    exception
      when no_data_found then
        raise_application_error(-20403, 'Loại nghỉ "' || p_ma_loai || '" không tồn tại.');
    end;

    -- Ky cua moi thang trong don phai con MO, neu khong tu choi toan don (TC-26)
    pkg_chung.khoa_ky_mo(p_tu_ngay, p_den_ngay);
    select * into v_nv from nhan_vien where nhan_vien_id = v_nv_id for update;
    if trunc(p_tu_ngay) < v_nv.ngay_vao_lam or trunc(p_den_ngay) > nvl(v_nv.ngay_nghi_viec, c_xa) then
      raise_application_error(-20217, 'Khoảng nghỉ nằm ngoài thời gian làm việc (BR-09).');
    end if;

    insert into don_nghi_phep (nhan_vien_id, loai_nghi_id, ly_do)
    values (v_nv_id, v_loai, p_ly_do)
    returning don_nghi_id into o_don_id;

    -- Chi buoi co gio chuan trong lich; IX-14 chan trung buoi voi don cho/da duyet
    insert into chi_tiet_nghi_phep (don_nghi_id, ngay, buoi, nhan_vien_id, con_hieu_luc)
    select o_don_id, l.ngay, b.buoi, v_nv_id, 1
      from lich_lam_viec l
     cross join (select 'SANG' as buoi from dual union all select 'CHIEU' from dual) b
     where l.ngay between trunc(p_tu_ngay) and trunc(p_den_ngay)
       and l.loai_ngay = 'LAM_VIEC'
       and (v_buoi = 'CA_NGAY' or b.buoi = v_buoi)
       and ((b.buoi = 'SANG' and l.gio_bat_dau_sang is not null)
         or (b.buoi = 'CHIEU' and l.gio_bat_dau_chieu is not null));
    v_so := sql%rowcount;
    if v_so = 0 then
      raise_application_error(-20403, 'Khoảng đăng ký không có buổi làm việc nào (ngày nghỉ tuần hoặc lễ).');
    end if;

    insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly)
    values (o_don_id, 'GUI', pkg_chung.tai_khoan);
  exception
    when others then
      rollback to sp_dk_nghi;
      o_don_id := null;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_dang_ky_nghi;

  -- ===========================================================================
  -- SP-05
  -- ===========================================================================
  procedure sp_xu_ly_don_nghi(
    p_don_nghi_id in number,
    p_hanh_dong   in varchar2,
    p_y_kien      in varchar2 default null)
  is
    v_hd       varchar2(10) := upper(p_hanh_dong);
    v_don      don_nghi_phep%rowtype;
    v_tu       date;
    v_den      date;
    v_tru_phep boolean;
    v_dung     number;
    v_han_muc  number;
    v_xung     number;
  begin
    savepoint sp_xu_ly;
    if v_hd not in ('DUYET', 'TU_CHOI', 'RUT') then
      raise_application_error(-20413, 'Hành động phải là DUYET, TU_CHOI hoặc RUT.');
    end if;
    pkg_chung.yeu_cau_vai_tro(case when v_hd = 'RUT' then 'EMPLOYEE' else 'MANAGER,HR' end);

    begin
      select * into v_don from don_nghi_phep where don_nghi_id = p_don_nghi_id;
    exception
      when no_data_found then
        raise_application_error(-20414, 'Đơn nghỉ không tồn tại.');
    end;
    select min(ngay), max(ngay) into v_tu, v_den from chi_tiet_nghi_phep where don_nghi_id = p_don_nghi_id;

    -- TX-02: KY_LUONG -> NHAN_VIEN -> HAN_MUC_PHEP_NAM -> DON
    pkg_chung.khoa_ky_mo(v_tu, v_den);
    select nhan_vien_id into v_xung from nhan_vien where nhan_vien_id = v_don.nhan_vien_id for update;
    for h in (select nam from han_muc_phep_nam
               where nhan_vien_id = v_don.nhan_vien_id
                 and nam between extract(year from v_tu) and extract(year from v_den)
               order by nam for update) loop
      null;
    end loop;
    select * into v_don from don_nghi_phep where don_nghi_id = p_don_nghi_id for update;

    if v_don.trang_thai <> 'CHO_DUYET' then
      raise_application_error(-20406, 'Chỉ xử lý đơn đang chờ duyệt; đơn này ' || v_don.trang_thai || ' (BR-18).');
    end if;

    if v_hd = 'RUT' then
      if v_don.nhan_vien_id <> pkg_chung.nhan_vien then
        raise_application_error(-20405, 'Chỉ chủ đơn được rút đơn (BR-18).');
      end if;
    else
      if not fn_nguoi_duyet_hop_le(v_don.nhan_vien_id, v_tu) then
        raise_application_error(-20407, 'Bạn không phải người duyệt hợp lệ của đơn này (mục 2.4, BR-15).');
      end if;
      if v_hd = 'TU_CHOI' and trim(p_y_kien) is null then
        raise_application_error(-20408, 'Từ chối đơn phải ghi lý do.');
      end if;
    end if;

    if v_hd = 'DUYET' then
      -- BR-17: so du tinh lai sau khi khoa, tung nam cua don
      select tru_phep_nam into v_tru_phep from loai_nghi_phep where loai_nghi_id = v_don.loai_nghi_id;
      if v_tru_phep then
        for y in (select extract(year from ngay) as nam, count(*) * 0.5 as so_ngay
                    from chi_tiet_nghi_phep where don_nghi_id = p_don_nghi_id
                   group by extract(year from ngay)) loop
          begin
            select so_ngay_duoc_cap + so_ngay_dieu_chinh into v_han_muc
              from han_muc_phep_nam where nhan_vien_id = v_don.nhan_vien_id and nam = y.nam;
          exception
            when no_data_found then
              raise_application_error(-20410, 'Nhân viên chưa có hạn mức phép năm ' || y.nam || '.');
          end;
          v_dung := so_ngay_da_duyet(v_don.nhan_vien_id, y.nam);
          if v_dung + y.so_ngay > v_han_muc then
            raise_application_error(-20409, 'Không đủ phép năm ' || y.nam || ': hạn mức ' || v_han_muc
              || ', đã duyệt ' || v_dung || ', đơn này ' || y.so_ngay || ' ngày (BR-17).');
          end if;
        end loop;
      end if;

      -- BR-12: cong da ghi + nghi khong vuot chuan ngay
      select count(*) into v_xung
        from (select ct.ngay, sum(case ct.buoi when 'SANG' then l.gio_ket_thuc_sang - l.gio_bat_dau_sang
                                               else l.gio_ket_thuc_chieu - l.gio_bat_dau_chieu end) as gio_nghi
                from chi_tiet_nghi_phep ct
                join lich_lam_viec l on l.ngay = ct.ngay
                left join don_nghi_phep d on d.don_nghi_id = ct.don_nghi_id
               where ct.nhan_vien_id = v_don.nhan_vien_id
                 and ct.ngay in (select ngay from chi_tiet_nghi_phep where don_nghi_id = p_don_nghi_id)
                 and (ct.don_nghi_id = p_don_nghi_id or d.trang_thai = 'DA_DUYET')
               group by ct.ngay) x
        join cham_cong c on c.nhan_vien_id = v_don.nhan_vien_id and c.ngay = x.ngay
        join lich_lam_viec l on l.ngay = x.ngay
       where c.so_gio_lam_thuc_te + x.gio_nghi > l.so_gio_chuan;
      if v_xung > 0 then
        raise_application_error(-20411, 'Có ' || v_xung || ' ngày công đã ghi cộng giờ nghỉ vượt chuẩn; '
          || 'HR cần sửa công trước khi duyệt (BR-12).');
      end if;

      update don_nghi_phep
         set trang_thai = 'DA_DUYET', nguoi_duyet = pkg_chung.tai_khoan, thoi_diem_duyet = systimestamp
       where don_nghi_id = p_don_nghi_id;
      insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, y_kien)
      values (p_don_nghi_id, 'DUYET', pkg_chung.tai_khoan, p_y_kien);

    else
      -- TU_CHOI / RUT: giai phong cac buoi khoi IX-14 (CON_HIEU_LUC = 0)
      update don_nghi_phep
         set trang_thai      = case v_hd when 'TU_CHOI' then 'TU_CHOI' else 'DA_RUT' end,
             nguoi_duyet     = case v_hd when 'TU_CHOI' then pkg_chung.tai_khoan end,
             thoi_diem_duyet = case v_hd when 'TU_CHOI' then systimestamp end
       where don_nghi_id = p_don_nghi_id;
      update chi_tiet_nghi_phep set con_hieu_luc = 0 where don_nghi_id = p_don_nghi_id;
      insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, y_kien)
      values (p_don_nghi_id, v_hd, pkg_chung.tai_khoan, p_y_kien);
    end if;
  exception
    when others then
      rollback to sp_xu_ly;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_xu_ly_don_nghi;
end pkg_leave;
/
show errors
