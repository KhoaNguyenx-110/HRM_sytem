-- =============================================================================
-- 10_grants.sql - Cap quyen doi tuong cho role va HRM_APP (ma tran muc 8.2)
-- Chay bang HRM_OWNER (chu so huu doi tuong), trong install.sql.
-- Khong role nghiep vu nao co INSERT/UPDATE/DELETE tren bang.
-- pkg_chung la noi bo: khong cap cho ai. pkg_payroll.danh_dau_tinh_lai cap kem
-- package nhung khai bao ACCESSIBLE BY nen chi pkg_hr, pkg_att, pkg_payroll goi duoc.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- HRM_APP (kenh web): EXECUTE tren package + SELECT tren VIEW (v2.3).
-- KHONG co quyen nao tren bang. Moi view tu loc dong theo HRM_CTX
-- (fn_co_vai_tro / fn_nhan_vien_hien_tai): truoc pkg_ctx.dat_phien hoac sau
-- xoa_phien moi view tra 0 dong; nguoi dung chi thay phan vai tro cua minh
-- duoc thay (TC-56). Danh muc la bang goc nen doc qua pkg_danh_muc (SP-29).
-- ---------------------------------------------------------------------------
grant execute on pkg_danh_muc to hrm_app;
grant select on vw_ho_so_nhan_vien      to hrm_app;
grant select on vw_phep_con_lai         to hrm_app;
grant select on vw_cong_thang           to hrm_app;
grant select on vw_nhan_su_phong        to hrm_app;
grant select on vw_don_cho_duyet        to hrm_app;
grant select on vw_yeu_cau_cua_toi      to hrm_app;
grant select on vw_tai_khoan_quan_tri   to hrm_app;
grant select on vw_nhat_ky              to hrm_app;
grant select on vw_bang_luong_tong_hop  to hrm_app;
grant select on vw_phieu_luong_ca_nhan  to hrm_app;
grant select on vw_hop_dong_sap_het_han to hrm_app;
grant select on vw_qua_trinh_cong_tac   to hrm_app;
grant select on vw_nghi_phep_chi_tiet   to hrm_app;
grant select on vw_danh_ba_nhan_vien    to hrm_app;
grant execute on pkg_auth  to hrm_app;
grant execute on pkg_ctx   to hrm_app;
grant execute on pkg_admin to hrm_app;
grant execute on pkg_hr    to hrm_app;
grant execute on pkg_att   to hrm_app;
grant execute on pkg_leave to hrm_app;
grant execute on pkg_payroll to hrm_app;

-- ---------------------------------------------------------------------------
-- EXECUTE theo role (lop chan thu nhat; moi procedure tu kiem tra vai tro)
-- ---------------------------------------------------------------------------
-- doi mat khau
grant execute on pkg_auth  to r_employee;
grant execute on pkg_admin to r_admin;
grant execute on pkg_hr    to r_hr;
-- Cong, OT, nghi: moi thu tuc tu kiem tra vai tro va pham vi (dang ky cho chinh
-- minh, duyet theo muc 2.4, rut chi chu don)
grant execute on pkg_att   to r_hr, r_manager, r_employee;
grant execute on pkg_leave to r_hr, r_manager, r_employee;
-- Luong: Payroll lap, tinh, khoa; HR duyet phat sinh qua pkg_hr
grant execute on pkg_payroll to r_payroll;
-- FN-01, FN-04, FN-05: Payroll tra cuu, giai thich so tren phieu (TC-36)
grant execute on fn_tinh_thue_tncn  to r_payroll;
grant execute on fn_tinh_ot         to r_payroll;
grant execute on fn_can_cu_bao_hiem to r_payroll;

-- Tra cuu truong phong tai mot ngay (FR-ORG-03)
grant execute on fn_truong_phong_tai_ngay to r_hr, r_manager;

-- ---------------------------------------------------------------------------
-- SELECT tren view (BR-35)
-- ---------------------------------------------------------------------------
-- VW-01
grant select on vw_ho_so_nhan_vien    to r_hr, r_payroll, r_manager, r_employee;
-- VW-02
grant select on vw_phep_con_lai       to r_hr, r_manager, r_employee;
-- VW-03
grant select on vw_cong_thang         to r_hr, r_payroll, r_manager, r_employee;
-- VW-07
grant select on vw_nhan_su_phong      to r_manager;
-- VW-08
grant select on vw_don_cho_duyet      to r_hr, r_manager;
-- VW-11 (bo sung)
grant select on vw_yeu_cau_cua_toi    to r_employee;
-- VW-09
grant select on vw_tai_khoan_quan_tri to r_admin;
-- VW-10
grant select on vw_nhat_ky            to r_admin, r_hr, r_payroll;
-- VW-04
grant select on vw_bang_luong_tong_hop to r_payroll;
-- VW-05: nhan vien chi thay phieu cua minh o ky DA_KHOA (loc trong view)
grant select on vw_phieu_luong_ca_nhan to r_payroll, r_employee;
-- VW-06
grant select on vw_hop_dong_sap_het_han to r_hr;
-- VW-12, VW-14 (bo sung): pham vi loc trong view nhu VW-03
grant select on vw_qua_trinh_cong_tac   to r_hr, r_payroll, r_manager, r_employee;
grant select on vw_nghi_phep_chi_tiet   to r_hr, r_payroll, r_manager, r_employee;
-- VW-13 (bo sung): danh ba toi thieu cho Admin cap tai khoan
grant select on vw_danh_ba_nhan_vien    to r_admin;

-- ---------------------------------------------------------------------------
-- Danh muc khong nhay cam ("danh muc" trong ma tran 8.2): SELECT tren bang
-- ---------------------------------------------------------------------------
grant select on phong_ban        to r_hr, r_payroll, r_manager, r_employee;
grant select on chuc_vu          to r_hr, r_payroll, r_manager, r_employee;
grant select on loai_nghi_phep   to r_hr, r_payroll, r_manager, r_employee;
grant select on lich_lam_viec    to r_hr, r_payroll, r_manager, r_employee;
grant select on vai_tro          to r_admin;
grant select on loai_hop_dong    to r_hr, r_payroll;
grant select on loai_khoan_luong to r_hr, r_payroll;
grant select on chinh_sach_luong to r_payroll;
grant select on he_so_ot         to r_payroll;
grant select on ty_le_bao_hiem   to r_payroll;
grant select on bac_thue_tncn    to r_payroll;
-- Danh sach ky va trang thai (khong co so tien): HR chot cong, Payroll tinh/khoa
grant select on ky_luong         to r_hr, r_payroll;

-- Khong ai ngoai HRM_APP co EXECUTE tren pkg_ctx: user demo khong the tu khai
-- danh tinh (TC-07, BR-37).
