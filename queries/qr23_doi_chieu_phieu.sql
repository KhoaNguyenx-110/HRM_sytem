-- =============================================================================
-- QR-23 Doi chieu phieu: phieu co tong lech chi tiet
--   Actor: Payroll (U_PAY01)            Nguon: VW-05 vw_phieu_luong_ca_nhan
--   Dau vao: :p_nam, :p_thang
--   Ky thuat: JOIN (phieu - chi tiet, trong view), GROUP BY, HAVING
--   Du lieu hop le tra 0 dong. Cung dieu kien voi pkg_payroll.so_phieu_lech ma
--   sp_tinh_luong_ky (sau khi ghi) va sp_khoa_ky_luong (truoc khi khoa) dung.
-- Chay: scripts/run.sh U_PAY01 queries/qr23_doi_chieu_phieu.sql
-- =============================================================================
@@_dinh_dang.sql
variable p_nam   number
variable p_thang number
exec :p_nam := 2026; :p_thang := 1
set feedback on

select phieu_luong_id, ma_nhan_vien,
       tong_gross,
       sum(case nhom_khoan_ap_dung when 'THU_NHAP' then thanh_tien
                                   when 'GIAM_THU_NHAP' then -thanh_tien else 0 end) as gross_chi_tiet,
       bao_hiem_nld,
       sum(case when nhom_khoan_ap_dung = 'BAO_HIEM_NLD' then thanh_tien else 0 end) as bh_chi_tiet,
       thue_tncn,
       sum(case when nhom_khoan_ap_dung = 'THUE_TNCN' then thanh_tien else 0 end)    as thue_chi_tiet
  from hrm_owner.vw_phieu_luong_ca_nhan
 where nam = :p_nam and thang = :p_thang
 group by phieu_luong_id, ma_nhan_vien, tong_gross, bao_hiem_nld, thue_tncn,
          khau_tru_khac, bao_hiem_nsdld, thu_nhap_chiu_thue
having tong_gross     <> sum(case nhom_khoan_ap_dung when 'THU_NHAP' then thanh_tien
                                                     when 'GIAM_THU_NHAP' then -thanh_tien else 0 end)
    or bao_hiem_nld   <> sum(case when nhom_khoan_ap_dung = 'BAO_HIEM_NLD'   then thanh_tien else 0 end)
    or bao_hiem_nsdld <> sum(case when nhom_khoan_ap_dung = 'BAO_HIEM_NSDLD' then thanh_tien else 0 end)
    or thue_tncn      <> sum(case when nhom_khoan_ap_dung = 'THUE_TNCN'      then thanh_tien else 0 end)
    or khau_tru_khac  <> sum(case when nhom_khoan_ap_dung = 'KHAU_TRU'       then thanh_tien else 0 end)
    or thu_nhap_chiu_thue <> greatest(sum(case nhom_khoan_ap_dung when 'THU_NHAP' then phan_chiu_thue
                                                                  when 'GIAM_THU_NHAP' then -phan_chiu_thue
                                                                  else 0 end), 0)
 order by ma_nhan_vien;

-- Tong kiem: so phieu, so dong chi tiet, tong net cua ky
select count(*) as so_phieu, sum(so_dong) as so_dong_chi_tiet,
       to_char(sum(tong_net), 'FM999G999G999G990') as tong_net
  from (select phieu_luong_id, max(tong_net) as tong_net, count(*) as so_dong
          from hrm_owner.vw_phieu_luong_ca_nhan
         where nam = :p_nam and thang = :p_thang
         group by phieu_luong_id);
