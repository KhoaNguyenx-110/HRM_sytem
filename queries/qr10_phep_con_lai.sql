-- =============================================================================
-- QR-10 Phep con lai theo nam
--   Actor: HR, truong phong, nhan vien (U_HR01)  Nguon: VW-02 vw_phep_con_lai
--   Dau vao: :p_nam, :p_ma_nhan_vien (NULL = tat ca trong pham vi)
--   Ky thuat: LEFT JOIN, CASE, SUM (trong VW-02: so ngay da dung / dang cho tinh
--             bang SUM(CASE trang thai)); truy van them CASE canh bao
--   Don cho duyet hien rieng, CHUA tru vao so con lai (BR-18, TC-30).
-- Chay: scripts/run.sh U_HR01 queries/qr10_phep_con_lai.sql
-- =============================================================================
@@_dinh_dang.sql
column canh_bao format a12
variable p_nam          number
variable p_ma_nhan_vien varchar2(20)
exec :p_nam := 2026; :p_ma_nhan_vien := null
set feedback on

select ma_nhan_vien, ho_ten, ma_phong_ban, so_ngay_duoc_cap, so_ngay_dieu_chinh,
       so_ngay_da_dung, so_ngay_cho_duyet, so_ngay_con_lai,
       case when so_ngay_con_lai < 0 then 'VUOT HAN MUC'
            when so_ngay_con_lai - so_ngay_cho_duyet <= 2 then 'SAP HET'
       end as canh_bao
  from hrm_owner.vw_phep_con_lai
 where nam = :p_nam
   and (:p_ma_nhan_vien is null or ma_nhan_vien = upper(:p_ma_nhan_vien))
   and (:p_ma_nhan_vien is not null or so_ngay_da_dung + so_ngay_cho_duyet > 0 or so_ngay_dieu_chinh <> 0)
 order by ma_phong_ban, ma_nhan_vien;
