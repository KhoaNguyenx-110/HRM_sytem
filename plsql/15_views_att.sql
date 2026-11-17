-- =============================================================================
-- 15_views_att.sql - View giai doan 4b (dac ta muc 7.4)
-- Pham vi chung: HR (va PAYROLL voi VW-03) thay tat ca; truong phong thay nguoi
-- thuoc phong minh dang quan ly; nhan vien thay chinh minh.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Phong ban "hien tai" cua moi nhan vien (phan cong bat dau gan nhat den hom nay):
-- dung de xac dinh pham vi truong phong trong VW-02, VW-03.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- VW-02 vw_phep_con_lai: cap, dieu chinh, da dung, cho, con lai theo nam (FR-LEV-05)
-- Da dung / cho chi tinh loai nghi TRU_PHEP_NAM; moi buoi 0,5 ngay.
-- -----------------------------------------------------------------------------
create or replace view vw_phep_con_lai as
with pc as (
  select q.nhan_vien_id, q.phong_ban_id,
         row_number() over (partition by q.nhan_vien_id order by q.ngay_bat_dau desc) as rn
    from qua_trinh_cong_tac q
   where q.ngay_bat_dau <= trunc(sysdate)
),
su_dung as (
  select c.nhan_vien_id, extract(year from c.ngay) as nam,
         sum(case when d.trang_thai = 'DA_DUYET'  then 0.5 else 0 end) as da_dung,
         sum(case when d.trang_thai = 'CHO_DUYET' then 0.5 else 0 end) as cho_duyet
    from chi_tiet_nghi_phep c
    join don_nghi_phep d  on d.don_nghi_id = c.don_nghi_id
    join loai_nghi_phep t on t.loai_nghi_id = d.loai_nghi_id and t.tru_phep_nam
   group by c.nhan_vien_id, extract(year from c.ngay)
)
select n.ma_nhan_vien,
       n.ho_ten,
       b.ma_phong_ban,
       h.nam,
       h.so_ngay_duoc_cap,
       h.so_ngay_dieu_chinh,
       nvl(s.da_dung, 0)                                             as so_ngay_da_dung,
       nvl(s.cho_duyet, 0)                                           as so_ngay_cho_duyet,
       h.so_ngay_duoc_cap + h.so_ngay_dieu_chinh - nvl(s.da_dung, 0) as so_ngay_con_lai
  from han_muc_phep_nam h
  join nhan_vien n on n.nhan_vien_id = h.nhan_vien_id
  left join pc p on p.nhan_vien_id = n.nhan_vien_id and p.rn = 1
  left join phong_ban b on b.phong_ban_id = p.phong_ban_id
  left join su_dung s on s.nhan_vien_id = h.nhan_vien_id and s.nam = h.nam
 where fn_co_vai_tro('HR')
    or n.nhan_vien_id = fn_nhan_vien_hien_tai
    or (fn_co_vai_tro('MANAGER')
        and fn_truong_phong_tai_ngay(p.phong_ban_id, trunc(sysdate)) = fn_nhan_vien_hien_tai)
with read only;

comment on table vw_phep_con_lai is 'VW-02 Phép năm: cấp, điều chỉnh, đã dùng, chờ, còn lại';

