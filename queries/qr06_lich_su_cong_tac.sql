-- =============================================================================
-- QR-06 Lich su cong tac cua mot nhan vien
--   Actor: HR, truong phong, chinh nhan vien    Nguon: VW-12 vw_qua_trinh_cong_tac
--   Dau vao: :p_ma_nhan_vien                    Ky thuat: JOIN (trong view), ORDER BY
-- Chay: scripts/run.sh U_HR01 queries/qr06_lich_su_cong_tac.sql
-- =============================================================================
@@_dinh_dang.sql
column den_ngay           format a10
column can_cu_dieu_chuyen format a34
variable p_ma_nhan_vien varchar2(20)
exec :p_ma_nhan_vien := 'NV023'
set feedback on

select ma_nhan_vien, ho_ten, ten_phong_ban, ten_chuc_vu, ngay_bat_dau,
       nvl(to_char(ngay_ket_thuc, 'DD/MM/YYYY'), 'hien tai') as den_ngay, can_cu_dieu_chuyen
  from hrm_owner.vw_qua_trinh_cong_tac
 where ma_nhan_vien = upper(:p_ma_nhan_vien)
 order by ngay_bat_dau;
