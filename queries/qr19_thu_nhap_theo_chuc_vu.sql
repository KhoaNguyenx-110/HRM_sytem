-- =============================================================================
-- QR-19 Thu nhap theo chuc vu trong khoang ky
--   Actor: Payroll (U_PAY01)            Nguon: VW-04 vw_bang_luong_tong_hop
--   Dau vao: :p_tu_ky, :p_den_ky (YYYY-MM)
--   Ky thuat: COUNT, MIN, MAX, AVG
--   Chuc vu lay tu phieu (snapshot). Khoang co ky chua khoa -> ghi "TAM TINH".
-- Chay: scripts/run.sh U_PAY01 queries/qr19_thu_nhap_theo_chuc_vu.sql
-- =============================================================================
@@_dinh_dang.sql
column gross_min format 999G999G990
column gross_max format 999G999G990
column gross_tb  format 999G999G990
column net_tb    format 999G999G990
variable p_tu_ky  varchar2(7)
variable p_den_ky varchar2(7)
exec :p_tu_ky := '2026-01'; :p_den_ky := '2026-03'
set feedback on

select ten_chuc_vu,
       count(distinct ma_nhan_vien) as so_nguoi,
       count(*)                     as so_phieu,
       min(tong_gross)              as gross_min,
       max(tong_gross)              as gross_max,
       round(avg(tong_gross))       as gross_tb,
       round(avg(tong_net))         as net_tb,
       case when min(trang_thai_ky) = 'DA_KHOA' and max(trang_thai_ky) = 'DA_KHOA'
            then 'CHINH THUC' else 'TAM TINH' end as tinh_trang
  from hrm_owner.vw_bang_luong_tong_hop
 where to_char(nam, 'FM0000') || '-' || to_char(thang, 'FM00') between :p_tu_ky and :p_den_ky
 group by ten_chuc_vu
 order by gross_tb desc;
