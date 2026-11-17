-- =============================================================================
-- 11_fn_att.sql - Ham cho cong, OT, nghi phep (dac ta muc 2.4, 7.2)
--   fn_nguoi_duyet_hop_le : quy tac nguoi duyet muc 2.4 (dung chung pkg_att,
--                           pkg_leave va VW-08)
--   FN-02 fn_gio_huong_luong : Hh cua mot nguoi trong mot ky
--   FN-03 fn_phep_con_lai    : cap + dieu chinh - da duyet
-- Ham khong ghi du lieu.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Phien hien tai co phai nguoi duyet hop le cho yeu cau cua p_nhan_vien_gui,
-- tinh theo du lieu tai p_ngay (ngay dau tien cua yeu cau)?
--   Nguoi gui co vai tro HR          -> HR khac nguoi gui
--   Nguoi gui giu chuc vu quan ly    -> moi HR
--   Nhan vien thuong                 -> truong phong cua phong nguoi gui tai p_ngay,
--                                       va hom nay van la truong phong phong do;
--                                       phong chua co truong phong -> moi HR
--   Khong ai duyet yeu cau cua chinh minh (BR-15).
-- -----------------------------------------------------------------------------
create or replace function fn_nguoi_duyet_hop_le(
  p_nhan_vien_gui in number,
  p_ngay          in date)
  return boolean
  authid definer
is
  v_nv_me  number := fn_nhan_vien_hien_tai;
  v_hr_gui number;
  v_pb     number;
  v_ql     boolean;
  v_tp     number;
begin
  if fn_tai_khoan_hien_tai is null then
    return false;
  end if;
  if v_nv_me = p_nhan_vien_gui then
    return false;
  end if;

  select count(*) into v_hr_gui
    from tai_khoan t
    join tai_khoan_vai_tro tv on tv.tai_khoan_id = t.tai_khoan_id
    join vai_tro r on r.vai_tro_id = tv.vai_tro_id
   where t.nhan_vien_id = p_nhan_vien_gui and r.ma_vai_tro = 'HR';
  if v_hr_gui > 0 then
    return fn_co_vai_tro('HR');
  end if;

  begin
    select q.phong_ban_id, c.la_quan_ly into v_pb, v_ql
      from qua_trinh_cong_tac q join chuc_vu c on c.chuc_vu_id = q.chuc_vu_id
     where q.nhan_vien_id = p_nhan_vien_gui
       and trunc(p_ngay) between q.ngay_bat_dau and nvl(q.ngay_ket_thuc, date '9999-12-31');
  exception
    when no_data_found then
      return fn_co_vai_tro('HR');
  end;

  if v_ql then
    return fn_co_vai_tro('HR');
  end if;

  v_tp := fn_truong_phong_tai_ngay(v_pb, p_ngay);
  if v_tp is null then
    return fn_co_vai_tro('HR');
  end if;

  return v_tp = v_nv_me
     and fn_co_vai_tro('MANAGER')
     and fn_truong_phong_tai_ngay(v_pb, trunc(sysdate)) = v_nv_me;
end;
/
show errors

-- -----------------------------------------------------------------------------
-- FN-02: gio huong luong Hh = gio lam thuc te + gio nghi co huong luong doanh
-- nghiep + gio quy doi ngay le, trong thoi gian lam viec cua nguoi do trong ky.
-- Nghi tuan khong cong (muc 9.2). OT khong cong vao Hh.
-- -----------------------------------------------------------------------------
create or replace function fn_gio_huong_luong(
  p_nhan_vien_id in number,
  p_ky_luong_id  in number)
  return number
  authid definer
is
  v_tu    date;
  v_den   date;
  v_cong  number;
  v_nghi  number;
  v_le    number;
begin
  select greatest(to_date(k.nam || '-' || k.thang || '-01', 'YYYY-MM-DD'), n.ngay_vao_lam),
         least(last_day(to_date(k.nam || '-' || k.thang || '-01', 'YYYY-MM-DD')),
               nvl(n.ngay_nghi_viec, date '9999-12-31'))
    into v_tu, v_den
    from ky_luong k, nhan_vien n
   where k.ky_luong_id = p_ky_luong_id and n.nhan_vien_id = p_nhan_vien_id;

  if v_tu > v_den then
    return 0;
  end if;

  select nvl(sum(so_gio_lam_thuc_te), 0) into v_cong
    from cham_cong
   where nhan_vien_id = p_nhan_vien_id and ngay between v_tu and v_den;

  select nvl(sum(case c.buoi when 'SANG' then l.gio_ket_thuc_sang - l.gio_bat_dau_sang
                             else l.gio_ket_thuc_chieu - l.gio_bat_dau_chieu end), 0)
    into v_nghi
    from chi_tiet_nghi_phep c
    join don_nghi_phep d  on d.don_nghi_id = c.don_nghi_id and d.trang_thai = 'DA_DUYET'
    join loai_nghi_phep t on t.loai_nghi_id = d.loai_nghi_id and t.huong_luong_doanh_nghiep
    join lich_lam_viec l  on l.ngay = c.ngay
   where c.nhan_vien_id = p_nhan_vien_id and c.ngay between v_tu and v_den;

  select nvl(sum(gio_quy_doi_luong), 0) into v_le
    from lich_lam_viec
   where loai_ngay = 'LE' and ngay between v_tu and v_den;

  return v_cong + v_nghi + v_le;
end;
/
show errors

-- -----------------------------------------------------------------------------
-- FN-03: phep nam con lai = cap + dieu chinh - so ngay da duyet cua loai tru phep
-- (moi buoi 0,5 ngay). NULL neu chua co han muc nam do.
-- Chi de tra cuu: khong thay buoc khoa dong va tinh lai khi duyet (muc 7.2).
-- -----------------------------------------------------------------------------
create or replace function fn_phep_con_lai(
  p_nhan_vien_id in number,
  p_nam          in number)
  return number
  authid definer
is
  v_han_muc number;
  v_da_dung number;
begin
  select so_ngay_duoc_cap + so_ngay_dieu_chinh into v_han_muc
    from han_muc_phep_nam where nhan_vien_id = p_nhan_vien_id and nam = p_nam;

  select nvl(count(*) * 0.5, 0) into v_da_dung
    from chi_tiet_nghi_phep c
    join don_nghi_phep d  on d.don_nghi_id = c.don_nghi_id and d.trang_thai = 'DA_DUYET'
    join loai_nghi_phep t on t.loai_nghi_id = d.loai_nghi_id and t.tru_phep_nam
   where c.nhan_vien_id = p_nhan_vien_id
     -- khoang ngay (khong boc ham cot ngay) de dung IX-17 (TC-54)
     and c.ngay >= to_date(p_nam || '-01-01', 'YYYY-MM-DD')
     and c.ngay <  to_date((p_nam + 1) || '-01-01', 'YYYY-MM-DD');

  return v_han_muc - v_da_dung;
exception
  when no_data_found then
    return null;
end;
/
show errors
