-- =============================================================================
-- seed/perf/02_nhan_vien.sql - 270 nhan vien sinh them cho bo hieu nang (NV101..NV370)
--
-- Quy tac sinh (tat dinh theo so thu tu n, chay lai cho cung ket qua):
--   * Phong theo n mod 10: 0 Nhan su, 1 Ke toan, 2-5 Kinh doanh, 6-9 Ky thuat.
--     Chuc vu: n mod 3 = 0 Chuyen vien, con lai Nhan vien (khong sinh truong phong).
--   * NV101..NV270 (170 nguoi) vao lam 2016-01 -> 2023-03: co mat tu dau bo du lieu.
--     Trong do n mod 8 = 0 (21 nguoi) nghi viec cuoi mot thang trong 2024-2025.
--   * NV271..NV370 (100 nguoi) vao lam rai deu 05/2023 -> 12/2025.
--     -> ky 01/2026 co ~300 nguoi dang lam (NFR-08: tinh ky 300 nhan vien).
--   * n mod 9 = 0: dieu chuyen sang phong ke tiep tu 01/07/2024 (neu con lam).
--   * Hop dong: nguoi cu 1 HD khong thoi han; nguoi moi HD xac dinh 12 thang roi
--     HD khong thoi han. Muc luong tang 5% moi 01/01 (2024, 2025, 2026).
--   * Phu cap an trua 730.000 den 31/12/2024, 800.000 tu 01/01/2025.
--   * Tai khoan nvNNN (vai tro EMPLOYEE), KHOA neu da nghi viec.
--   * Han muc phep 12 ngay/nam cho moi nam co lam viec (ca nhan vien demo).
--   * Nguoi phu thuoc da xac minh: n mod 3 = 1 co con; n mod 6 = 1 them cha/me.
-- =============================================================================
set define off
whenever sqlerror exit failure rollback

declare
  c_hash  constant varchar2(100) := '$2b$12$DEMO.CHUA.CO.HASH.THAT.SINH.O.GIAI.DOAN.7.WEB......';
  c_dau   constant date := date '2023-04-01';
  c_cuoi  constant date := date '2026-03-31';

  type t_ma is table of varchar2(20) index by pls_integer;
  v_pb_ma t_ma;
  v_ho    sys.odcivarchar2list := sys.odcivarchar2list('Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Phan', 'Vũ', 'Đặng', 'Bùi', 'Đỗ');
  v_dem   sys.odcivarchar2list := sys.odcivarchar2list('Văn', 'Thị', 'Minh', 'Thanh', 'Quốc', 'Ngọc', 'Đức', 'Hải');
  v_ten   sys.odcivarchar2list := sys.odcivarchar2list('An', 'Bảo', 'Cường', 'Duy', 'Giang', 'Hà', 'Hiếu', 'Khoa',
                                                       'Lâm', 'Long', 'My', 'Nam', 'Nhung', 'Phát', 'Quỳnh', 'Tài',
                                                       'Thắng', 'Tú', 'Uyên', 'Yến');

  v_lhd_xd   number;
  v_lhd_kxd  number;
  v_lk_an    number;
  v_vt_nv    number;
  v_cv_cv    number;
  v_cv_nv    number;

  v_nv     number;
  v_hd     number;
  v_tk     number;
  v_ma     varchar2(20);
  v_pb     number;
  v_pb2    number;
  v_cv     number;
  v_vao    date;
  v_nghi   date;
  v_l0     number;
  v_dd     varchar2(12);

  function id_pb(p varchar2) return number is v number;
  begin select phong_ban_id into v from phong_ban where ma_phong_ban = p; return v; end;

  -- Muc luong theo tung doan [a, b] cua mot hop dong; tach tai moi 01/01, tang 5%/nam tu 2024
  procedure muc_luong(p_hd number, p_tu date, p_den date, p_l0 number) is
    a date := p_tu;
    b date;
    l number;
  begin
    while a <= nvl(p_den, c_cuoi) loop
      -- 31/12 cua nam; nguoi vao truoc 2023 giu mot doan den het 2023
      b := add_months(trunc(greatest(a, date '2023-01-01'), 'YYYY'), 12) - 1;
      if p_den is not null and b >= p_den then b := p_den; end if;
      if b > c_cuoi and p_den is null then b := null; end if;   -- doan cuoi mo
      l := round(p_l0 * power(1.05, greatest(extract(year from a) - 2023, 0)), -3);
      insert into muc_luong_hop_dong (hop_dong_id, tu_ngay, den_ngay, luong_co_ban, can_cu_dong_bao_hiem)
      values (p_hd, a, b, l, l);
      exit when b is null;
      a := b + 1;
    end loop;
  end;
