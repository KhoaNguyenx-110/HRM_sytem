-- =============================================================================
-- QR-07 Nguoi phu thuoc con hieu luc trong mot thang
--   Actor: HR (U_HR01)   Nguon: bang NGUOI_PHU_THUOC qua procedure HR
--                        pkg_hr.sp_tra_nguoi_phu_thuoc (tra SYS_REFCURSOR)
--   Dau vao: thang, nam, ma nhan vien (NULL = tat ca)
--   Ky thuat: JOIN, giao khoang [tu_ngay, den_ngay] voi thang:
--             tu_ngay <= cuoi thang AND nvl(den_ngay, vo han) >= dau thang
--   Chi dang ky DA_XAC_MINH (dang cho xac minh khong duoc giam tru - TC-15).
-- Chay: scripts/run.sh U_HR01 queries/qr07_nguoi_phu_thuoc.sql
-- DBeaver: {call hrm_owner.pkg_hr.sp_tra_nguoi_phu_thuoc(1, 2026, null, ?)} voi ? la OUT cursor
-- =============================================================================
@@_dinh_dang.sql
column nguoi_phu_thuoc format a24
column dinh_danh       format a14
variable rc refcursor
exec hrm_owner.pkg_hr.sp_tra_nguoi_phu_thuoc(1, 2026, null, :rc)
set feedback on
print rc
