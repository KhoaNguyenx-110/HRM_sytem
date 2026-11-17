-- =============================================================================
-- 09_tr01_audit.sql - TR-01: audit thay doi nhay cam (dac ta muc 7.3, BR-34)
--
-- Moi bang mot trigger AFTER ... FOR EACH ROW, cung goi pkg_chung.ghi_audit:
-- ghi gia tri cu/moi dang JSON vao NHAT_KY_HE_THONG trong CUNG transaction, nen
-- rollback thi audit cung mat, commit thi audit con (muc 8.5).
-- Trigger khong doc bang dang sua (tranh mutating table).
--
-- Bang: TAI_KHOAN (khong ghi MAT_KHAU_BAM), TAI_KHOAN_VAI_TRO, NHAN_VIEN, HOP_DONG,
--       MUC_LUONG_HOP_DONG, HAN_MUC_PHEP_NAM, PHAT_SINH_LUONG, KY_LUONG (trang thai),
--       PHIEU_LUONG (GD 6). Cuoi file: trigger chan sua/xoa NHAT_KY_HE_THONG.
-- TAI_KHOAN co trong danh sach vi VW-10 cua Admin can audit khoa/mo tai khoan.
-- =============================================================================

create or replace trigger tr01_tai_khoan
  after insert or update or delete on tai_khoan
  for each row
declare
  cu  json_object_t;
  moi json_object_t;
begin
  if updating or deleting then
    cu := json_object_t();
    cu.put('TEN_DANG_NHAP', :old.ten_dang_nhap);
    cu.put('NHAN_VIEN_ID', :old.nhan_vien_id);
    cu.put('ORACLE_USERNAME', :old.oracle_username);
    cu.put('TRANG_THAI', :old.trang_thai);
    cu.put('SO_LAN_DANG_NHAP_SAI', :old.so_lan_dang_nhap_sai);
  end if;
  if inserting or updating then
    moi := json_object_t();
    moi.put('TEN_DANG_NHAP', :new.ten_dang_nhap);
    moi.put('NHAN_VIEN_ID', :new.nhan_vien_id);
    moi.put('ORACLE_USERNAME', :new.oracle_username);
    moi.put('TRANG_THAI', :new.trang_thai);
    moi.put('SO_LAN_DANG_NHAP_SAI', :new.so_lan_dang_nhap_sai);
    if updating and :old.mat_khau_bam <> :new.mat_khau_bam then
      moi.put('MAT_KHAU', 'DA_DOI');   -- chi ghi su kien, khong ghi gia tri
    end if;
  end if;
  pkg_chung.ghi_audit('TAI_KHOAN', to_char(coalesce(:new.tai_khoan_id, :old.tai_khoan_id)), cu, moi);
end;
/
show errors

create or replace trigger tr01_tai_khoan_vai_tro
  after insert or update or delete on tai_khoan_vai_tro
  for each row
declare
  cu  json_object_t;
  moi json_object_t;
begin
  if updating or deleting then
    cu := json_object_t();
    cu.put('TAI_KHOAN_ID', :old.tai_khoan_id);
    cu.put('VAI_TRO_ID', :old.vai_tro_id);
    cu.put('NGAY_GAN', :old.ngay_gan);
    cu.put('NGUOI_GAN', :old.nguoi_gan);
  end if;
  if inserting or updating then
    moi := json_object_t();
    moi.put('TAI_KHOAN_ID', :new.tai_khoan_id);
    moi.put('VAI_TRO_ID', :new.vai_tro_id);
    moi.put('NGAY_GAN', :new.ngay_gan);
    moi.put('NGUOI_GAN', :new.nguoi_gan);
  end if;
  pkg_chung.ghi_audit('TAI_KHOAN_VAI_TRO',
    coalesce(:new.tai_khoan_id, :old.tai_khoan_id) || '/' || coalesce(:new.vai_tro_id, :old.vai_tro_id), cu, moi);
end;
/
show errors

