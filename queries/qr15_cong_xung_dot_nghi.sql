-- =============================================================================
-- QR-15 Cong xung dot nghi: ngay co gio cong + gio nghi da duyet vuot chuan (BR-12)
--   Nguon: truy van kiem tra BEN TRONG pkg_att.sp_chot_cong (SP-07); chay bang
--   HRM_OWNER de nop cau SQL va ket qua mau.
--   Dau vao: :p_nam, :p_thang
--   Ky thuat: CTE gom gio nghi theo nguoi/ngay (SUM), JOIN voi cong va lich
--   Du lieu hop le tra 0 dong; TC-23 tao du lieu loi de thay mot dong.
-- Chay: scripts/run.sh owner queries/qr15_cong_xung_dot_nghi.sql
-- =============================================================================
@@_dinh_dang.sql
variable p_nam   number
variable p_thang number
exec :p_nam := 2026; :p_thang := 2
set feedback on

with nghi as (
  select ct.nhan_vien_id, ct.ngay,
         sum(case ct.buoi when 'SANG' then l.gio_ket_thuc_sang - l.gio_bat_dau_sang
                          else l.gio_ket_thuc_chieu - l.gio_bat_dau_chieu end) as gio_nghi
    from chi_tiet_nghi_phep ct
    join don_nghi_phep d on d.don_nghi_id = ct.don_nghi_id and d.trang_thai = 'DA_DUYET'
    join lich_lam_viec l on l.ngay = ct.ngay
   where extract(year from ct.ngay) = :p_nam and extract(month from ct.ngay) = :p_thang
   group by ct.nhan_vien_id, ct.ngay
)
select n.ma_nhan_vien, n.ho_ten, c.ngay, c.so_gio_lam_thuc_te as gio_cong, x.gio_nghi,
       l.so_gio_chuan, c.so_gio_lam_thuc_te + x.gio_nghi - l.so_gio_chuan as vuot
  from cham_cong c
  join nghi x          on x.nhan_vien_id = c.nhan_vien_id and x.ngay = c.ngay
  join lich_lam_viec l on l.ngay = c.ngay
  join nhan_vien n     on n.nhan_vien_id = c.nhan_vien_id
 where c.so_gio_lam_thuc_te + x.gio_nghi > l.so_gio_chuan
 order by c.ngay, n.ma_nhan_vien;

-- Ngay co ca cong va nghi da duyet (hop le, khong vuot chuan) - de thay truy van co du lieu
with nghi as (
  select ct.nhan_vien_id, ct.ngay,
         sum(case ct.buoi when 'SANG' then l.gio_ket_thuc_sang - l.gio_bat_dau_sang
                          else l.gio_ket_thuc_chieu - l.gio_bat_dau_chieu end) as gio_nghi
    from chi_tiet_nghi_phep ct
    join don_nghi_phep d on d.don_nghi_id = ct.don_nghi_id and d.trang_thai = 'DA_DUYET'
    join lich_lam_viec l on l.ngay = ct.ngay
   where extract(year from ct.ngay) = :p_nam and extract(month from ct.ngay) = :p_thang
   group by ct.nhan_vien_id, ct.ngay
)
select n.ma_nhan_vien, c.ngay, c.so_gio_lam_thuc_te as gio_cong, x.gio_nghi, l.so_gio_chuan
  from cham_cong c
  join nghi x          on x.nhan_vien_id = c.nhan_vien_id and x.ngay = c.ngay
  join lich_lam_viec l on l.ngay = c.ngay
  join nhan_vien n     on n.nhan_vien_id = c.nhan_vien_id
 order by c.ngay;
