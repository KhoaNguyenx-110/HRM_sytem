-- =============================================================================
-- 14_tr03_cong_da_chot.sql - TR-03: bao ve cong da chot (dac ta muc 7.3, BR-25)
--
-- BEFORE INSERT/UPDATE/DELETE tren CHAM_CONG, DANG_KY_TANG_CA, CHI_TIET_NGHI_PHEP,
-- LICH_LAM_VIEC: tu choi neu thang cua ngay khong con o trang thai MO.
-- Day la lop bao ve thu hai sau procedure (pkg_chung.khoa_ky_mo): chan ca duong
-- ghi sai do loi lap trinh hoac do chu schema sua tay.
-- Trigger chi DOC KY_LUONG (bang khac) nen khong bi mutating table.
-- Thang chua co ky luong thi cho phep (chua co gi de bao ve).
-- =============================================================================

-- Kiem tra dung chung cho 4 trigger
create or replace procedure tr03_kiem_tra_ngay(p_ngay in date)
  authid definer
is
  v_trang_thai ky_luong.trang_thai%type;
begin
  if p_ngay is null then
    return;
  end if;
  select trang_thai into v_trang_thai
    from ky_luong
   where nam = extract(year from p_ngay) and thang = extract(month from p_ngay);
  if v_trang_thai <> 'MO' then
    raise_application_error(-20301, 'Tháng ' || to_char(p_ngay, 'MM/YYYY') || ' đã chốt công ('
      || v_trang_thai || '): không thay đổi công, nghỉ, OT, lịch (TR-03).');
  end if;
exception
  when no_data_found then
    null;
end;
/
show errors

create or replace trigger tr03_cham_cong
  before insert or update or delete on cham_cong
  for each row
begin
  tr03_kiem_tra_ngay(:old.ngay);
  tr03_kiem_tra_ngay(:new.ngay);
end;
/
show errors

-- NGAY la cot ao: lay tu BAT_DAU de khong phu thuoc gia tri cot ao trong BEFORE trigger
create or replace trigger tr03_dang_ky_tang_ca
  before insert or update or delete on dang_ky_tang_ca
  for each row
begin
  tr03_kiem_tra_ngay(trunc(cast(:old.bat_dau as date)));
  tr03_kiem_tra_ngay(trunc(cast(:new.bat_dau as date)));
end;
/
show errors

create or replace trigger tr03_chi_tiet_nghi_phep
  before insert or update or delete on chi_tiet_nghi_phep
  for each row
begin
  tr03_kiem_tra_ngay(:old.ngay);
  tr03_kiem_tra_ngay(:new.ngay);
end;
/
show errors

create or replace trigger tr03_lich_lam_viec
  before insert or update or delete on lich_lam_viec
  for each row
begin
  tr03_kiem_tra_ngay(:old.ngay);
  tr03_kiem_tra_ngay(:new.ngay);
end;
/
show errors
