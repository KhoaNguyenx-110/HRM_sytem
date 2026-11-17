-- =============================================================================
-- QR-11 Nghi theo loai trong khoang ngay
--   Actor: HR, Payroll, truong phong (U_HR01)  Nguon: VW-14 vw_nghi_phep_chi_tiet
--   Dau vao: :p_tu, :p_den (YYYY-MM-DD)
--   Ky thuat: JOIN (trong view), GROUP BY
--   Chi cong don DA_DUYET: don TU_CHOI, DA_RUT, CHO_DUYET khong duoc tinh (TC-48);
--   VW-14 giu ca trang thai don de doi chieu chi tiet. Moi buoi = 0,5 ngay.
-- Chay: scripts/run.sh U_HR01 queries/qr11_nghi_theo_loai.sql
-- =============================================================================
@@_dinh_dang.sql
column ten_loai_nghi format a24
variable p_tu  varchar2(10)
variable p_den varchar2(10)
exec :p_tu := '2026-01-01'; :p_den := '2026-03-31'
set feedback on

select ma_phong_ban, ma_nhan_vien, ho_ten, ten_loai_nghi,
       count(*)       as so_buoi,
       count(*) * 0.5 as so_ngay,
       sum(so_gio)    as so_gio,
       min(ngay)      as tu_ngay,
       max(ngay)      as den_ngay
  from hrm_owner.vw_nghi_phep_chi_tiet
 where trang_thai_don = 'DA_DUYET'
   and ngay between to_date(:p_tu, 'YYYY-MM-DD') and to_date(:p_den, 'YYYY-MM-DD')
 group by ma_phong_ban, ma_nhan_vien, ho_ten, ten_loai_nghi
 order by ma_phong_ban, ma_nhan_vien, ten_loai_nghi;

-- Doi chieu: so buoi theo trang thai don trong cung khoang (dong khac DA_DUYET khong cong o tren)
select trang_thai_don, count(*) as so_buoi
  from hrm_owner.vw_nghi_phep_chi_tiet
 where ngay between to_date(:p_tu, 'YYYY-MM-DD') and to_date(:p_den, 'YYYY-MM-DD')
 group by trang_thai_don
 order by trang_thai_don;
