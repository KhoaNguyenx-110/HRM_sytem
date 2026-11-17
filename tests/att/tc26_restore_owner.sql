-- Dua ky 03/2026 ve MO sau TC-26 (HRM_OWNER; chi dung cho moi truong kiem thu)
set feedback off
update ky_luong set trang_thai = 'MO', nguoi_chot_cong = null, thoi_diem_chot_cong = null
 where nam = 2026 and thang = 3;
commit;
prompt Da dua ky 03/2026 ve MO
