-- =============================================================================
-- QR-17 Phieu luong chi tiet cua mot nguoi trong mot ky
--   Actor: Payroll (tat ca), nhan vien (phieu cua minh o ky DA_KHOA) - U_PAY01
--   Nguon: VW-05 vw_phieu_luong_ca_nhan
--   Dau vao: :p_ma_nhan_vien, :p_nam, :p_thang
--   Ky thuat: JOIN (phieu - chi tiet - loai khoan, trong view), ORDER BY theo nhom
--   Moi dong luu so luong x don gia x he so = thanh tien de giai thich tung con so
--   (muc 9.9). Vi du NV_A ky 01/2026 = vi du muc 9.8, net 35.635.200.
-- Chay: scripts/run.sh U_PAY01 queries/qr17_phieu_luong_chi_tiet.sql
--       scripts/run.sh U_NV_A  queries/qr17_phieu_luong_chi_tiet.sql  (chinh minh)
-- =============================================================================
@@_dinh_dang.sql
column nhom_khoan_ap_dung format a15
column don_gia            format 999G999G990D9999
column thanh_tien         format 999G999G990
column phan_chiu_thue     format 999G999G990
column so_luong           format 9990D99
column he_so              format 0D999
variable p_ma_nhan_vien varchar2(20)
variable p_nam          number
variable p_thang        number
exec :p_ma_nhan_vien := 'NV_A'; :p_nam := 2026; :p_thang := 1
set feedback on

-- Phan dau phieu
select distinct ma_nhan_vien, ho_ten, ten_phong_ban, ten_chuc_vu,
       case trang_thai_ky when 'DA_KHOA' then 'CHINH THUC' else 'TAM TINH' end as tinh_trang,
       to_char(tong_gross, 'FM999G999G990')         as gross,
       to_char(bao_hiem_nld, 'FM999G999G990')       as bh_nld,
       to_char(thu_nhap_tinh_thue, 'FM999G999G990') as tntt,
       to_char(thue_tncn, 'FM999G999G990')          as thue,
       to_char(tong_net, 'FM999G999G990')           as net
  from hrm_owner.vw_phieu_luong_ca_nhan
 where ma_nhan_vien = upper(:p_ma_nhan_vien) and nam = :p_nam and thang = :p_thang;

-- Cac dong
select ma_khoan, ten_khoan, nhom_khoan_ap_dung, so_luong, don_gia, he_so, thanh_tien, phan_chiu_thue
  from hrm_owner.vw_phieu_luong_ca_nhan
 where ma_nhan_vien = upper(:p_ma_nhan_vien) and nam = :p_nam and thang = :p_thang
 order by decode(nhom_khoan_ap_dung, 'THU_NHAP', 1, 'GIAM_THU_NHAP', 2, 'BAO_HIEM_NLD', 3,
                 'THUE_TNCN', 4, 'KHAU_TRU', 5, 6), chi_tiet_id;
