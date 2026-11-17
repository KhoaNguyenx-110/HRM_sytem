-- =============================================================================
-- restore.sql - Dua du lieu ve trang thai seed sau bo kiem thu bao mat
-- Chay bang HRM_OWNER. TC-02 khoa that tai khoan nv_c bang autonomous COMMIT.
-- =============================================================================
set feedback off
update tai_khoan
   set trang_thai = 'HOAT_DONG', so_lan_dang_nhap_sai = 0
 where ten_dang_nhap = 'nv_c';
commit;
prompt Da mo lai tai khoan nv_c
