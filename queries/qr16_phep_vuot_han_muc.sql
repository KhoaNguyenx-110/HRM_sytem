-- =============================================================================
-- QR-16 Phep vuot han muc (truy van bat thuong)
--   Actor: HR (U_HR01)                  Nguon: VW-02 vw_phep_con_lai
--   Dau vao: :p_nam                     Ky thuat: GROUP BY, HAVING
--   Du lieu hop le tra 0 dong: sp_xu_ly_don_nghi khoa dong HAN_MUC_PHEP_NAM va tinh
--   lai so du truoc khi duyet (BR-17, TC-28). Dong nao xuat hien la dau hieu du lieu
--   bi sua ngoai procedure.
-- Chay: scripts/run.sh U_HR01 queries/qr16_phep_vuot_han_muc.sql
-- =============================================================================
@@_dinh_dang.sql
variable p_nam number
exec :p_nam := 2026
set feedback on

select ma_nhan_vien, ho_ten,
       sum(so_ngay_duoc_cap + so_ngay_dieu_chinh) as han_muc,
       sum(so_ngay_da_dung)                       as da_dung
  from hrm_owner.vw_phep_con_lai
 where nam = :p_nam
 group by ma_nhan_vien, ho_ten
having sum(so_ngay_da_dung) > sum(so_ngay_duoc_cap + so_ngay_dieu_chinh)
 order by ma_nhan_vien;

-- Doi chieu: nguoi da dung nhieu phep nhat (de thay du lieu nam duoi han muc)
select ma_nhan_vien, ho_ten, so_ngay_duoc_cap + so_ngay_dieu_chinh as han_muc, so_ngay_da_dung
  from hrm_owner.vw_phep_con_lai
 where nam = :p_nam and so_ngay_da_dung > 0
 order by so_ngay_da_dung desc, ma_nhan_vien
 fetch first 5 rows only;