-- -----------------------------------------------------------------------------
-- VW-03 vw_cong_thang: cong, nghi, OT theo nguoi / ky (FR-ATT-06, TC-24)
-- Chi OT DA_DUYET duoc cong; tach theo loai ngay. GIO_HUONG_LUONG = FN-02.
-- Pham vi truong phong: phong cua nguoi do vao ngay cuoi ky (hoac ngay nghi viec).
-- Toi uu GD 6 (TC-54): cong / nghi / OT lay bang OUTER APPLY voi dieu kien
-- "nhan vien = ... va ngay BETWEEN dau ky AND cuoi ky" de dung index
-- (nhan_vien_id, ngay); ban cu gom ca bang theo TRUNC(ngay, 'MM') roi noi, khong
-- dung duoc index theo khoang ngay (xem tests/perf/ket_qua/tc54_v1_*).
-- -----------------------------------------------------------------------------
create or replace view vw_cong_thang as
with ky as (
  select k.ky_luong_id, k.thang, k.nam, k.trang_thai,
         to_date(k.nam || '-' || k.thang || '-01', 'YYYY-MM-DD') as tu,
         last_day(to_date(k.nam || '-' || k.thang || '-01', 'YYYY-MM-DD')) as den
    from ky_luong k
),
nk as (
  select n.nhan_vien_id, n.ma_nhan_vien, n.ho_ten, k.*,
         (select q.phong_ban_id from qua_trinh_cong_tac q
           where q.nhan_vien_id = n.nhan_vien_id
             and least(k.den, nvl(n.ngay_nghi_viec, k.den)) between q.ngay_bat_dau and nvl(q.ngay_ket_thuc, date '9999-12-31')
           fetch first 1 row only) as phong_ban_id
    from nhan_vien n
    join ky k on n.ngay_vao_lam <= k.den and nvl(n.ngay_nghi_viec, k.den) >= k.tu
)
select nk.thang,
       nk.nam,
       nk.trang_thai                         as trang_thai_ky,
       nk.ma_nhan_vien,
       nk.ho_ten,
       b.ma_phong_ban,
       nvl(c.so_ngay_co_cong, 0)             as so_ngay_co_cong,
       nvl(c.gio_cong, 0)                    as gio_cong,
       nvl(g.ngay_nghi_huong_luong, 0)       as ngay_nghi_huong_luong,
       nvl(g.ngay_nghi_khong_luong, 0)       as ngay_nghi_khong_luong,
       fn_gio_huong_luong(nk.nhan_vien_id, nk.ky_luong_id) as gio_huong_luong,
       nvl(o.ot_ngay_thuong, 0)              as ot_ngay_thuong,
       nvl(o.ot_nghi_tuan, 0)                as ot_nghi_tuan,
       nvl(o.ot_le, 0)                       as ot_le
  from nk
  left join phong_ban b on b.phong_ban_id = nk.phong_ban_id
  -- Ham gop khong GROUP BY luon tra 1 dong (khong co du lieu -> COUNT 0, SUM NULL)
  outer apply (
    select count(*) as so_ngay_co_cong, sum(c.so_gio_lam_thuc_te) as gio_cong
      from cham_cong c
     where c.nhan_vien_id = nk.nhan_vien_id and c.ngay between nk.tu and nk.den) c
  outer apply (
    select sum(case when t.huong_luong_doanh_nghiep then 0.5 else 0 end)     as ngay_nghi_huong_luong,
           sum(case when not t.huong_luong_doanh_nghiep then 0.5 else 0 end) as ngay_nghi_khong_luong
      from chi_tiet_nghi_phep ct
      join don_nghi_phep d  on d.don_nghi_id = ct.don_nghi_id and d.trang_thai = 'DA_DUYET'
      join loai_nghi_phep t on t.loai_nghi_id = d.loai_nghi_id
     where ct.nhan_vien_id = nk.nhan_vien_id and ct.ngay between nk.tu and nk.den) g
  outer apply (
    select sum(case when l.loai_ngay = 'LAM_VIEC'  then o.so_gio_duoc_duyet else 0 end) as ot_ngay_thuong,
           sum(case when l.loai_ngay = 'NGHI_TUAN' then o.so_gio_duoc_duyet else 0 end) as ot_nghi_tuan,
           sum(case when l.loai_ngay = 'LE'        then o.so_gio_duoc_duyet else 0 end) as ot_le
      from dang_ky_tang_ca o
      join lich_lam_viec l on l.ngay = o.ngay
     where o.nhan_vien_id = nk.nhan_vien_id and o.trang_thai = 'DA_DUYET'
       and o.ngay between nk.tu and nk.den) o
 where fn_co_vai_tro('HR') or fn_co_vai_tro('PAYROLL')
    or nk.nhan_vien_id = fn_nhan_vien_hien_tai
    or (fn_co_vai_tro('MANAGER')
        and fn_truong_phong_tai_ngay(nk.phong_ban_id, trunc(sysdate)) = fn_nhan_vien_hien_tai)
with read only;

comment on table vw_cong_thang is 'VW-03 Công, nghỉ, OT theo người và kỳ';

-- -----------------------------------------------------------------------------
-- VW-08 vw_don_cho_duyet: don nghi, OT, quyet dinh khen thuong ma nguoi dang
-- nhap la nguoi duyet hop le theo muc 2.4 (QR-09). Phong chua co truong phong:
-- don hien cho HR.
-- -----------------------------------------------------------------------------
create or replace view vw_don_cho_duyet as
select 'NGHI_PHEP'          as loai_yeu_cau,
       d.don_nghi_id        as ma_yeu_cau,
       n.ma_nhan_vien,
       n.ho_ten,
       t.ten_loai           as noi_dung,
       x.tu_ngay,
       x.den_ngay,
       x.so_buoi            as so_luong,
       d.ly_do,
       d.thoi_diem_tao
  from don_nghi_phep d
  join nhan_vien n      on n.nhan_vien_id = d.nhan_vien_id
  join loai_nghi_phep t on t.loai_nghi_id = d.loai_nghi_id
  join (select don_nghi_id, min(ngay) as tu_ngay, max(ngay) as den_ngay, count(*) as so_buoi
          from chi_tiet_nghi_phep group by don_nghi_id) x on x.don_nghi_id = d.don_nghi_id
 where d.trang_thai = 'CHO_DUYET'
   and fn_nguoi_duyet_hop_le(d.nhan_vien_id, x.tu_ngay)
