-- =============================================================================
-- QR-09 Don cho toi duyet
--   Actor: truong phong, HR (U_TP_KT)   Nguon: VW-08 vw_don_cho_duyet
--   Dau vao: danh tinh phien (khong tham so - nguoi duyet hop le theo muc 2.4
--            duoc tinh trong view)
--   Ky thuat: JOIN (trong view), GROUP BY
-- Chay: scripts/run.sh U_TP_KT queries/qr09_don_cho_toi_duyet.sql
-- =============================================================================
@@_dinh_dang.sql
column loai_yeu_cau format a16
column noi_dung     format a30
column ly_do        format a30
set feedback on

-- Tom tat theo loai yeu cau
select loai_yeu_cau, count(*) as so_yeu_cau, sum(so_luong) as tong_so_luong,
       min(tu_ngay) as som_nhat
  from hrm_owner.vw_don_cho_duyet
 group by loai_yeu_cau
 order by loai_yeu_cau;

-- Chi tiet (so_luong: so buoi voi don nghi, so gio voi OT, so tien voi quyet dinh)
select loai_yeu_cau, ma_yeu_cau, ma_nhan_vien, ho_ten, noi_dung, tu_ngay, den_ngay, so_luong, ly_do
  from hrm_owner.vw_don_cho_duyet
 order by tu_ngay, loai_yeu_cau, ma_yeu_cau;
