-- =============================================================================
-- QR-02 Nhan su theo phong tai mot ngay (ke ca ngay trong qua khu)
--   Actor: HR, truong phong (U_HR01)        Nguon: VW-12 vw_qua_trinh_cong_tac
--   Dau vao: :p_ngay, :p_phong (ma phong, NULL = tat ca)
--   Ky thuat: JOIN (trong view), loc hieu luc tai ngay; GROUP BY ROLLUP de tong
--             khop chi tiet (FR-REP-01)
--   Dung lich su phan cong, KHONG dung phong hien tai: NV023 chuyen tu KINH_DOANH
--   sang KY_THUAT ngay 01/02/2026, nen tai 15/01/2026 van thuoc KINH_DOANH (TC-47).
-- Chay: scripts/run.sh U_HR01 queries/qr02_nhan_su_phong_tai_ngay.sql
-- =============================================================================
@@_dinh_dang.sql
column phong         format a14
column chuc_vu       format a20
variable p_ngay  varchar2(10)
variable p_phong varchar2(20)
exec :p_ngay := '2026-01-15'; :p_phong := 'KINH_DOANH'
set feedback on

-- Chi tiet
select ma_phong_ban, ma_nhan_vien, ho_ten, ten_chuc_vu, ngay_bat_dau, ngay_ket_thuc
  from hrm_owner.vw_qua_trinh_cong_tac
 where to_date(:p_ngay, 'YYYY-MM-DD') between ngay_bat_dau and nvl(ngay_ket_thuc, date '9999-12-31')
   and (:p_phong is null or ma_phong_ban = :p_phong)
 order by ma_phong_ban, la_quan_ly desc, ma_nhan_vien;

-- Tong theo phong va chuc vu (dong ROLLUP cuoi = tong toan bo, khop so dong chi tiet)
select case grouping(ma_phong_ban) when 1 then '== TONG' else ma_phong_ban end as phong,
       case grouping(ten_chuc_vu)  when 1 then '(cong phong)' else ten_chuc_vu end as chuc_vu,
       count(*) as so_nguoi
  from hrm_owner.vw_qua_trinh_cong_tac
 where to_date(:p_ngay, 'YYYY-MM-DD') between ngay_bat_dau and nvl(ngay_ket_thuc, date '9999-12-31')
   and (:p_phong is null or ma_phong_ban = :p_phong)
 group by rollup (ma_phong_ban, ten_chuc_vu)
 order by grouping(ma_phong_ban), ma_phong_ban, grouping(ten_chuc_vu), ten_chuc_vu;
