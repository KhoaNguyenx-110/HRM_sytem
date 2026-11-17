-- Xuat CSV (Payroll): bang luong mot ky - VW-04. File luong PHAI nen kem mat khau:
--   scripts/xuat_csv.sh U_PAY01 queries/xuat/pay_bang_luong.sql luong_2026_01 --nen
-- Ky chua khoa ghi "TAM TINH" o tung dong (muc 6). Ky xuat: sua hai gia tri duoi day.
variable p_nam   number
variable p_thang number
exec :p_nam := 2026; :p_thang := 1
select nam, thang,
       case trang_thai_ky when 'DA_KHOA' then 'CHINH THUC' else 'TAM TINH' end as tinh_trang,
       ma_phong_ban, ma_chuc_vu, ma_nhan_vien, ho_ten, luong_co_ban_ap_dung, gio_huong_luong,
       tong_gross, thu_nhap_chiu_thue, thu_nhap_tinh_thue, bao_hiem_nld, thue_tncn, khau_tru_khac,
       tong_net, bao_hiem_nsdld, chi_phi_doanh_nghiep
  from hrm_owner.vw_bang_luong_tong_hop
 where nam = :p_nam and thang = :p_thang
 order by ma_phong_ban, ma_nhan_vien;
