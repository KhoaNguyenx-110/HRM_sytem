-- =============================================================================
-- 18_tr02_tr04.sql - TR-02 bao ve ky da khoa, TR-04 bao ve chinh sach (muc 7.3)
--
-- Lop bao ve thu hai sau procedure: chan ca duong ghi sai do loi lap trinh hoac
-- do chu schema sua tay (TC-42). Trigger chi DOC bang khac (KY_LUONG,
-- PHIEU_LUONG) nen khong bi mutating table.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TR-02. Truoc khi ghi PHIEU_LUONG, CHI_TIET_PHIEU_LUONG, PHAT_SINH_LUONG:
-- tu choi neu ky cu hoac ky moi la DA_KHOA (BR-25).
-- -----------------------------------------------------------------------------
create or replace procedure tr02_kiem_tra_ky(p_ky_luong_id in number)
  authid definer
is
  v ky_luong%rowtype;
begin
  if p_ky_luong_id is null then
    return;
  end if;
  select * into v from ky_luong where ky_luong_id = p_ky_luong_id;
  if v.trang_thai = 'DA_KHOA' then
    raise_application_error(-20501, 'Kỳ ' || lpad(v.thang, 2, '0') || '/' || v.nam
      || ' đã khóa: không ghi, sửa, xóa phiếu, chi tiết, phát sinh (TR-02, BR-25).');
  end if;
exception
  when no_data_found then
    null;
end;
/
show errors

-- Ky cua mot phieu (cho trigger tren CHI_TIET_PHIEU_LUONG)
create or replace procedure tr02_kiem_tra_phieu(p_phieu_luong_id in number)
  authid definer
is
  v_ky number;
begin
  if p_phieu_luong_id is null then
    return;
  end if;
  select ky_luong_id into v_ky from phieu_luong where phieu_luong_id = p_phieu_luong_id;
  tr02_kiem_tra_ky(v_ky);
exception
  when no_data_found then
    null;
end;
/
show errors

create or replace trigger tr02_phieu_luong
  before insert or update or delete on phieu_luong
  for each row
begin
  tr02_kiem_tra_ky(:old.ky_luong_id);
  tr02_kiem_tra_ky(:new.ky_luong_id);
end;
/
show errors

create or replace trigger tr02_chi_tiet_phieu_luong
  before insert or update or delete on chi_tiet_phieu_luong
  for each row
begin
  tr02_kiem_tra_phieu(:old.phieu_luong_id);
  tr02_kiem_tra_phieu(:new.phieu_luong_id);
end;
/
show errors

create or replace trigger tr02_phat_sinh_luong
  before insert or update or delete on phat_sinh_luong
  for each row
begin
  tr02_kiem_tra_ky(:old.ky_luong_id);
  tr02_kiem_tra_ky(:new.ky_luong_id);
end;
/
show errors

-- -----------------------------------------------------------------------------
-- TR-04. Truoc khi sua/xoa CHINH_SACH_LUONG va 3 bang con: tu choi neu co ky
-- DA_KHOA da tinh bang phien ban do (BR-29: khong tinh lai lich su bang chinh
-- sach moi; so tren phieu da khoa luon giai thich duoc).
-- Ngoai le duy nhat: chi doi DEN_NGAY cua CHINH_SACH_LUONG (dong phien ban de mo
-- phien ban moi) ma cac ky da khoa van nam trong khoang hieu luc moi.
-- -----------------------------------------------------------------------------
create or replace procedure tr04_kiem_tra_chinh_sach(
  p_chinh_sach_id in number,
  p_den_ngay_moi  in date    default null,
  p_chi_doi_den   in boolean default false)
  authid definer
is
  v_ky varchar2(200);
begin
  if p_chinh_sach_id is null then
    return;
  end if;
  select listagg(lpad(thang, 2, '0') || '/' || nam, ', ') within group (order by nam, thang)
    into v_ky
    from ky_luong
   where chinh_sach_id = p_chinh_sach_id and trang_thai = 'DA_KHOA'
     and (not p_chi_doi_den
          or last_day(to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD')) > nvl(p_den_ngay_moi, date '9999-12-31'));
  if v_ky is not null then
    raise_application_error(-20509, 'Phiên bản chính sách ' || p_chinh_sach_id
      || ' đã dùng ở kỳ đã khóa (' || v_ky || '): không sửa/xóa được (TR-04, BR-29).');
  end if;
end;
/
show errors

create or replace trigger tr04_chinh_sach_luong
  before update or delete on chinh_sach_luong
  for each row
declare
  v_chi_doi_den boolean;
begin
  v_chi_doi_den := updating
    and :new.tu_ngay = :old.tu_ngay
    and :new.giam_tru_ban_than = :old.giam_tru_ban_than
    and :new.giam_tru_nguoi_phu_thuoc = :old.giam_tru_nguoi_phu_thuoc
    and :new.han_muc_ot_ngay = :old.han_muc_ot_ngay
    and :new.han_muc_ot_thang = :old.han_muc_ot_thang
    and :new.han_muc_ot_nam = :old.han_muc_ot_nam
    and :new.nguon_can_cu = :old.nguon_can_cu;
  tr04_kiem_tra_chinh_sach(:old.chinh_sach_id, :new.den_ngay, nvl(v_chi_doi_den, false));
end;
/
show errors

create or replace trigger tr04_he_so_ot
  before insert or update or delete on he_so_ot
  for each row
begin
  tr04_kiem_tra_chinh_sach(:old.chinh_sach_id);
  tr04_kiem_tra_chinh_sach(:new.chinh_sach_id);
end;
/
show errors

create or replace trigger tr04_ty_le_bao_hiem
  before insert or update or delete on ty_le_bao_hiem
  for each row
begin
  tr04_kiem_tra_chinh_sach(:old.chinh_sach_id);
  tr04_kiem_tra_chinh_sach(:new.chinh_sach_id);
end;
/
show errors

create or replace trigger tr04_bac_thue_tncn
  before insert or update or delete on bac_thue_tncn
  for each row
begin
  tr04_kiem_tra_chinh_sach(:old.chinh_sach_id);
  tr04_kiem_tra_chinh_sach(:new.chinh_sach_id);
end;
/
show errors
