-- =============================================================================
-- 06_pkg_payroll.sql - pkg_payroll: PHAN SPEC (khai bao)
--
-- Vi sao tach spec va body?
--   pkg_hr, pkg_att, pkg_leave goi pkg_payroll.danh_dau_tinh_lai nen can spec
--   co truoc khi bien dich. Body lai can FN-01/04/05 (16_fn_luong.sql) va FN-02
--   (11_fn_att.sql) nen tao sau: 17_pkg_payroll_body.sql.
--   Package khac chi phu thuoc SPEC, nen tao lai body khong lam chung INVALID.
--
-- Thu tuc (dac ta muc 7.1):
--   danh_dau_tinh_lai     co che phien ban dau vao (muc 7.7, BR-38)
--   SP-21 sp_tao_ky_luong      Payroll  FR-PAY-01
--   SP-12 sp_luu_chinh_sach    Payroll  FR-PAY-02 (+ sp_ket_thuc_chinh_sach)
--   SP-22 sp_luu_phu_cap       Payroll  FR-PAY-03
--   SP-11 sp_luu_phat_sinh     Payroll  FR-PAY-04 (HR duyet: pkg_hr.sp_duyet_phat_sinh)
--   SP-10 sp_chuyen_thuong     Payroll  FR-RWD-03
--   SP-08 sp_tinh_luong_ky     Payroll  FR-PAY-05, 06
--   SP-09 sp_khoa_ky_luong     Payroll  FR-PAY-07
--
-- Ma loi -205xx (xem dau file body). Khong thu tuc nao COMMIT.
-- =============================================================================

create or replace package pkg_payroll
  authid definer
as
  -- Goi trong CUNG transaction voi moi duong ghi lam thay doi dau vao luong:
  --   ky DA_KHOA          : tu choi ca thao tac (-20501), sai sot ghi phat sinh
  --                         dieu chinh o ky chua khoa (BR-32)
  --   ky DA_TINH          : tang PHIEN_BAN_DAU_VAO, dua ky ve CHOT_CONG
  --   ky MO, CHOT_CONG    : tang PHIEN_BAN_DAU_VAO
  -- Khoa dong cac ky giao [tu, den] theo (nam, thang) tang dan (muc 8.5).
  -- p_den_ngay NULL = den vo han.
  -- ACCESSIBLE BY: package cap cho Payroll nhung thu tuc noi bo nay chi cac
  -- package nghiep vu goi duoc (goi truc tiep -> PLS-00904 khi bien dich).
  procedure danh_dau_tinh_lai(p_tu_ngay in date, p_den_ngay in date)
    accessible by (package pkg_hr, package pkg_att, package pkg_payroll);

  -- SP-21: tao ky trang thai MO. p_ngay_chi_tra NULL = ngay cuoi thang.
  procedure sp_tao_ky_luong(
    p_thang        in  number,
    p_nam          in  number,
    p_ngay_chi_tra in  date default null,
    o_ky_luong_id  out number);

  -- SP-12: tao (p_chinh_sach_id NULL) hoac sua toan bo mot phien ban chinh sach.
  -- Ba bang con truyen dang mang JSON, vi du:
  --   p_he_so_ot : [{"loai_ngay":"LAM_VIEC","he_so":1.5}, ...]                 (du 3 loai ngay)
  --   p_bao_hiem : [{"loai":"BHXH","nld":0.08,"nsdld":0.17,"san":5310000,
  --                  "tran":46800000,"can_cu":"..."}, ...]                     (du 4 loai)
  --   p_bac_thue : [{"bac":1,"can_duoi":0,"can_tren":10000000,"thue_suat":0.05}, ...]
  -- Kiem tra: khong chong hieu luc, bac thue lien tuc, du loai bao hiem va he so
  -- OT >= muc toi thieu cua luat; phien ban da dung o ky DA_KHOA khong sua duoc.
  procedure sp_luu_chinh_sach(
    p_tu_ngay           in  date,
    p_den_ngay          in  date,
    p_giam_tru_ban_than in  number,
    p_giam_tru_npt      in  number,
    p_han_muc_ot_ngay   in  number,
    p_han_muc_ot_thang  in  number,
    p_han_muc_ot_nam    in  number,
    p_nguon_can_cu      in  varchar2,
    p_he_so_ot          in  clob,
    p_bao_hiem          in  clob,
    p_bac_thue          in  clob,
    p_chinh_sach_id     in  number default null,
    o_chinh_sach_id     out number);

  -- Dong hieu luc mot phien ban (de mo phien ban moi). Duoc phep ca khi phien ban
  -- da dung o ky DA_KHOA, mien la cac ky do van nam trong khoang moi.
  procedure sp_ket_thuc_chinh_sach(
    p_chinh_sach_id in number,
    p_den_ngay      in date);

  -- SP-22: phu cap theo nguoi/loai. Hieu luc tron thang: tu ngay 1, den cuoi thang.
  -- p_sua FALSE: them (chong cung loai -> -20518).
  -- p_sua TRUE : sua muc tien / ngay ket thuc cua ban ghi (nhan vien, loai, tu ngay).
  procedure sp_luu_phu_cap(
    p_ma_nhan_vien in varchar2,
    p_ma_khoan     in varchar2,
    p_muc_tien     in number,
    p_tu_ngay      in date,
    p_den_ngay     in date    default null,
    p_sua          in boolean default false);

  -- SP-11: phat sinh co can cu, trang thai CHO_DUYET (HR duyet).
  -- p_phieu_goc_id: bat buoc khi dieu chinh cho ky da khoa (BR-32).
  procedure sp_luu_phat_sinh(
    p_ma_nhan_vien in  varchar2,
    p_thang        in  number,
    p_nam          in  number,
    p_ma_khoan     in  varchar2,
    p_so_tien      in  number,
    p_can_cu       in  varchar2,
    p_phieu_goc_id in  number default null,
    o_phat_sinh_id out number);

  -- SP-10: chuyen thuong tien da duyet thanh phat sinh cua ky (toi da 1 lan).
  procedure sp_chuyen_thuong(
    p_so_quyet_dinh in  varchar2,
    p_thang         in  number,
    p_nam           in  number,
    o_phat_sinh_id  out number);

  -- SP-08: tinh moi hoac tinh lai ca ky trong MOT transaction.
  -- Loi cap ky (chua chot cong, thieu chinh sach, ky dang ban...) : nem ngoai le.
  -- Loi cap nhan vien (thieu muc luong, net am...) : KHONG ghi gi, ket qua cu giu
  -- nguyen, tra so loi va danh sach (giong sp_chot_cong).
  procedure sp_tinh_luong_ky(
    p_thang  in  number,
    p_nam    in  number,
    o_so_loi out number,
    o_ds_loi out clob);

  -- SP-09: khoa ky khi phien ban khop, du phieu, QR-23 tra 0 dong.
  procedure sp_khoa_ky_luong(
    p_thang in number,
    p_nam   in number);

  -- QR-23: so phieu cua ky co tong lech chi tiet (dung trong SP-08, SP-09, kiem thu)
  function so_phieu_lech(p_ky_luong_id in number) return number;
end pkg_payroll;
/
show errors