create or replace trigger tr01_nhan_vien
  after insert or update or delete on nhan_vien
  for each row
declare
  cu  json_object_t;
  moi json_object_t;
begin
  if updating or deleting then
    cu := json_object_t();
    cu.put('MA_NHAN_VIEN', :old.ma_nhan_vien);
    cu.put('HO_TEN', :old.ho_ten);
    cu.put('NGAY_SINH', :old.ngay_sinh);
    cu.put('SO_DINH_DANH', :old.so_dinh_danh);
    cu.put('MA_SO_THUE', :old.ma_so_thue);
    cu.put('EMAIL', :old.email);
    cu.put('SO_DIEN_THOAI', :old.so_dien_thoai);
    cu.put('DIA_CHI', :old.dia_chi);
    cu.put('NGAY_VAO_LAM', :old.ngay_vao_lam);
    cu.put('NGAY_NGHI_VIEC', :old.ngay_nghi_viec);
  end if;
  if inserting or updating then
    moi := json_object_t();
    moi.put('MA_NHAN_VIEN', :new.ma_nhan_vien);
    moi.put('HO_TEN', :new.ho_ten);
    moi.put('NGAY_SINH', :new.ngay_sinh);
    moi.put('SO_DINH_DANH', :new.so_dinh_danh);
    moi.put('MA_SO_THUE', :new.ma_so_thue);
    moi.put('EMAIL', :new.email);
    moi.put('SO_DIEN_THOAI', :new.so_dien_thoai);
    moi.put('DIA_CHI', :new.dia_chi);
    moi.put('NGAY_VAO_LAM', :new.ngay_vao_lam);
    moi.put('NGAY_NGHI_VIEC', :new.ngay_nghi_viec);
  end if;
  pkg_chung.ghi_audit('NHAN_VIEN', to_char(coalesce(:new.nhan_vien_id, :old.nhan_vien_id)), cu, moi);
end;
/
show errors

create or replace trigger tr01_hop_dong
  after insert or update or delete on hop_dong
  for each row
declare
  cu  json_object_t;
  moi json_object_t;
begin
  if updating or deleting then
    cu := json_object_t();
    cu.put('SO_HOP_DONG', :old.so_hop_dong);
    cu.put('NHAN_VIEN_ID', :old.nhan_vien_id);
    cu.put('LOAI_HOP_DONG_ID', :old.loai_hop_dong_id);
    cu.put('NGAY_BAT_DAU', :old.ngay_bat_dau);
    cu.put('NGAY_KET_THUC', :old.ngay_ket_thuc);
    cu.put('DA_HUY', :old.da_huy);
  end if;
  if inserting or updating then
    moi := json_object_t();
    moi.put('SO_HOP_DONG', :new.so_hop_dong);
    moi.put('NHAN_VIEN_ID', :new.nhan_vien_id);
    moi.put('LOAI_HOP_DONG_ID', :new.loai_hop_dong_id);
    moi.put('NGAY_BAT_DAU', :new.ngay_bat_dau);
    moi.put('NGAY_KET_THUC', :new.ngay_ket_thuc);
    moi.put('DA_HUY', :new.da_huy);
  end if;
  pkg_chung.ghi_audit('HOP_DONG', to_char(coalesce(:new.hop_dong_id, :old.hop_dong_id)), cu, moi);
end;
/
show errors

create or replace trigger tr01_muc_luong_hop_dong
  after insert or update or delete on muc_luong_hop_dong
  for each row
declare
  cu  json_object_t;
  moi json_object_t;
