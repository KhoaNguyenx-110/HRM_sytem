-- =============================================================================
-- seed/perf/04_quyet_dinh_phat_sinh.sql - Phat sinh luong, khen thuong, ky luat
-- cho cac ky 04/2023 -> 12/2025 (ky 2026 da co du lieu demo).
--   * Ky 12 moi nam: thuong cuoi nam (THUONG) cho moi nguoi dang lam.
--   * Cac ky khac: ~25% nguoi-ky co ho tro cong tac (DIEU_CHINH_TANG),
--     ~5% co khau tru tam ung (KHAU_TRU). Tat ca DA_DUYET: U_PAY01 lap, U_HR01 duyet.
--   * Khen thuong giay khen (~40% nguoi/nam) va ky luat khien trach (~1/13 nguoi/nam):
--     chi de dat quy mo bang (muc 5.6), khong anh huong luong.
-- =============================================================================
set define off
whenever sqlerror exit failure rollback

insert into phat_sinh_luong (nhan_vien_id, ky_luong_id, loai_khoan_id, so_tien, chieu_dieu_chinh, can_cu,
                             nguoi_tao, trang_thai_duyet, nguoi_duyet)
with ky as (
  select ky_luong_id, thang, nam, to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD') as tu,
         months_between(to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD'), date '2023-04-01') as m
    from ky_luong
   where to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD') between date '2023-04-01' and date '2025-12-01'
),
x as (
  select n.nhan_vien_id as id, k.ky_luong_id, k.thang, k.nam,
         mod(n.nhan_vien_id * 11 + k.m * 29, 100) as h
    from nhan_vien n
    join ky k on n.ngay_vao_lam <= last_day(k.tu) and nvl(n.ngay_nghi_viec, date '9999-12-31') >= k.tu
)
select x.id, x.ky_luong_id, l.loai_khoan_id,
       case l.ma_khoan when 'THUONG'          then 3000000 + mod(x.id, 5) * 1000000
                       when 'DIEU_CHINH_TANG' then 300000 + mod(x.h, 8) * 100000
                       else 200000 end,
       case l.ma_khoan when 'KHAU_TRU' then 'GIAM' else 'TANG' end,
       case l.ma_khoan when 'THUONG'          then 'Thưởng cuối năm ' || x.nam
                       when 'DIEU_CHINH_TANG' then 'Hỗ trợ công tác phí tháng ' || x.thang || '/' || x.nam
                       else 'Khấu trừ tạm ứng tháng ' || x.thang || '/' || x.nam end,
       (select tai_khoan_id from tai_khoan where oracle_username = 'U_PAY01'),
       'DA_DUYET',
       (select tai_khoan_id from tai_khoan where oracle_username = 'U_HR01')
  from x
  join loai_khoan_luong l
    on l.ma_khoan = case when x.thang = 12 then 'THUONG'
                         when x.h < 25     then 'DIEU_CHINH_TANG'
                         when x.h < 30     then 'KHAU_TRU' end;

insert into khen_thuong (nhan_vien_id, so_quyet_dinh, ngay_quyet_dinh, ly_do, hinh_thuc,
                         nguoi_tao, trang_thai_duyet, nguoi_duyet, thoi_diem_duyet)
select n.nhan_vien_id, 'KT-' || y.nam || '-' || n.nhan_vien_id, to_date(y.nam || '-12-20', 'YYYY-MM-DD'),
       'Hoàn thành xuất sắc nhiệm vụ năm ' || y.nam, 'GIAY_KHEN',
       (select tai_khoan_id from tai_khoan where oracle_username = 'U_HR01'), 'DA_DUYET',
       (select tai_khoan_id from tai_khoan where oracle_username = 'U_HR02'),
       to_timestamp(y.nam || '-12-22 10:00', 'YYYY-MM-DD HH24:MI')
  from nhan_vien n
  join (select 2022 + level as nam from dual connect by level <= 3) y
    on n.ngay_vao_lam <= to_date(y.nam || '-12-20', 'YYYY-MM-DD')
   and nvl(n.ngay_nghi_viec, date '9999-12-31') >= to_date(y.nam || '-12-20', 'YYYY-MM-DD')
 where mod(n.nhan_vien_id + y.nam, 5) in (0, 1);

insert into ky_luat (nhan_vien_id, so_quyet_dinh, ngay_quyet_dinh, ly_do, hinh_thuc, nguoi_tao, nguoi_phe_duyet)
select n.nhan_vien_id, 'KL-' || y.nam || '-' || n.nhan_vien_id, to_date(y.nam || '-06-15', 'YYYY-MM-DD'),
       'Vi phạm nội quy giờ làm việc', 'KHIEN_TRACH',
       (select tai_khoan_id from tai_khoan where oracle_username = 'U_HR01'),
       (select tai_khoan_id from tai_khoan where oracle_username = 'U_TP_NS')
  from nhan_vien n
  join (select 2022 + level as nam from dual connect by level <= 3) y
    on n.ngay_vao_lam <= to_date(y.nam || '-06-15', 'YYYY-MM-DD')
   and nvl(n.ngay_nghi_viec, date '9999-12-31') >= to_date(y.nam || '-06-15', 'YYYY-MM-DD')
 where mod(n.nhan_vien_id * y.nam, 13) = 0;

commit;