begin
  v_pb_ma(0) := 'NHAN_SU';    v_pb_ma(1) := 'KE_TOAN';
  v_pb_ma(2) := 'KINH_DOANH'; v_pb_ma(3) := 'KINH_DOANH'; v_pb_ma(4) := 'KINH_DOANH'; v_pb_ma(5) := 'KINH_DOANH';
  v_pb_ma(6) := 'KY_THUAT';   v_pb_ma(7) := 'KY_THUAT';   v_pb_ma(8) := 'KY_THUAT';   v_pb_ma(9) := 'KY_THUAT';

  select loai_hop_dong_id into v_lhd_xd  from loai_hop_dong where ma_loai = 'XAC_DINH';
  select loai_hop_dong_id into v_lhd_kxd from loai_hop_dong where ma_loai = 'KHONG_XAC_DINH';
  select loai_khoan_id    into v_lk_an   from loai_khoan_luong where ma_khoan = 'PC_AN_TRUA';
  select vai_tro_id       into v_vt_nv   from vai_tro where ma_vai_tro = 'EMPLOYEE';
  select chuc_vu_id       into v_cv_cv   from chuc_vu where ma_chuc_vu = 'CHUYEN_VIEN';
  select chuc_vu_id       into v_cv_nv   from chuc_vu where ma_chuc_vu = 'NHAN_VIEN';

  for n in 101 .. 370 loop
    v_ma   := 'NV' || n;
    v_pb   := id_pb(v_pb_ma(mod(n, 10)));
    v_pb2  := id_pb(v_pb_ma(mod(n + 1, 10)));
    v_cv   := case when mod(n, 3) = 0 then v_cv_cv else v_cv_nv end;
    v_vao  := case when n <= 270 then add_months(date '2016-01-01', mod(n * 7, 87))
                   else add_months(date '2023-05-01', trunc((n - 271) * 32 / 100)) end;
    v_nghi := case when n <= 270 and mod(n, 8) = 0 then last_day(add_months(date '2024-01-01', mod(n, 22))) end;
    v_l0   := case when mod(n, 3) = 0 then 16000000 + mod(n, 7) * 1200000 else 9000000 + mod(n, 6) * 800000 end;
    v_dd   := '0793' || lpad(n, 8, '0');

    insert into nhan_vien (ma_nhan_vien, ho_ten, ngay_sinh, so_dinh_danh, ma_so_thue, email,
                           so_dien_thoai, dia_chi, ngay_vao_lam, ngay_nghi_viec)
    values (v_ma,
            v_ho(mod(n, 10) + 1) || ' ' || v_dem(mod(n * 3, 8) + 1) || ' ' || v_ten(mod(n * 7, 20) + 1),
            add_months(date '1975-01-01', mod(n * 37, 300)), v_dd, v_dd,
            lower(v_ma) || '@hrm.example.com', '08' || lpad(n * 977, 8, '0'),
            'Số ' || n || ', Quận ' || (mod(n, 12) + 1) || ', TP. Hồ Chí Minh', v_vao, v_nghi)
    returning nhan_vien_id into v_nv;

    -- Phan cong (co dieu chuyen 01/07/2024 voi n mod 9 = 0)
    if mod(n, 9) = 0 and v_vao < date '2024-07-01' and nvl(v_nghi, c_cuoi) > date '2024-07-01' then
      insert into qua_trinh_cong_tac (nhan_vien_id, phong_ban_id, chuc_vu_id, ngay_bat_dau, ngay_ket_thuc)
      values (v_nv, v_pb, v_cv, v_vao, date '2024-06-30');
      insert into qua_trinh_cong_tac (nhan_vien_id, phong_ban_id, chuc_vu_id, ngay_bat_dau, ngay_ket_thuc,
                                      can_cu_dieu_chuyen)
      values (v_nv, v_pb2, v_cv, date '2024-07-01', v_nghi, 'Điều chuyển theo kế hoạch nhân sự 2024');
    else
      insert into qua_trinh_cong_tac (nhan_vien_id, phong_ban_id, chuc_vu_id, ngay_bat_dau, ngay_ket_thuc)
      values (v_nv, v_pb, v_cv, v_vao, v_nghi);
    end if;

    -- Hop dong + muc luong
    if n <= 270 then
      insert into hop_dong (so_hop_dong, nhan_vien_id, loai_hop_dong_id, ngay_bat_dau, ngay_ket_thuc)
      values ('HD-' || v_ma || '-01', v_nv, v_lhd_kxd, v_vao, v_nghi)
      returning hop_dong_id into v_hd;
      muc_luong(v_hd, v_vao, v_nghi, v_l0);
    else
      insert into hop_dong (so_hop_dong, nhan_vien_id, loai_hop_dong_id, ngay_bat_dau, ngay_ket_thuc)
      values ('HD-' || v_ma || '-01', v_nv, v_lhd_xd, v_vao, add_months(v_vao, 12) - 1)
      returning hop_dong_id into v_hd;
      muc_luong(v_hd, v_vao, add_months(v_vao, 12) - 1, v_l0);
      if add_months(v_vao, 12) <= c_cuoi then
        insert into hop_dong (so_hop_dong, nhan_vien_id, loai_hop_dong_id, ngay_bat_dau)
        values ('HD-' || v_ma || '-02', v_nv, v_lhd_kxd, add_months(v_vao, 12))
        returning hop_dong_id into v_hd;
        muc_luong(v_hd, add_months(v_vao, 12), null, v_l0);
      end if;
    end if;

    -- Phu cap an trua (tron thang)
    if v_vao <= date '2024-12-31' then
      insert into khoan_luong_nhan_vien (nhan_vien_id, loai_khoan_id, muc_tien, tu_ngay, den_ngay)
      values (v_nv, v_lk_an, 730000, v_vao, least(date '2024-12-31', nvl(v_nghi, date '9999-12-31')));
    end if;
    if nvl(v_nghi, c_cuoi) >= date '2025-01-31' then
      insert into khoan_luong_nhan_vien (nhan_vien_id, loai_khoan_id, muc_tien, tu_ngay, den_ngay)
      values (v_nv, v_lk_an, 800000, greatest(v_vao, date '2025-01-01'), v_nghi);
    end if;

    -- Tai khoan
    insert into tai_khoan (ten_dang_nhap, mat_khau_bam, nhan_vien_id, trang_thai)
    values (lower(v_ma), c_hash, v_nv, case when v_nghi is null then 'HOAT_DONG' else 'KHOA' end)
    returning tai_khoan_id into v_tk;
    insert into tai_khoan_vai_tro (tai_khoan_id, vai_tro_id) values (v_tk, v_vt_nv);

    -- Nguoi phu thuoc
    if mod(n, 3) = 1 then
      insert into nguoi_phu_thuoc (nhan_vien_id, ho_ten, quan_he, dinh_danh_chuan_hoa, tu_ngay, den_ngay,
                                   trang_thai_xac_minh)
      values (v_nv, 'Con của ' || v_ma, 'CON', '0794' || lpad(n * 10 + 1, 8, '0'),
              greatest(v_vao, date '2023-01-01'), v_nghi, 'DA_XAC_MINH');
    end if;
    if mod(n, 6) = 1 then
      insert into nguoi_phu_thuoc (nhan_vien_id, ho_ten, quan_he, dinh_danh_chuan_hoa, tu_ngay, den_ngay,
                                   trang_thai_xac_minh)
      values (v_nv, 'Cha/mẹ của ' || v_ma, 'CHA_ME', '0794' || lpad(n * 10 + 2, 8, '0'),
              greatest(v_vao, date '2023-01-01'), v_nghi, 'DA_XAC_MINH');
    end if;
  end loop;

  -- Han muc phep 2023-2026 cho moi nguoi (ca demo) trong nam co lam viec, chua co dong
  insert into han_muc_phep_nam (nhan_vien_id, nam, so_ngay_duoc_cap)
  select n.nhan_vien_id, y.nam, 12
    from nhan_vien n
    join (select 2022 + level as nam from dual connect by level <= 4) y
      on extract(year from n.ngay_vao_lam) <= y.nam
     and extract(year from nvl(n.ngay_nghi_viec, date '9999-12-31')) >= y.nam
   where not exists (select 1 from han_muc_phep_nam h where h.nhan_vien_id = n.nhan_vien_id and h.nam = y.nam);

  commit;
end;
/