begin
  if updating or deleting then
    cu := json_object_t();
    cu.put('HOP_DONG_ID', :old.hop_dong_id);
    cu.put('TU_NGAY', :old.tu_ngay);
    cu.put('DEN_NGAY', :old.den_ngay);
    cu.put('LUONG_CO_BAN', :old.luong_co_ban);
    cu.put('CAN_CU_DONG_BAO_HIEM', :old.can_cu_dong_bao_hiem);
  end if;
  if inserting or updating then
    moi := json_object_t();
    moi.put('HOP_DONG_ID', :new.hop_dong_id);
    moi.put('TU_NGAY', :new.tu_ngay);
    moi.put('DEN_NGAY', :new.den_ngay);
    moi.put('LUONG_CO_BAN', :new.luong_co_ban);
    moi.put('CAN_CU_DONG_BAO_HIEM', :new.can_cu_dong_bao_hiem);
  end if;
  pkg_chung.ghi_audit('MUC_LUONG_HOP_DONG', to_char(coalesce(:new.muc_luong_id, :old.muc_luong_id)), cu, moi);
end;
/
show errors

create or replace trigger tr01_han_muc_phep_nam
  after insert or update or delete on han_muc_phep_nam
  for each row
declare
  cu  json_object_t;
  moi json_object_t;
begin
  if updating or deleting then
    cu := json_object_t();
    cu.put('SO_NGAY_DUOC_CAP', :old.so_ngay_duoc_cap);
    cu.put('SO_NGAY_DIEU_CHINH', :old.so_ngay_dieu_chinh);
    cu.put('CAN_CU_DIEU_CHINH', :old.can_cu_dieu_chinh);
  end if;
  if inserting or updating then
    moi := json_object_t();
    moi.put('SO_NGAY_DUOC_CAP', :new.so_ngay_duoc_cap);
    moi.put('SO_NGAY_DIEU_CHINH', :new.so_ngay_dieu_chinh);
    moi.put('CAN_CU_DIEU_CHINH', :new.can_cu_dieu_chinh);
  end if;
  pkg_chung.ghi_audit('HAN_MUC_PHEP_NAM',
    coalesce(:new.nhan_vien_id, :old.nhan_vien_id) || '/' || coalesce(:new.nam, :old.nam), cu, moi);
end;
/
show errors

create or replace trigger tr01_phat_sinh_luong
  after insert or update or delete on phat_sinh_luong
  for each row
declare
  cu  json_object_t;
  moi json_object_t;
begin
  if updating or deleting then
    cu := json_object_t();
    cu.put('NHAN_VIEN_ID', :old.nhan_vien_id);
    cu.put('KY_LUONG_ID', :old.ky_luong_id);
    cu.put('LOAI_KHOAN_ID', :old.loai_khoan_id);
    cu.put('SO_TIEN', :old.so_tien);
    cu.put('CHIEU_DIEU_CHINH', :old.chieu_dieu_chinh);
    cu.put('TRANG_THAI_DUYET', :old.trang_thai_duyet);
    cu.put('NGUOI_DUYET', :old.nguoi_duyet);
  end if;
  if inserting or updating then
    moi := json_object_t();
    moi.put('NHAN_VIEN_ID', :new.nhan_vien_id);
    moi.put('KY_LUONG_ID', :new.ky_luong_id);
    moi.put('LOAI_KHOAN_ID', :new.loai_khoan_id);
    moi.put('SO_TIEN', :new.so_tien);
    moi.put('CHIEU_DIEU_CHINH', :new.chieu_dieu_chinh);
    moi.put('TRANG_THAI_DUYET', :new.trang_thai_duyet);
    moi.put('NGUOI_DUYET', :new.nguoi_duyet);
  end if;
  pkg_chung.ghi_audit('PHAT_SINH_LUONG', to_char(coalesce(:new.phat_sinh_id, :old.phat_sinh_id)), cu, moi);
end;
/
show errors

-- KY_LUONG: chi audit chuyen trang thai va phien ban (khoa ky, chot cong, tinh lai)
create or replace trigger tr01_ky_luong
  after update of trang_thai, phien_ban_da_tinh on ky_luong
  for each row
declare
  cu  json_object_t := json_object_t();
  moi json_object_t := json_object_t();
