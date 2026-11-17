-- Xuat CSV (truong phong): nhan su phong minh dang quan ly - VW-07
-- Dung: scripts/xuat_csv.sh U_TP_KT queries/xuat/tp_nhan_su_phong.sql nhan_su_ky_thuat
select ma_nhan_vien, ho_ten, ma_phong_ban, ten_phong_ban, ma_chuc_vu, ten_chuc_vu,
       ngay_bat_dau, email, so_dien_thoai
  from hrm_owner.vw_nhan_su_phong
 order by ma_nhan_vien;
