-- =============================================================================
-- 16_fn_luong.sql - Function tinh luong (dac ta muc 7.2, muc 9)
--
--   FN-01 fn_tinh_thue_tncn   : TNTT, chinh sach -> thue luy tien tung phan
--   FN-04 fn_tinh_ot          : gio, don gia, loai ngay, chinh sach -> tien OT
--         fn_he_so_ot         : (phu tro FN-04) he so OT doc tu HE_SO_OT
--   FN-05 fn_can_cu_bao_hiem  : can cu, loai BH, chinh sach -> can cu sau san/tran
--
-- Nguyen tac: moi so lieu chinh sach doc tu bang theo PHIEN BAN (chinh_sach_id),
-- khong viet cung so bac thue, ty le hay he so trong ma. Thieu cau hinh la LOI,
-- khong tu ap dung gia tri mac dinh (muc 9.5). Function khong ghi du lieu.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- FN-01. Thue = tong tren tung bac: (phan TNTT nam trong bac) x thue suat.
--   Phan trong bac = min(TNTT, can tren) - can duoi, toi thieu 0.
--   Bac cuoi khong co can tren (NULL) -> lay TNTT.
-- Vi du 9.8: TNTT 13.928.000 -> 10.000.000 x 5% + 3.928.000 x 10% = 892.800.
-- Lam tron ve dong mot lan tren tong (thue la mot dong tien cua phieu, BR-36).
-- -----------------------------------------------------------------------------
create or replace function fn_tinh_thue_tncn(
  p_tntt          in number,
  p_chinh_sach_id in number)
  return number
  authid definer
is
  v_so_bac number;
  v_thue   number;
begin
  select count(*),
         sum(greatest(least(greatest(nvl(p_tntt, 0), 0), nvl(can_tren, greatest(nvl(p_tntt, 0), 0)))
                      - can_duoi, 0) * thue_suat)
    into v_so_bac, v_thue
    from bac_thue_tncn
   where chinh_sach_id = p_chinh_sach_id;

  if v_so_bac = 0 then
    raise_application_error(-20515, 'Chính sách ' || p_chinh_sach_id || ' chưa có biểu thuế TNCN.');
  end if;
  return round(v_thue, 0);
end;
/
show errors

-- -----------------------------------------------------------------------------
-- He so OT cua loai ngay theo phien ban chinh sach (muc 9.3)
-- -----------------------------------------------------------------------------
create or replace function fn_he_so_ot(
  p_loai_ngay     in varchar2,
  p_chinh_sach_id in number)
  return number
  authid definer
is
  v number;
begin
  select he_so into v
    from he_so_ot
   where chinh_sach_id = p_chinh_sach_id and loai_ngay = p_loai_ngay;
  return v;
exception
  when no_data_found then
    raise_application_error(-20517, 'Chính sách ' || p_chinh_sach_id
      || ' chưa có hệ số OT cho loại ngày ' || p_loai_ngay || '.');
end;
/
show errors

-- -----------------------------------------------------------------------------
-- FN-04. Tien OT = ROUND(gio x don gia x he so, 0).
-- Don gia giu nguyen do chinh xac (khong lam tron) den buoc cuoi (muc 9.9).
-- Cung cong thuc voi cot ao CHI_TIET_PHIEU_LUONG.THANH_TIEN nen dong OT tren
-- phieu luon bang FN-04.
-- -----------------------------------------------------------------------------
create or replace function fn_tinh_ot(
  p_so_gio        in number,
  p_don_gia       in number,
  p_loai_ngay     in varchar2,
  p_chinh_sach_id in number)
  return number
  authid definer
is
begin
  return round(p_so_gio * p_don_gia * fn_he_so_ot(p_loai_ngay, p_chinh_sach_id), 0);
end;
/
show errors

-- -----------------------------------------------------------------------------
-- FN-05. Can cu dong cua mot loai bao hiem = can cu hop dong dua ve [san, tran].
--   San/tran NULL = khong gioi han phia do.
--   Khong co dong TY_LE_BAO_HIEM cho loai nay -> loi (khong mac dinh 10,5% gross).
-- -----------------------------------------------------------------------------
create or replace function fn_can_cu_bao_hiem(
  p_can_cu        in number,
  p_loai_bao_hiem in varchar2,
  p_chinh_sach_id in number)
  return number
  authid definer
is
  v_san  number;
  v_tran number;
begin
  select san_dong, tran_dong into v_san, v_tran
    from ty_le_bao_hiem
   where chinh_sach_id = p_chinh_sach_id and loai_bao_hiem = p_loai_bao_hiem;
  return least(greatest(p_can_cu, nvl(v_san, p_can_cu)), nvl(v_tran, p_can_cu));
exception
  when no_data_found then
    raise_application_error(-20516, 'Chính sách ' || p_chinh_sach_id
      || ' chưa cấu hình bảo hiểm ' || p_loai_bao_hiem || '.');
end;
/
show errors