begin
  cu.put('TRANG_THAI', :old.trang_thai);
  cu.put('PHIEN_BAN_DAU_VAO', :old.phien_ban_dau_vao);
  cu.put('PHIEN_BAN_DA_TINH', :old.phien_ban_da_tinh);
  moi.put('TRANG_THAI', :new.trang_thai);
  moi.put('PHIEN_BAN_DAU_VAO', :new.phien_ban_dau_vao);
  moi.put('PHIEN_BAN_DA_TINH', :new.phien_ban_da_tinh);
  pkg_chung.ghi_audit('KY_LUONG', to_char(:new.ky_luong_id), cu, moi);
end;
/
show errors

-- PHIEU_LUONG (GD 6, NFR-11 "phieu"): chi sp_tinh_luong_ky ghi bang nay (xoa ket qua
-- cu roi them moi), nen moi lan tinh lai de lai cap DELETE/INSERT voi so tien truoc/sau.
-- Khoa ban ghi = "ky_luong_id/nhan_vien_id" (khong dung phieu_luong_id vi id doi sau
-- moi lan tinh) de tra lich su phieu cua mot nguoi trong mot ky qua IX-13.
-- Khong audit CHI_TIET_PHIEU_LUONG: tong cua phieu da du doi chieu, chi tiet tinh lai
-- duoc tu dau vao (moi dau vao deu da co audit).
create or replace trigger tr01_phieu_luong
  after insert or update or delete on phieu_luong
  for each row
declare
  cu  json_object_t;
  moi json_object_t;
begin
  if updating or deleting then
    cu := json_object_t();
    cu.put('HOP_DONG_ID', :old.hop_dong_id);
    cu.put('PHONG_BAN_ID', :old.phong_ban_id);
    cu.put('TONG_GROSS', :old.tong_gross);
    cu.put('BAO_HIEM_NLD', :old.bao_hiem_nld);
    cu.put('THUE_TNCN', :old.thue_tncn);
    cu.put('KHAU_TRU_KHAC', :old.khau_tru_khac);
    cu.put('TONG_NET', :old.tong_net);
  end if;
  if inserting or updating then
    moi := json_object_t();
    moi.put('HOP_DONG_ID', :new.hop_dong_id);
    moi.put('PHONG_BAN_ID', :new.phong_ban_id);
    moi.put('TONG_GROSS', :new.tong_gross);
    moi.put('BAO_HIEM_NLD', :new.bao_hiem_nld);
    moi.put('THUE_TNCN', :new.thue_tncn);
    moi.put('KHAU_TRU_KHAC', :new.khau_tru_khac);
    moi.put('TONG_NET', :new.tong_net);
  end if;
  pkg_chung.ghi_audit('PHIEU_LUONG',
    coalesce(:new.ky_luong_id, :old.ky_luong_id) || '/' || coalesce(:new.nhan_vien_id, :old.nhan_vien_id), cu, moi);
end;
/
show errors

-- -----------------------------------------------------------------------------
-- NHAT_KY_HE_THONG chi duoc them (NFR-15, TC-52).
--   Lop 1: role nghiep vu khong co quyen nao tren bang; VW-10 la view WITH READ ONLY.
--   Lop 2 (trigger nay): ke ca HRM_OWNER cung khong UPDATE/DELETE duoc bang lenh DML.
-- Gioi han (ghi trong bien ban): owner/DBA van co the DISABLE trigger, TRUNCATE hoac
-- DROP bang; chong lai muc nay can bang IMMUTABLE/BLOCKCHAIN hoac Unified Auditing,
-- khong dung trong do an vi lam install.sql khong chay lai duoc tren schema cu.
-- Don nhat ky qua han giu 12 thang (muc tieu thiet ke) la thao tac van hanh cua DBA.
-- -----------------------------------------------------------------------------
create or replace trigger tr01_nhat_ky_chi_them
  before update or delete on nhat_ky_he_thong
begin
  raise_application_error(-20021, 'Nhật ký hệ thống chỉ được ghi thêm, không được sửa hoặc xóa.');
end;
/
show errors
