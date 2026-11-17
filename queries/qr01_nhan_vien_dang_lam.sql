-- =============================================================================
-- QR-01 Nhan vien dang lam tai mot ngay
--   Actor: HR (user demo U_HR01)            Nguon: VW-01 vw_ho_so_nhan_vien
--   Dau vao: :p_ngay (YYYY-MM-DD)           Ky thuat: WHERE khoang ngay
--   Dang lam tai ngay D: ngay_vao_lam <= D va (chua nghi hoac ngay_nghi_viec >= D)
-- Chay: scripts/run.sh U_HR01 queries/qr01_nhan_vien_dang_lam.sql
-- DBeaver: chay rieng cau SELECT (Ctrl+Enter), nhap gia tri cho :p_ngay.
-- =============================================================================
@@_dinh_dang.sql
variable p_ngay varchar2(10)
exec :p_ngay := '2026-03-31'
set feedback on

select ma_nhan_vien, ho_ten, ten_phong_ban, ngay_vao_lam, ngay_nghi_viec
  from hrm_owner.vw_ho_so_nhan_vien
 where ngay_vao_lam <= to_date(:p_ngay, 'YYYY-MM-DD')
   and (ngay_nghi_viec is null or ngay_nghi_viec >= to_date(:p_ngay, 'YYYY-MM-DD'))
 order by ma_nhan_vien;
