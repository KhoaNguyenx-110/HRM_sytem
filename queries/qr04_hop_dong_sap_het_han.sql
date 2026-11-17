-- =============================================================================
-- QR-04 Hop dong sap het han trong N ngay ke tu mot ngay
--   Actor: HR (U_HR01)                      Nguon: VW-06 vw_hop_dong_sap_het_han
--   Dau vao: :p_ngay, :p_so_ngay            Ky thuat: JOIN (trong view), dieu kien ngay
--   View da loai hop dong khong thoi han va hop dong da huy (FR-REP-02, TC-47).
-- Chay: scripts/run.sh U_HR01 queries/qr04_hop_dong_sap_het_han.sql
-- =============================================================================
@@_dinh_dang.sql
column ten_loai_hop_dong format a28
variable p_ngay    varchar2(10)
variable p_so_ngay number
exec :p_ngay := '2026-11-15'; :p_so_ngay := 30
set feedback on

select so_hop_dong, ma_nhan_vien, ho_ten, ten_phong_ban, ten_loai_hop_dong, ngay_ket_thuc,
       ngay_ket_thuc - to_date(:p_ngay, 'YYYY-MM-DD') as con_ngay
  from hrm_owner.vw_hop_dong_sap_het_han
 where ngay_ket_thuc between to_date(:p_ngay, 'YYYY-MM-DD') and to_date(:p_ngay, 'YYYY-MM-DD') + :p_so_ngay
 order by ngay_ket_thuc, ma_nhan_vien;
