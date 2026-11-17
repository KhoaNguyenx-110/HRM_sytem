-- =============================================================================
-- QR-21 Bien dong quy luong theo thang
--   Actor: Payroll (U_PAY01)            Nguon: VW-04 vw_bang_luong_tong_hop
--   Dau vao: :p_tu_ky, :p_den_ky (YYYY-MM)
--   Ky thuat: day thang lien tuc (CONNECT BY LEVEL), LEFT JOIN, LAG, NULLIF
--   * Thang khong co phieu van hien (quy 0, "KHONG CO KY"), khong bi nhay qua roi
--     goi thang lien truoc la "thang truoc" (muc 6).
--   * Ty le = chenh lech / quy thang truoc; thang truoc bang 0 -> NULLIF tra NULL,
--     khong loi chia 0 (FR-REP-05, TC-50).
--   Nop kem execution plan truoc/sau index (TC-54, giai doan 6).
-- Chay: scripts/run.sh U_PAY01 queries/qr21_bien_dong_quy_luong.sql
-- =============================================================================
@@_dinh_dang.sql
column ky         format a7
column gross      format 999G999G999G990
column gross_truoc format 999G999G999G990
column chenh_lech format 999G999G999G990
column ty_le_pct  format 990D99
column tinh_trang format a12
variable p_tu_ky  varchar2(7)
variable p_den_ky varchar2(7)
exec :p_tu_ky := '2025-11'; :p_den_ky := '2026-03'
set feedback on

with thang as (
  select add_months(to_date(:p_tu_ky, 'YYYY-MM'), level - 1) as dau_thang
    from dual
 connect by level <= months_between(to_date(:p_den_ky, 'YYYY-MM'), to_date(:p_tu_ky, 'YYYY-MM')) + 1
),
quy as (
  select to_date(nam || '-' || thang, 'YYYY-MM') as dau_thang,
         sum(tong_gross) as gross,
         max(trang_thai_ky) as trang_thai_ky
    from hrm_owner.vw_bang_luong_tong_hop
   group by nam, thang
),
day_du as (
  select t.dau_thang, nvl(q.gross, 0) as gross, q.trang_thai_ky
    from thang t
    left join quy q on q.dau_thang = t.dau_thang
)
select to_char(dau_thang, 'MM/YYYY')                       as ky,
       gross,
       lag(gross) over (order by dau_thang)                 as gross_truoc,
       gross - lag(gross) over (order by dau_thang)         as chenh_lech,
       round((gross - lag(gross) over (order by dau_thang))
             / nullif(lag(gross) over (order by dau_thang), 0) * 100, 2) as ty_le_pct,
       case when trang_thai_ky is null      then 'KHONG CO KY'
            when trang_thai_ky = 'DA_KHOA'  then 'CHINH THUC'
            else 'TAM TINH' end                             as tinh_trang
  from day_du
 order by dau_thang;
