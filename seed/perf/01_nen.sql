-- =============================================================================
-- seed/perf/01_nen.sql - Du lieu nen cho bo hieu nang (TC-54, dac ta muc 5.6, 12.3)
-- Chay bang HRM_OWNER sau seed.sql:  scripts/seed_perf.sh
--
-- Bo hieu nang = 36 ky lien tuc 04/2023 -> 03/2026 (3 nam), noi tiep du lieu demo
-- (01-03/2026). File nay tao:
--   * Lich lam viec 01/04/2023 -> 31/12/2025. Ngay le la GAN DUNG (le co dinh,
--     Tet am lich, Gio To, nghi bu chinh), chi phuc vu do hieu nang.
--   * Chinh sach 04/2023 -> 12/2025: CHEP so lieu chinh sach 2026 (KHONG phai
--     muc giam tru/bao hiem that cua 2023-2025) de bang luong lich su tinh duoc.
--   * Loai khoan luong co hieu luc tu 01/04/2023.
--   * 33 ky luong 04/2023 -> 12/2025, trang thai MO.
-- Chi dung tren CSDL thu nghiem; scripts/rebuild.sh tra ve du lieu demo.
-- =============================================================================
set define off
whenever sqlerror exit failure rollback

declare
  type t_le is table of varchar2(100) index by varchar2(10);
  v_le   t_le;
  v_ngay date := date '2023-04-01';
  v_key  varchar2(10);
begin
  -- 2023
  v_le('2023-04-29') := 'Giỗ Tổ Hùng Vương';
  v_le('2023-04-30') := 'Ngày Chiến thắng';
  v_le('2023-05-01') := 'Quốc tế Lao động';
  v_le('2023-05-02') := 'Nghỉ bù';
  v_le('2023-05-03') := 'Nghỉ bù';
  v_le('2023-09-01') := 'Quốc khánh (ngày liền kề)';
  v_le('2023-09-02') := 'Quốc khánh';
  v_le('2023-09-04') := 'Nghỉ bù Quốc khánh';
  -- 2024
  v_le('2024-01-01') := 'Tết Dương lịch';
  for i in 0 .. 6 loop
    v_le(to_char(date '2024-02-08' + i, 'YYYY-MM-DD')) := 'Tết Nguyên đán';
  end loop;
  v_le('2024-04-18') := 'Giỗ Tổ Hùng Vương';
  v_le('2024-04-29') := 'Nghỉ bù';
  v_le('2024-04-30') := 'Ngày Chiến thắng';
  v_le('2024-05-01') := 'Quốc tế Lao động';
  v_le('2024-09-02') := 'Quốc khánh';
  v_le('2024-09-03') := 'Quốc khánh (ngày liền kề)';
  -- 2025
  v_le('2025-01-01') := 'Tết Dương lịch';
  for i in 0 .. 8 loop
    v_le(to_char(date '2025-01-25' + i, 'YYYY-MM-DD')) := 'Tết Nguyên đán';
  end loop;
  v_le('2025-04-07') := 'Giỗ Tổ Hùng Vương';
  v_le('2025-04-30') := 'Ngày Chiến thắng';
  v_le('2025-05-01') := 'Quốc tế Lao động';
  v_le('2025-05-02') := 'Nghỉ bù';
  v_le('2025-09-01') := 'Quốc khánh (ngày liền kề)';
  v_le('2025-09-02') := 'Quốc khánh';

  while v_ngay < date '2026-01-01' loop
    v_key := to_char(v_ngay, 'YYYY-MM-DD');
    if v_le.exists(v_key) then
      insert into lich_lam_viec (ngay, loai_ngay, gio_quy_doi_luong, ten_ngay_le)
      values (v_ngay, 'LE', 8, v_le(v_key));
    elsif to_char(v_ngay, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN') in ('SAT', 'SUN') then
      insert into lich_lam_viec (ngay, loai_ngay, gio_quy_doi_luong)
      values (v_ngay, 'NGHI_TUAN', 0);
    else
      insert into lich_lam_viec (ngay, loai_ngay, gio_bat_dau_sang, gio_ket_thuc_sang,
                                 gio_bat_dau_chieu, gio_ket_thuc_chieu, gio_quy_doi_luong)
      values (v_ngay, 'LAM_VIEC', 8, 12, 13, 17, 8);
    end if;
    v_ngay := v_ngay + 1;
  end loop;
end;
/

-- Chinh sach 04/2023 - 12/2025: chep tu chinh sach 2026 (con cua no cung chep)
declare
  v_goc chinh_sach_luong%rowtype;
  v_cs  number;
begin
  -- INSERT ... SELECT khong cho RETURNING: doc dong goc vao bien roi INSERT ... VALUES
  select * into v_goc from chinh_sach_luong where tu_ngay = date '2026-01-01';
  insert into chinh_sach_luong (tu_ngay, den_ngay, giam_tru_ban_than, giam_tru_nguoi_phu_thuoc,
                                han_muc_ot_ngay, han_muc_ot_thang, han_muc_ot_nam, nguon_can_cu)
  values (date '2023-04-01', date '2025-12-31', v_goc.giam_tru_ban_than, v_goc.giam_tru_nguoi_phu_thuoc,
          v_goc.han_muc_ot_ngay, v_goc.han_muc_ot_thang, v_goc.han_muc_ot_nam,
          'DU LIEU HIEU NANG (TC-54): chép số liệu chính sách 2026, không phải chính sách thật 2023-2025')
  returning chinh_sach_id into v_cs;
  insert into he_so_ot       select v_cs, loai_ngay, he_so from he_so_ot where chinh_sach_id = v_goc.chinh_sach_id;
  insert into ty_le_bao_hiem select v_cs, loai_bao_hiem, ty_le_nld, ty_le_nsdld, san_dong, tran_dong, can_cu_ap_dung
                               from ty_le_bao_hiem where chinh_sach_id = v_goc.chinh_sach_id;
  insert into bac_thue_tncn  select v_cs, bac, can_duoi, can_tren, thue_suat from bac_thue_tncn where chinh_sach_id = v_goc.chinh_sach_id;
end;
/

update loai_khoan_luong set tu_ngay = date '2023-04-01' where tu_ngay > date '2023-04-01';

-- 33 ky 04/2023 -> 12/2025 (MO); chot cong / tinh / khoa bang procedure o buoc sau
insert into ky_luong (thang, nam, ngay_chi_tra_du_kien)
select extract(month from d), extract(year from d), last_day(d)
  from (select add_months(date '2023-04-01', level - 1) as d from dual connect by level <= 33);

commit;
