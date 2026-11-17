-- Xuat CSV (truong phong, HR, Payroll): cong thang theo pham vi cua nguoi chay - VW-03
-- Dung: scripts/xuat_csv.sh U_TP_KT queries/xuat/tp_cong_thang.sql cong_2026_01
-- Ky xuat: sua hai gia tri duoi day.
variable p_nam   number
variable p_thang number
exec :p_nam := 2026; :p_thang := 1
select nam, thang, trang_thai_ky, ma_phong_ban, ma_nhan_vien, ho_ten, so_ngay_co_cong, gio_cong,
       ngay_nghi_huong_luong, ngay_nghi_khong_luong, gio_huong_luong, ot_ngay_thuong, ot_nghi_tuan, ot_le
  from hrm_owner.vw_cong_thang
 where nam = :p_nam and thang = :p_thang
 order by ma_phong_ban, ma_nhan_vien;
