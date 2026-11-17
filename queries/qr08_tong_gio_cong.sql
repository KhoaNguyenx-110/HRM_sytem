-- =============================================================================
-- QR-08 Tong gio cong theo nguoi trong mot ky (loc phong tuy chon)
--   Actor: HR, Payroll, truong phong (U_HR01)   Nguon: VW-03 vw_cong_thang
--   Dau vao: :p_nam, :p_thang, :p_phong (NULL = tat ca)
--   Ky thuat: SUM, GROUP BY (tong theo phong) - truy van nop kem execution plan
--             truoc/sau index (TC-54, giai doan 6)
-- Chay: scripts/run.sh U_HR01 queries/qr08_tong_gio_cong.sql
-- =============================================================================
@@_dinh_dang.sql
variable p_nam   number
variable p_thang number
variable p_phong varchar2(20)
exec :p_nam := 2026; :p_thang := 1; :p_phong := 'KY_THUAT'
set feedback on

-- Theo nguoi
select ma_phong_ban, ma_nhan_vien, ho_ten, so_ngay_co_cong, gio_cong,
       ngay_nghi_huong_luong, ngay_nghi_khong_luong, gio_huong_luong,
       ot_ngay_thuong + ot_nghi_tuan + ot_le as gio_ot
  from hrm_owner.vw_cong_thang
 where nam = :p_nam and thang = :p_thang
   and (:p_phong is null or ma_phong_ban = :p_phong)
 order by ma_phong_ban, ma_nhan_vien;

-- Tong theo phong (ca cong ty khi :p_phong NULL)
select ma_phong_ban, count(*) as so_nguoi, sum(gio_cong) as tong_gio_cong,
       sum(gio_huong_luong) as tong_gio_huong_luong,
       sum(ot_ngay_thuong + ot_nghi_tuan + ot_le) as tong_gio_ot
  from hrm_owner.vw_cong_thang
 where nam = :p_nam and thang = :p_thang
   and (:p_phong is null or ma_phong_ban = :p_phong)
 group by ma_phong_ban
 order by ma_phong_ban;
