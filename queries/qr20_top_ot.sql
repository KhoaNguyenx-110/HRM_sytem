-- =============================================================================
-- QR-20 Top N nguoi lam OT nhieu nhat trong khoang ky
--   Actor: HR, Payroll (U_PAY01)        Nguon: VW-03 vw_cong_thang
--   Dau vao: :p_nam, :p_tu_thang, :p_den_thang, :p_n
--   Ky thuat: CTE, DENSE_RANK - nguoi dong hang cung hang, nen co the ra nhieu hon
--             N nguoi (vd top 2 hang: hang 1 co 3 nguoi cung 4 gio)
-- Chay: scripts/run.sh U_PAY01 queries/qr20_top_ot.sql
-- =============================================================================
@@_dinh_dang.sql
variable p_nam       number
variable p_tu_thang  number
variable p_den_thang number
variable p_n         number
exec :p_nam := 2026; :p_tu_thang := 1; :p_den_thang := 3; :p_n := 2
set feedback on

with tong as (
  select ma_nhan_vien, ho_ten, max(ma_phong_ban) as ma_phong_ban,
         sum(ot_ngay_thuong + ot_nghi_tuan + ot_le) as gio_ot
    from hrm_owner.vw_cong_thang
   where nam = :p_nam and thang between :p_tu_thang and :p_den_thang
   group by ma_nhan_vien, ho_ten
),
xep_hang as (
  select t.*, dense_rank() over (order by gio_ot desc) as hang
    from tong t
   where gio_ot > 0
)
select hang, ma_nhan_vien, ho_ten, ma_phong_ban, gio_ot
  from xep_hang
 where hang <= :p_n
 order by hang, ma_nhan_vien;
