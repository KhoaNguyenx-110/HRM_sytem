-- =============================================================================
-- QR-03 Tim ho so theo ma hoac ten, khong phan biet hoa/thuong
--   Actor: HR, truong phong, nhan vien      Nguon: VW-01 vw_ho_so_nhan_vien
--   Dau vao: :p_tu_khoa                     Ky thuat: LIKE + UPPER, ESCAPE
--   Chay bang U_TP_KT de thay pham vi: chi phong Ky thuat, dinh danh chi 4 so cuoi,
--   MST trong (TC-18). Dau "_" trong tu khoa duoc thoat de khong thanh ky tu dai dien.
-- Chay: scripts/run.sh U_TP_KT queries/qr03_tim_ho_so.sql
-- =============================================================================
@@_dinh_dang.sql
column so_dinh_danh  format a14
column ma_so_thue    format a14
variable p_tu_khoa varchar2(100)
exec :p_tu_khoa := 'nv04'
set feedback on

select ma_nhan_vien, ho_ten, so_dinh_danh, ma_so_thue, ten_phong_ban, ten_chuc_vu
  from hrm_owner.vw_ho_so_nhan_vien
 where upper(ma_nhan_vien) like '%' || replace(upper(:p_tu_khoa), '_', '\_') || '%' escape '\'
    or upper(ho_ten)       like '%' || replace(upper(:p_tu_khoa), '_', '\_') || '%' escape '\'
 order by ma_nhan_vien;