union all
select 'OT',
       o.tang_ca_id,
       n.ma_nhan_vien,
       n.ho_ten,
       to_char(o.bat_dau, 'HH24:MI') || '-' || to_char(o.ket_thuc, 'HH24:MI'),
       o.ngay,
       o.ngay,
       round((cast(o.ket_thuc as date) - cast(o.bat_dau as date)) * 24, 2),
       o.ly_do,
       null
  from dang_ky_tang_ca o
  join nhan_vien n on n.nhan_vien_id = o.nhan_vien_id
 where o.trang_thai = 'CHO_DUYET'
   and fn_nguoi_duyet_hop_le(o.nhan_vien_id, o.ngay)
union all
select 'KHEN_THUONG',
       k.khen_thuong_id,
       n.ma_nhan_vien,
       n.ho_ten,
       k.so_quyet_dinh || ' - ' || k.hinh_thuc,
       k.ngay_quyet_dinh,
       k.ngay_quyet_dinh,
       k.so_tien,
       k.ly_do,
       null
  from khen_thuong k
  join nhan_vien n on n.nhan_vien_id = k.nhan_vien_id
 where k.trang_thai_duyet = 'CHO_DUYET'
   and fn_co_vai_tro('HR')
   and k.nguoi_tao <> nvl(fn_tai_khoan_hien_tai, -1)
   and k.nhan_vien_id <> nvl(fn_nhan_vien_hien_tai, -1)
union all
-- Phat sinh luong do Payroll lap, HR duyet (bo sung giai doan 4c)
select 'PHAT_SINH_LUONG',
       s.phat_sinh_id,
       n.ma_nhan_vien,
       n.ho_ten,
       l.ma_khoan || ' ' || s.chieu_dieu_chinh || ' kỳ ' || lpad(k.thang, 2, '0') || '/' || k.nam,
       to_date(k.nam || '-' || k.thang || '-01', 'YYYY-MM-DD'),
       last_day(to_date(k.nam || '-' || k.thang || '-01', 'YYYY-MM-DD')),
       s.so_tien,
       s.can_cu,
       null
  from phat_sinh_luong s
  join nhan_vien n        on n.nhan_vien_id  = s.nhan_vien_id
  join ky_luong k         on k.ky_luong_id   = s.ky_luong_id
  join loai_khoan_luong l on l.loai_khoan_id = s.loai_khoan_id
 where s.trang_thai_duyet = 'CHO_DUYET'
   and k.trang_thai <> 'DA_KHOA'
   and fn_co_vai_tro('HR')
   and s.nguoi_tao <> nvl(fn_tai_khoan_hien_tai, -1)
   and s.nhan_vien_id <> nvl(fn_nhan_vien_hien_tai, -1)
with read only;

comment on table vw_don_cho_duyet is 'VW-08 Đơn nghỉ, OT, quyết định mà người đăng nhập là người duyệt hợp lệ';

-- -----------------------------------------------------------------------------
-- VW-11 vw_yeu_cau_cua_toi (BO SUNG so voi dac ta v2.0): don nghi va dang ky OT
-- cua chinh nguoi dang nhap, kem trang thai. Can de nhan vien biet ma don khi rut
-- (FR-LEV-03) va de giao dien hien danh sach yeu cau cua toi.
-- -----------------------------------------------------------------------------
create or replace view vw_yeu_cau_cua_toi as
select 'NGHI_PHEP'      as loai_yeu_cau,
       d.don_nghi_id    as ma_yeu_cau,
       t.ten_loai       as noi_dung,
       x.tu_ngay,
       x.den_ngay,
       x.so_buoi        as so_luong,
       d.trang_thai,
       d.ly_do,
       d.thoi_diem_tao
  from don_nghi_phep d
  join loai_nghi_phep t on t.loai_nghi_id = d.loai_nghi_id
  join (select don_nghi_id, min(ngay) as tu_ngay, max(ngay) as den_ngay, count(*) as so_buoi
          from chi_tiet_nghi_phep group by don_nghi_id) x on x.don_nghi_id = d.don_nghi_id
 where d.nhan_vien_id = fn_nhan_vien_hien_tai
union all
select 'OT',
       o.tang_ca_id,
       to_char(o.bat_dau, 'HH24:MI') || '-' || to_char(o.ket_thuc, 'HH24:MI'),
       o.ngay,
       o.ngay,
       nvl(o.so_gio_duoc_duyet, round((cast(o.ket_thuc as date) - cast(o.bat_dau as date)) * 24, 2)),
       o.trang_thai,
       o.ly_do,
       null
  from dang_ky_tang_ca o
 where o.nhan_vien_id = fn_nhan_vien_hien_tai
with read only;

comment on table vw_yeu_cau_cua_toi is 'VW-11 Đơn nghỉ và đăng ký OT của chính người đăng nhập (bổ sung)';
