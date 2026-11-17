-- =============================================================================
-- QR-14 Thieu cham cong: nguoi/ngay phai lam ma khong co ban ghi cong
--   Nguon: day la truy van kiem tra BEN TRONG pkg_att.sp_chot_cong (SP-07). Nguoi
--   dung nghiep vu xem ket qua qua o_ds_loi cua sp_chot_cong; file nay chay bang
--   HRM_OWNER de nop cau SQL va ket qua mau.
--   Dau vao: :p_nam, :p_thang
--   Ky thuat: CTE (ngay phai lam = ngay LAM_VIEC trong thoi gian lam viec), NOT EXISTS
--   Du lieu mau co cong den het 03/2026, nen ky 04/2026 cho ket qua; ky 01-03 = 0 dong.
-- Chay: scripts/run.sh owner queries/qr14_thieu_cham_cong.sql
-- =============================================================================
@@_dinh_dang.sql
variable p_nam   number
variable p_thang number
exec :p_nam := 2026; :p_thang := 4
set feedback on

with ky as (
  select to_date(:p_nam || '-' || :p_thang || '-01', 'YYYY-MM-DD') as tu,
         last_day(to_date(:p_nam || '-' || :p_thang || '-01', 'YYYY-MM-DD')) as den
    from dual
),
phai_lam as (
  select n.nhan_vien_id, n.ma_nhan_vien, n.ho_ten, l.ngay
    from nhan_vien n
    cross join ky
    join lich_lam_viec l
      on l.loai_ngay = 'LAM_VIEC' and l.ngay between ky.tu and ky.den
     and l.ngay >= n.ngay_vao_lam and l.ngay <= nvl(n.ngay_nghi_viec, date '9999-12-31')
),
thieu as (
  select p.*
    from phai_lam p
   -- Cung dieu kien voi sp_chot_cong: moi ngay phai lam can mot ban ghi cong
   -- (ngay nghi ca ngay van co ban ghi 0 gio)
   where not exists (select 1 from cham_cong c where c.nhan_vien_id = p.nhan_vien_id and c.ngay = p.ngay)
)
select ma_nhan_vien, ho_ten, count(*) as so_ngay_thieu, min(ngay) as ngay_dau, max(ngay) as ngay_cuoi
  from thieu
 group by ma_nhan_vien, ho_ten
 order by ma_nhan_vien
 fetch first 10 rows only;
