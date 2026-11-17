-- Xoa du lieu loi cua TC-23 (HRM_OWNER)
set feedback off
delete from chi_tiet_nghi_phep where don_nghi_id in (select don_nghi_id from don_nghi_phep where ly_do = 'TC-23 dữ liệu lỗi');
delete from don_nghi_phep where ly_do = 'TC-23 dữ liệu lỗi';
commit;
prompt Da xoa du lieu loi TC-23
