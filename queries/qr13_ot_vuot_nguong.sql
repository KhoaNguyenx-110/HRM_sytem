-- =============================================================================
-- QR-13 Nguoi co gio OT vuot nguong canh bao trong khoang ky
--   Actor: HR, truong phong (U_HR01)    Nguon: VW-03 vw_cong_thang
--   Dau vao: :p_nam, :p_tu_thang, :p_den_thang, :p_nguong (gio)
--   Ky thuat: GROUP BY, HAVING
--   Nguong la canh bao noi bo, khac han muc luat (han muc chan khi duyet OT, SP-06).
-- Chay: scripts/run.sh U_HR01 queries/qr13_ot_vuot_nguong.sql
-- =============================================================================
@@_dinh_dang.sql
variable p_nam       number
variable p_tu_thang  number
variable p_den_thang number
variable p_nguong    number
exec :p_nam := 2026; :p_tu_thang := 1; :p_den_thang := 3; :p_nguong := 3
set feedback on

select ma_nhan_vien, ho_ten, max(ma_phong_ban) as ma_phong_ban,
       sum(ot_ngay_thuong) as ot_ngay_thuong, sum(ot_nghi_tuan) as ot_nghi_tuan, sum(ot_le) as ot_le,
       sum(ot_ngay_thuong + ot_nghi_tuan + ot_le) as tong_gio_ot
  from hrm_owner.vw_cong_thang
 where nam = :p_nam and thang between :p_tu_thang and :p_den_thang
 group by ma_nhan_vien, ho_ten
having sum(ot_ngay_thuong + ot_nghi_tuan + ot_le) > :p_nguong
 order by tong_gio_ot desc, ma_nhan_vien;
