-- =============================================================================
-- QR-22 Luy ke thu nhap theo thang trong nam cua mot nguoi
--   Actor: Payroll, chinh nhan vien (U_PAY01)   Nguon: VW-05 vw_phieu_luong_ca_nhan
--   Dau vao: :p_nam, :p_ma_nhan_vien
--   Ky thuat: SUM() OVER (ORDER BY thang) - tong chay
--   VW-05 moi dong la mot dong chi tiet, nen lay DISTINCT phan dau phieu truoc.
--   Chay bang U_NV_A: chi thay cac ky DA_KHOA (01, 02); Payroll thay them ky 03
--   "TAM TINH".
-- Chay: scripts/run.sh U_PAY01 queries/qr22_luy_ke_thu_nhap.sql
-- =============================================================================
@@_dinh_dang.sql
column gross        format 999G999G990
column luy_ke_gross format 999G999G990
column thue         format 999G999G990
column luy_ke_thue  format 999G999G990
column net          format 999G999G990
column luy_ke_net   format 999G999G990
variable p_nam          number
variable p_ma_nhan_vien varchar2(20)
exec :p_nam := 2026; :p_ma_nhan_vien := 'NV_A'
set feedback on

with phieu as (
  select distinct thang, trang_thai_ky, tong_gross, thue_tncn, tong_net
    from hrm_owner.vw_phieu_luong_ca_nhan
   where nam = :p_nam and ma_nhan_vien = upper(:p_ma_nhan_vien)
)
select thang,
       tong_gross                                  as gross,
       sum(tong_gross) over (order by thang)       as luy_ke_gross,
       thue_tncn                                   as thue,
       sum(thue_tncn) over (order by thang)        as luy_ke_thue,
       tong_net                                    as net,
       sum(tong_net) over (order by thang)         as luy_ke_net,
       case trang_thai_ky when 'DA_KHOA' then 'CHINH THUC' else 'TAM TINH' end as tinh_trang
  from phieu
 order by thang;
