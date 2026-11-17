-- =============================================================================
-- QR-05 Nguoi dang lam chua co tai khoan
--   Actor: Admin (U_ADMIN)   Nguon: VW-13 vw_danh_ba_nhan_vien (bo sung), VW-09
--   Dau vao: :p_ngay                        Ky thuat: NOT EXISTS
--   Dac ta ghi nguon VW-01 + VW-09 nhung khong role nao co ca hai (Admin khong doc
--   VW-01, TC-08). VW-13 la danh ba toi thieu cho Admin. Du lieu mau: moi nguoi deu
--   co tai khoan nen 0 dong; tests/rep (TC-47) them nguoi moi de thay ket qua.
-- Chay: scripts/run.sh U_ADMIN queries/qr05_chua_co_tai_khoan.sql
-- =============================================================================
@@_dinh_dang.sql
column email         format a30
variable p_ngay varchar2(10)
exec :p_ngay := '2026-11-15'
set feedback on

select d.ma_nhan_vien, d.ho_ten, d.email, d.ngay_vao_lam, d.ten_phong_ban
  from hrm_owner.vw_danh_ba_nhan_vien d
 where d.ngay_vao_lam <= to_date(:p_ngay, 'YYYY-MM-DD')
   and (d.ngay_nghi_viec is null or d.ngay_nghi_viec >= to_date(:p_ngay, 'YYYY-MM-DD'))
   and not exists (select 1 from hrm_owner.vw_tai_khoan_quan_tri t
                    where t.ma_nhan_vien = d.ma_nhan_vien)
 order by d.ngay_vao_lam, d.ma_nhan_vien;
