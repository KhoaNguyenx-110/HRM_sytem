-- =============================================================================
-- 21_pkg_danh_muc.sql - SP-29 (bo sung v2.3, GD 7): doc danh muc cho kenh web
--
-- Vi sao can: kenh web dang nhap bang HRM_APP. Theo muc 8.1, HRM_APP "khong co
-- quyen tren bang"; v2.3 chi cap them SELECT tren cac view VW-xx (view tu loc
-- theo HRM_CTX). Danh muc (PHONG_BAN, CHUC_VU, ...) va KY_LUONG lai la BANG GOC
-- ma role R_* duoc SELECT truc tiep o kenh DBeaver. Package nay tra cac danh
-- muc do qua SYS_REFCURSOR, kiem tra vai tro GIONG HET ma tran 8.2, nen HRM_APP
-- van khong co quyen nao tren bang.
--
-- Vai tro duoc doc (khop security/10_grants.sql, muc "Danh muc"):
--   PHONG_BAN, CHUC_VU, LOAI_NGHI_PHEP, LICH_LAM_VIEC : HR, PAYROLL, MANAGER, EMPLOYEE
--   LOAI_HOP_DONG, LOAI_KHOAN_LUONG, KY_LUONG         : HR, PAYROLL
--   VAI_TRO                                           : ADMIN
-- Ma loi: -20003 chua co danh tinh phien; -20009 khong du vai tro;
--         -20022 loai danh muc khong ho tro / tham so nam khong hop le.
-- =============================================================================

create or replace package pkg_danh_muc
  authid definer
as
  -- p_loai: ten danh muc nhu tren. p_nam chi dung cho LICH_LAM_VIEC (bat buoc,
  -- tranh tra ca ngan ngay) va KY_LUONG (NULL = tat ca cac nam).
  procedure sp_tra_danh_muc(
    p_loai    in  varchar2,
    o_ket_qua out sys_refcursor,
    p_nam     in  number default null);
end pkg_danh_muc;
/
show errors

create or replace package body pkg_danh_muc
as
  procedure sp_tra_danh_muc(
    p_loai    in  varchar2,
    o_ket_qua out sys_refcursor,
    p_nam     in  number default null)
  is
    v_loai varchar2(30) := upper(trim(p_loai));
  begin
    case v_loai
      when 'PHONG_BAN' then
        pkg_chung.yeu_cau_vai_tro('HR,PAYROLL,MANAGER,EMPLOYEE');
        open o_ket_qua for
          select ma_phong_ban, ten_phong_ban, mo_ta, trang_thai
            from phong_ban order by ma_phong_ban;

      when 'CHUC_VU' then
        pkg_chung.yeu_cau_vai_tro('HR,PAYROLL,MANAGER,EMPLOYEE');
        open o_ket_qua for
          select ma_chuc_vu, ten_chuc_vu, la_quan_ly, trang_thai
            from chuc_vu order by ma_chuc_vu;

      when 'LOAI_NGHI_PHEP' then
        pkg_chung.yeu_cau_vai_tro('HR,PAYROLL,MANAGER,EMPLOYEE');
        open o_ket_qua for
          select ma_loai, ten_loai, tru_phep_nam, huong_luong_doanh_nghiep
            from loai_nghi_phep order by ma_loai;

      when 'LICH_LAM_VIEC' then
        pkg_chung.yeu_cau_vai_tro('HR,PAYROLL,MANAGER,EMPLOYEE');
        if p_nam is null or p_nam not between 2000 and 2100 then
          raise_application_error(-20022, 'Lịch làm việc cần tham số năm hợp lệ.');
        end if;
        -- Khoang ngay (khong dung EXTRACT) de dung khoa chinh NGAY (bai hoc TC-54)
        open o_ket_qua for
          select ngay, loai_ngay, so_gio_chuan, gio_quy_doi_luong, ten_ngay_le
            from lich_lam_viec
           where ngay >= to_date(p_nam || '-01-01', 'YYYY-MM-DD')
             and ngay <  to_date(p_nam + 1 || '-01-01', 'YYYY-MM-DD')
           order by ngay;

      when 'LOAI_HOP_DONG' then
        pkg_chung.yeu_cau_vai_tro('HR,PAYROLL');
        open o_ket_qua for
          select ma_loai, ten_loai, yeu_cau_ngay_ket_thuc
            from loai_hop_dong order by ma_loai;

      when 'LOAI_KHOAN_LUONG' then
        pkg_chung.yeu_cau_vai_tro('HR,PAYROLL');
        open o_ket_qua for
          select ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay, den_ngay
            from loai_khoan_luong order by nhom_khoan, ma_khoan;

      when 'KY_LUONG' then
        pkg_chung.yeu_cau_vai_tro('HR,PAYROLL');
        open o_ket_qua for
          select thang, nam, ngay_chi_tra_du_kien, trang_thai,
                 thoi_diem_chot_cong, thoi_diem_khoa,
                 -- Phieu can tinh lai khi dau vao doi sau lan tinh gan nhat
                 case when phien_ban_da_tinh is null or phien_ban_da_tinh < phien_ban_dau_vao
                      then 1 else 0 end as can_tinh_lai
            from ky_luong
           where p_nam is null or nam = p_nam
           order by nam desc, thang desc;

      when 'VAI_TRO' then
        pkg_chung.yeu_cau_vai_tro('ADMIN');
        open o_ket_qua for
          select ma_vai_tro, ten_vai_tro from vai_tro order by ma_vai_tro;

      else
        raise_application_error(-20022, 'Danh mục "' || p_loai || '" không được hỗ trợ.');
    end case;
  end sp_tra_danh_muc;
end pkg_danh_muc;
/
show errors
