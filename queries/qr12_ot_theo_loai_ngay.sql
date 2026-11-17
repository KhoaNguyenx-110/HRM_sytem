-- =============================================================================
-- QR-12 Gio OT theo loai ngay (ngay thuong / nghi tuan / le) va phong
--   Actor: HR, Payroll (U_PAY01)        Nguon: VW-03 vw_cong_thang
--   Dau vao: :p_nam, :p_tu_thang, :p_den_thang
--   Ky thuat: SUM(CASE ...) (trong VW-03 tach gio OT theo loai ngay), UNPIVOT ba
--             cot thanh dong roi PIVOT theo phong: dong = loai ngay, cot = phong
-- Chay: scripts/run.sh U_PAY01 queries/qr12_ot_theo_loai_ngay.sql
-- =============================================================================
@@_dinh_dang.sql
column loai_ngay format a12
variable p_nam       number
variable p_tu_thang  number
variable p_den_thang number
exec :p_nam := 2026; :p_tu_thang := 1; :p_den_thang := 3
set feedback on

select *
  from (select ma_phong_ban, loai_ngay, gio
          from hrm_owner.vw_cong_thang
       unpivot (gio for loai_ngay in (ot_ngay_thuong as 'NGAY_THUONG',
                                      ot_nghi_tuan   as 'NGHI_TUAN',
                                      ot_le          as 'LE'))
         where nam = :p_nam and thang between :p_tu_thang and :p_den_thang)
 pivot (sum(gio) for ma_phong_ban in ('BGD'        as bgd,
                                      'NHAN_SU'    as nhan_su,
                                      'KE_TOAN'    as ke_toan,
                                      'KINH_DOANH' as kinh_doanh,
                                      'KY_THUAT'   as ky_thuat))
 order by decode(loai_ngay, 'NGAY_THUONG', 1, 'NGHI_TUAN', 2, 3);
