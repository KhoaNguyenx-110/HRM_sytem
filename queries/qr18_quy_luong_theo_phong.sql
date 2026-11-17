-- =============================================================================
-- QR-18 Quy luong theo phong trong mot ky
--   Actor: Payroll (U_PAY01)            Nguon: VW-04 vw_bang_luong_tong_hop
--   Dau vao: :p_nam, :p_thang
--   Ky thuat: SUM, GROUP BY ROLLUP (dong tong cong ty), GROUPING
--   Phong lay tu PHIEU (luu luc tinh), khong lay phong hien tai: dieu chuyen ve sau
--   khong doi quy luong ky cu (BR-29, TC-49). Ky chua khoa ghi "TAM TINH" (muc 6).
--   Nop kem execution plan truoc/sau index (TC-54, giai doan 6).
-- Chay: scripts/run.sh U_PAY01 queries/qr18_quy_luong_theo_phong.sql
-- =============================================================================
@@_dinh_dang.sql
column phong format a20
column gross    format 999G999G999G990
column bh_nld   format 999G999G990
column thue     format 999G999G990
column net      format 999G999G999G990
column bh_nsdld format 999G999G990
column chi_phi  format 999G999G999G990
variable p_nam   number
variable p_thang number
exec :p_nam := 2026; :p_thang := 1
set feedback on

select case grouping(ten_phong_ban) when 1 then '== TONG CONG TY' else ten_phong_ban end as phong,
       count(*)                    as so_phieu,
       sum(tong_gross)             as gross,
       sum(bao_hiem_nld)           as bh_nld,
       sum(thue_tncn)              as thue,
       sum(tong_net)               as net,
       sum(bao_hiem_nsdld)         as bh_nsdld,
       sum(chi_phi_doanh_nghiep)   as chi_phi,
       case max(trang_thai_ky) when 'DA_KHOA' then 'CHINH THUC' else 'TAM TINH' end as tinh_trang
  from hrm_owner.vw_bang_luong_tong_hop
 where nam = :p_nam and thang = :p_thang
 group by rollup (ten_phong_ban)
 order by grouping(ten_phong_ban), ten_phong_ban;
