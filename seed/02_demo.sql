-- =============================================================================
-- seed/02_demo.sql - Du lieu demo (dac ta muc 12.2, 12.3)
-- Chay sau seed/01_catalog.sql, bang HRM_OWNER.
--
-- Noi dung:
--   * 50 nhan vien / 5 phong; moi nhan vien mot tai khoan + U_ADMIN (51 tai khoan)
--   * 11 tai khoan anh xa user demo U_* (Oracle user tao o giai doan 3)
--   * Hop dong, muc luong, phan cong, phu cap, nguoi phu thuoc, han muc phep 2026
--   * Ky luong 01-03/2026 (trang thai MO), cong 3 thang, nghi phep, OT,
--     khen thuong, ky luat, phat sinh
--
-- Truong hop bien (muc 12.3):
--   NV_A    : dung so lieu vi du muc 9.8 (luong 26,4 trieu, OT 4 gio, 1 NPT,
--             thuong 12 trieu) -> dap an TC-36 net 35.635.200 cho ky 01/2026
--   NV049   : vao lam giua thang (15/01/2026)
--   NV050   : nghi viec giua thang (13/03/2026), tai khoan KHOA
--   NV023   : dieu chuyen Kinh doanh -> Ky thuat tu 01/02/2026 (TC-49)
--   NV047   : tang luong tu 01/03/2026
--   NV009, NV022 : hop dong xac dinh thoi han sap het han (30/11 va 10/12/2026)
--   NV001   : luong vuot tran dong bao hiem (60 trieu > 46,8 trieu)
--   NV037   : OT ngay le 18/02/2026 (he so 3,0); NV038 OT thu Bay (he so 2,0)
--   Don nghi du 4 trang thai: DA_DUYET, CHO_DUYET, TU_CHOI, DA_RUT
--
-- Mat khau: MAT_KHAU_BAM la chuoi giu cho dung dinh dang bcrypt, KHONG phai hash
-- that. Kenh DBeaver xac thuc bang Oracle user nen khong can; hash that sinh khi
-- lam giao dien web (giai doan 7).
--
-- Ghi chu ky thuat: ham khai bao trong khoi PL/SQL khong goi duoc ben trong cau
-- SQL (PLS-00231), nen moi gia tri tra cuu duoc gan vao bien truoc khi dung.
-- =============================================================================
set define off

declare
  c_hash constant varchar2(100) := '$2b$12$DEMO.CHUA.CO.HASH.THAT.SINH.O.GIAI.DOAN.7.WEB......';

  type t_ds is table of varchar2(30);
  v_ho  t_ds := t_ds('Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ',
                     'Võ', 'Đặng', 'Bùi', 'Đỗ', 'Hồ', 'Ngô', 'Dương');
  v_dem t_ds := t_ds('Văn', 'Thị', 'Minh', 'Thanh', 'Quốc', 'Ngọc', 'Hoàng', 'Thu', 'Đức', 'Hải');
  v_ten t_ds := t_ds('An', 'Bình', 'Chi', 'Dũng', 'Giang', 'Hà', 'Hải', 'Hạnh', 'Hiếu', 'Hoa',
                     'Hùng', 'Hương', 'Khánh', 'Lan', 'Linh', 'Long', 'Mai', 'Nam', 'Nga', 'Phong',
                     'Phúc', 'Quân', 'Quyên', 'Sơn', 'Tâm', 'Thảo', 'Trang', 'Trung', 'Tuấn', 'Vy');

  -- Bien dung trong than khoi (PL/SQL yeu cau khai bao bien truoc cac ham con)
  v_tk_admin  number;
  v_hr01      number;
  v_hr02      number;
  v_pay01     number;
  v_tp_ns     number;
  v_id        number;
  v_id2       number;
  v_id3       number;

  -- ---------------------------------------------------------------------------
  -- Tra cuu khoa ky thuat theo ma nghiep vu (chi dung trong lenh gan PL/SQL)
  -- ---------------------------------------------------------------------------
  function id_pb(p varchar2) return number is v number;
  begin select phong_ban_id into v from phong_ban where ma_phong_ban = p; return v; end;

  function id_cv(p varchar2) return number is v number;
  begin select chuc_vu_id into v from chuc_vu where ma_chuc_vu = p; return v; end;

  function id_lhd(p varchar2) return number is v number;
  begin select loai_hop_dong_id into v from loai_hop_dong where ma_loai = p; return v; end;

  function id_lnp(p varchar2) return number is v number;
  begin select loai_nghi_id into v from loai_nghi_phep where ma_loai = p; return v; end;

  function id_lk(p varchar2) return number is v number;
  begin select loai_khoan_id into v from loai_khoan_luong where ma_khoan = p; return v; end;

  function id_vt(p varchar2) return number is v number;
  begin select vai_tro_id into v from vai_tro where ma_vai_tro = p; return v; end;

  function id_nv(p varchar2) return number is v number;
  begin select nhan_vien_id into v from nhan_vien where ma_nhan_vien = p; return v; end;

  function id_hd(p varchar2) return number is v number;
  begin
    select h.hop_dong_id into v
      from hop_dong h join nhan_vien n on n.nhan_vien_id = h.nhan_vien_id
     where n.ma_nhan_vien = p;
    return v;
  end;

  -- Tai khoan cua nhan vien co ma p
  function id_tk(p varchar2) return number is v number;
  begin
    select t.tai_khoan_id into v
      from tai_khoan t join nhan_vien n on n.nhan_vien_id = t.nhan_vien_id
     where n.ma_nhan_vien = p;
    return v;
  end;

  function id_ky(p_thang number) return number is v number;
  begin select ky_luong_id into v from ky_luong where nam = 2026 and thang = p_thang; return v; end;

  procedure gan_vai_tro(p_tk number, p_ma_vai_tro varchar2) is
    v_vt number := id_vt(p_ma_vai_tro);
  begin
    insert into tai_khoan_vai_tro (tai_khoan_id, vai_tro_id) values (p_tk, v_vt);
  end;

  -- ---------------------------------------------------------------------------
  -- Them mot nhan vien day du: ho so, phan cong, hop dong, muc luong, phu cap,
  -- tai khoan + vai tro, han muc phep 2026.
  --   p_hd_den null  -> hop dong khong xac dinh thoi han
  --   p_vai_tro      -> vai tro them ngoai EMPLOYEE, phan cach bang dau phay
  -- ---------------------------------------------------------------------------
  procedure them_nv(
    p_n        number,
    p_ma       varchar2,
    p_pb       varchar2,
    p_cv       varchar2,
    p_luong    number,
    p_vao_lam  date,
    p_hd_den   date     default null,
    p_oracle   varchar2 default null,
    p_vai_tro  varchar2 default null)
  is
    v_nv      number;
    v_hd      number;
    v_tk      number;
    v_pb      number := id_pb(p_pb);
    v_cv      number := id_cv(p_cv);
    v_lhd     number := id_lhd(case when p_hd_den is null then 'KHONG_XAC_DINH'
                                    else 'XAC_DINH' end);
    v_lk_an   number := id_lk('PC_AN_TRUA');
    v_lk_tn   number := id_lk('PC_TRACH_NHIEM');
    v_ho_ten  varchar2(100) := v_ho(mod(p_n * 7, 15) + 1) || ' ' || v_dem(mod(p_n * 3, 10) + 1)
                               || ' ' || v_ten(mod(p_n * 11, 30) + 1);
    v_dinh_danh varchar2(12) := '0792' || lpad(p_n, 8, '0');
  begin
    insert into nhan_vien (ma_nhan_vien, ho_ten, ngay_sinh, so_dinh_danh, ma_so_thue,
                           email, so_dien_thoai, dia_chi, ngay_vao_lam)
    values (
      p_ma, v_ho_ten,
      add_months(date '1978-01-15', mod(p_n * 37, 240)),
      v_dinh_danh,
      v_dinh_danh,                         -- tu 07/2025 MST ca nhan la so dinh danh
      lower(replace(p_ma, '_', '.')) || '@hrm.example.com',
      '09' || lpad(p_n * 1371, 8, '0'),
      'Số ' || p_n || ', Quận ' || (mod(p_n, 12) + 1) || ', TP. Hồ Chí Minh',
      p_vao_lam)
    returning nhan_vien_id into v_nv;

    insert into qua_trinh_cong_tac (nhan_vien_id, phong_ban_id, chuc_vu_id, ngay_bat_dau)
    values (v_nv, v_pb, v_cv, p_vao_lam);

    insert into hop_dong (so_hop_dong, nhan_vien_id, loai_hop_dong_id, ngay_bat_dau, ngay_ket_thuc)
    values ('HD-' || p_ma || '-01', v_nv, v_lhd, p_vao_lam, p_hd_den)
    returning hop_dong_id into v_hd;

    -- Muc luong hieu luc tu ngay 1 cua thang vao lam (CHECK BR-39); gio huong luong
    -- chi tinh tu ngay vao lam nen nguoi vao giua thang van duoc tinh dung.
    insert into muc_luong_hop_dong (hop_dong_id, tu_ngay, den_ngay, luong_co_ban, can_cu_dong_bao_hiem)
    values (v_hd, trunc(p_vao_lam, 'MM'), p_hd_den, p_luong, p_luong);

    -- Phu cap: an trua cho moi nguoi (tru NV_A de khop vi du 9.8);
    -- trach nhiem cho chuc vu quan ly
    if p_ma <> 'NV_A' then
      insert into khoan_luong_nhan_vien (nhan_vien_id, loai_khoan_id, muc_tien, tu_ngay, den_ngay)
      values (v_nv, v_lk_an, 730000, p_vao_lam, p_hd_den);
    end if;
    if p_cv in ('GIAM_DOC', 'TRUONG_PHONG') then
      insert into khoan_luong_nhan_vien (nhan_vien_id, loai_khoan_id, muc_tien, tu_ngay)
      values (v_nv, v_lk_tn, case p_cv when 'GIAM_DOC' then 5000000 else 3000000 end, p_vao_lam);
    end if;

    insert into tai_khoan (ten_dang_nhap, mat_khau_bam, nhan_vien_id, oracle_username)
    values (lower(p_ma), c_hash, v_nv, p_oracle)
    returning tai_khoan_id into v_tk;

    gan_vai_tro(v_tk, 'EMPLOYEE');
    if p_vai_tro is not null then
      for i in 1 .. regexp_count(p_vai_tro, ',') + 1 loop
        gan_vai_tro(v_tk, trim(regexp_substr(p_vai_tro, '[^,]+', 1, i)));
      end loop;
    end if;

    insert into han_muc_phep_nam (nhan_vien_id, nam, so_ngay_duoc_cap)
    values (v_nv, 2026, case when p_vao_lam > date '2026-01-01' then 11 else 12 end);
  end;

  -- Nhan vien thuong (khong phai user demo): luong theo chuc vu
  procedure them_nv_thuong(p_n number, p_pb varchar2, p_vao_lam date, p_hd_den date default null) is
    v_cv varchar2(20) := case when mod(p_n, 3) = 0 then 'CHUYEN_VIEN' else 'NHAN_VIEN' end;
  begin
    them_nv(p_n, 'NV' || lpad(p_n, 3, '0'), p_pb, v_cv,
            case v_cv when 'CHUYEN_VIEN' then 16000000 + mod(p_n, 7) * 1200000
                      else 9000000 + mod(p_n, 6) * 800000 end,
            p_vao_lam, p_hd_den);
  end;

  -- ---------------------------------------------------------------------------
  -- Don nghi: tao don, chi tiet tung buoi trong cac ngay LAM_VIEC cua khoang,
  -- va lich su xu ly theo trang thai cuoi.
  --   p_buoi: CA_NGAY | SANG | CHIEU
  -- ---------------------------------------------------------------------------
  procedure don_nghi(
    p_ma          varchar2,
    p_loai        varchar2,
    p_tu          date,
    p_den         date,
    p_buoi        varchar2,
    p_trang_thai  varchar2,
    p_nguoi_duyet varchar2 default null,
    p_y_kien      varchar2 default null)
  is
    v_nv        number    := id_nv(p_ma);
    v_tk_chu    number    := id_tk(p_ma);
    v_loai      number    := id_lnp(p_loai);
    v_tk_duyet  number;
    v_don       number;
    v_hieu_luc  number    := case when p_trang_thai in ('CHO_DUYET', 'DA_DUYET') then 1 else 0 end;
    v_tao       timestamp := cast(p_tu - 5 + 9/24 as timestamp);
    v_duyet     timestamp := cast(p_tu - 4 + 14/24 as timestamp);
  begin
    if p_nguoi_duyet is not null then
      v_tk_duyet := id_tk(p_nguoi_duyet);
    end if;

    insert into don_nghi_phep (nhan_vien_id, loai_nghi_id, ly_do, trang_thai, thoi_diem_tao,
                               nguoi_duyet, thoi_diem_duyet)
    values (v_nv, v_loai,
            case p_loai when 'OM' then 'Ốm, có giấy khám bệnh' when 'KHONG_LUONG' then 'Việc gia đình'
                        else 'Nghỉ phép năm' end,
            p_trang_thai, v_tao,
            case when p_trang_thai in ('DA_DUYET', 'TU_CHOI') then v_tk_duyet end,
            case when p_trang_thai in ('DA_DUYET', 'TU_CHOI') then v_duyet end)
    returning don_nghi_id into v_don;

    insert into chi_tiet_nghi_phep (don_nghi_id, ngay, buoi, nhan_vien_id, con_hieu_luc)
    select v_don, l.ngay, b.buoi, v_nv, v_hieu_luc
      from lich_lam_viec l
     cross join (select 'SANG' as buoi from dual union all select 'CHIEU' from dual) b
     where l.ngay between p_tu and p_den
       and l.loai_ngay = 'LAM_VIEC'
       and (p_buoi = 'CA_NGAY' or b.buoi = p_buoi);

    insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, thoi_diem)
    values (v_don, 'GUI', v_tk_chu, v_tao);

    if p_trang_thai = 'DA_DUYET' then
      insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, thoi_diem, y_kien)
      values (v_don, 'DUYET', v_tk_duyet, v_duyet, p_y_kien);
    elsif p_trang_thai = 'TU_CHOI' then
      insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, thoi_diem, y_kien)
      values (v_don, 'TU_CHOI', v_tk_duyet, v_duyet, p_y_kien);
    elsif p_trang_thai = 'DA_RUT' then
      insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, thoi_diem)
      values (v_don, 'RUT', v_tk_chu, v_duyet);
    end if;
  end;

  -- ---------------------------------------------------------------------------
  -- Dang ky OT. p_gio_duyet chi dung khi DA_DUYET.
  -- ---------------------------------------------------------------------------
  procedure ot(
    p_ma          varchar2,
    p_bat_dau     timestamp,
    p_ket_thuc    timestamp,
    p_trang_thai  varchar2,
    p_nguoi_duyet varchar2 default null,
    p_gio_duyet   number   default null)
  is
    v_nv        number := id_nv(p_ma);
    v_tk_duyet  number;
  begin
    if p_trang_thai <> 'CHO_DUYET' then
      v_tk_duyet := id_tk(p_nguoi_duyet);
    end if;

    insert into dang_ky_tang_ca (nhan_vien_id, bat_dau, ket_thuc, so_gio_duoc_duyet, ly_do,
                                 trang_thai, nguoi_duyet, thoi_diem_duyet)
    values (v_nv, p_bat_dau, p_ket_thuc,
            case when p_trang_thai = 'DA_DUYET' then p_gio_duyet end,
            'Hoàn thành công việc gấp theo kế hoạch phòng',
            p_trang_thai, v_tk_duyet,
            case when p_trang_thai <> 'CHO_DUYET' then p_bat_dau - interval '1' day end);
  end;

begin
  -- ===========================================================================
  -- 1. Nhan vien, theo phong (50)
  -- ===========================================================================
  -- Ban Giam doc (3)
  them_nv(1, 'NV001', 'BGD', 'GIAM_DOC', 60000000, date '2015-03-01', null, null, 'MANAGER');
  them_nv_thuong(2, 'BGD', date '2019-06-01');
  them_nv_thuong(3, 'BGD', date '2021-09-01');

  -- Nhan su (7)
  them_nv(4, 'NV004', 'NHAN_SU', 'TRUONG_PHONG', 38000000, date '2016-05-01', null, 'U_TP_NS', 'HR,MANAGER');
  them_nv(5, 'NV005', 'NHAN_SU', 'CHUYEN_VIEN',  20000000, date '2018-02-01', null, 'U_HR01',  'HR');
  them_nv(6, 'NV006', 'NHAN_SU', 'CHUYEN_VIEN',  19000000, date '2019-08-01', null, 'U_HR02',  'HR');
  them_nv_thuong(7, 'NHAN_SU', date '2022-04-01');
  them_nv_thuong(8, 'NHAN_SU', date '2023-07-01');
  them_nv_thuong(9, 'NHAN_SU', date '2024-12-01', date '2026-11-30');   -- HD sap het han
  them_nv_thuong(10, 'NHAN_SU', date '2025-03-01', date '2027-02-28');

  -- Ke toan (8)
  them_nv(11, 'NV011', 'KE_TOAN', 'TRUONG_PHONG', 36000000, date '2016-01-01', null, null, 'MANAGER');
  them_nv(12, 'NV012', 'KE_TOAN', 'CHUYEN_VIEN',  21000000, date '2018-09-01', null, 'U_PAY01', 'PAYROLL');
  for i in 13 .. 18 loop
    them_nv_thuong(i, 'KE_TOAN', add_months(date '2019-01-01', i * 3));
  end loop;

  -- Kinh doanh (14)
  them_nv(19, 'NV019', 'KINH_DOANH', 'TRUONG_PHONG', 37000000, date '2017-04-01', null, 'U_TP_KD', 'MANAGER');
  them_nv(20, 'NV_C',  'KINH_DOANH', 'NHAN_VIEN',    14000000, date '2022-01-01', null, 'U_NV_C');
  them_nv_thuong(21, 'KINH_DOANH', date '2020-02-01');
  them_nv_thuong(22, 'KINH_DOANH', date '2025-12-01', date '2026-12-10');  -- HD sap het han
  them_nv_thuong(23, 'KINH_DOANH', date '2020-05-01');                    -- se dieu chuyen
  for i in 24 .. 32 loop
    them_nv_thuong(i, 'KINH_DOANH', add_months(date '2018-01-01', i * 2));
  end loop;

  -- Ky thuat (18)
  them_nv(33, 'NV033',   'KY_THUAT', 'TRUONG_PHONG', 40000000, date '2016-08-01', null, 'U_TP_KT', 'MANAGER');
  them_nv(34, 'NV_A',    'KY_THUAT', 'CHUYEN_VIEN',  26400000, date '2020-03-01', null, 'U_NV_A');
  them_nv(35, 'NV_B',    'KY_THUAT', 'CHUYEN_VIEN',  24000000, date '2021-06-01', null, 'U_NV_B');
  them_nv(36, 'NV_KHOA', 'KY_THUAT', 'NHAN_VIEN',    12000000, date '2022-11-01', null, 'U_NV_KHOA');
  for i in 37 .. 48 loop
    them_nv_thuong(i, 'KY_THUAT', add_months(date '2017-07-01', i * 2));
  end loop;
  them_nv_thuong(49, 'KY_THUAT', date '2026-01-15', date '2027-01-14');  -- vao giua thang
  them_nv_thuong(50, 'KY_THUAT', date '2019-10-01');                    -- nghi viec giua thang

  -- ===========================================================================
  -- 2. Tai khoan quan tri va trang thai tai khoan
  -- ===========================================================================
  insert into tai_khoan (ten_dang_nhap, mat_khau_bam, nhan_vien_id, oracle_username)
  values ('admin', c_hash, null, 'U_ADMIN')
  returning tai_khoan_id into v_tk_admin;
  gan_vai_tro(v_tk_admin, 'ADMIN');

  v_id := id_tk('NV_KHOA');
  update tai_khoan set trang_thai = 'KHOA' where tai_khoan_id = v_id;

  v_hr01  := id_tk('NV005');
  v_hr02  := id_tk('NV006');
  v_pay01 := id_tk('NV012');
  v_tp_ns := id_tk('NV004');

  -- ===========================================================================
  -- 3. Bien dong: dieu chuyen, tang luong, nghi viec, dieu chinh phep
  -- ===========================================================================
  -- NV023: Kinh doanh -> Ky thuat tu 01/02/2026
  v_id  := id_nv('NV023');
  v_id2 := id_pb('KY_THUAT');
  v_id3 := id_cv('NHAN_VIEN');
  update qua_trinh_cong_tac set ngay_ket_thuc = date '2026-01-31'
   where nhan_vien_id = v_id and ngay_ket_thuc is null;
  insert into qua_trinh_cong_tac (nhan_vien_id, phong_ban_id, chuc_vu_id, ngay_bat_dau, can_cu_dieu_chuyen)
  values (v_id, v_id2, v_id3, date '2026-02-01', 'QĐ điều chuyển 012/2026/QĐ-NS');

  -- NV047: tang luong 2 trieu tu 01/03/2026
  v_id := id_hd('NV047');
  update muc_luong_hop_dong set den_ngay = date '2026-02-28' where hop_dong_id = v_id;
  insert into muc_luong_hop_dong (hop_dong_id, tu_ngay, luong_co_ban, can_cu_dong_bao_hiem)
  select hop_dong_id, date '2026-03-01', luong_co_ban + 2000000, luong_co_ban + 2000000
    from muc_luong_hop_dong where hop_dong_id = v_id;

  -- NV050: nghi viec 13/03/2026 (cac buoc SP-18 se lam: ket thuc phan cong, khoa tai khoan)
  v_id  := id_nv('NV050');
  v_id2 := id_hd('NV050');
  v_id3 := id_tk('NV050');
  update nhan_vien             set ngay_nghi_viec = date '2026-03-13' where nhan_vien_id = v_id;
  update qua_trinh_cong_tac    set ngay_ket_thuc  = date '2026-03-13' where nhan_vien_id = v_id;
  update hop_dong              set ngay_ket_thuc  = date '2026-03-13' where hop_dong_id  = v_id2;
  update muc_luong_hop_dong    set den_ngay       = date '2026-03-13' where hop_dong_id  = v_id2;
  update khoan_luong_nhan_vien set den_ngay       = date '2026-03-13' where nhan_vien_id = v_id;
  update tai_khoan             set trang_thai     = 'KHOA'            where tai_khoan_id = v_id3;

  -- NV001: tham nien, them 2 ngay phep
  v_id := id_nv('NV001');
  update han_muc_phep_nam
     set so_ngay_dieu_chinh = 2, can_cu_dieu_chinh = 'Thâm niên đủ 10 năm (BLLĐ 2019 Điều 114)'
   where nhan_vien_id = v_id and nam = 2026;

  -- ===========================================================================
  -- 4. Nguoi phu thuoc
  -- ===========================================================================
  v_id := id_nv('NV_A');
  insert into nguoi_phu_thuoc (nhan_vien_id, ho_ten, quan_he, dinh_danh_chuan_hoa, tu_ngay, trang_thai_xac_minh)
  values (v_id, 'Phạm Minh Khôi', 'CON', '079220000034', date '2020-01-01', 'DA_XAC_MINH');
  -- NV_B: dang cho xac minh, chua duoc giam tru (TC-15)
  v_id := id_nv('NV_B');
  insert into nguoi_phu_thuoc (nhan_vien_id, ho_ten, quan_he, dinh_danh_chuan_hoa, tu_ngay, trang_thai_xac_minh)
  values (v_id, 'Lê Thu An', 'CON', '079225000035', date '2026-01-01', 'CHO_XAC_MINH');
  -- Nhan vien co so thu tu chia het cho 4: 1 con; chia het cho 12: them cha/me
  for r in (select nhan_vien_id, ma_nhan_vien, to_number(substr(ma_nhan_vien, 3)) as so
              from nhan_vien
             where regexp_like(ma_nhan_vien, '^NV[0-9]{3}$')
               and mod(to_number(substr(ma_nhan_vien, 3)), 4) = 0) loop
    insert into nguoi_phu_thuoc (nhan_vien_id, ho_ten, quan_he, dinh_danh_chuan_hoa, tu_ngay, trang_thai_xac_minh)
    values (r.nhan_vien_id, 'Con của ' || r.ma_nhan_vien, 'CON',
            '0792190' || lpad(r.so, 5, '0'), date '2022-01-01', 'DA_XAC_MINH');
    if mod(r.so, 12) = 0 then
      insert into nguoi_phu_thuoc (nhan_vien_id, ho_ten, quan_he, dinh_danh_chuan_hoa, tu_ngay, trang_thai_xac_minh)
      values (r.nhan_vien_id, 'Mẹ của ' || r.ma_nhan_vien, 'CHA_ME',
              '0011950' || lpad(r.so, 5, '0'), date '2023-01-01', 'DA_XAC_MINH');
    end if;
  end loop;

  -- ===========================================================================
  -- 5. Ky luong 01-03/2026 (MO; chot cong, tinh, khoa do procedure giai doan 4)
  -- ===========================================================================
  insert into ky_luong (thang, nam, ngay_chi_tra_du_kien) values (1, 2026, date '2026-01-30');
  insert into ky_luong (thang, nam, ngay_chi_tra_du_kien) values (2, 2026, date '2026-02-27');
  insert into ky_luong (thang, nam, ngay_chi_tra_du_kien) values (3, 2026, date '2026-03-31');

  -- ===========================================================================
  -- 6. Don nghi (nguoi duyet theo muc 2.4)
  -- ===========================================================================
  don_nghi('NV_B',  'PHEP_NAM',    date '2026-03-09', date '2026-03-10', 'CA_NGAY', 'DA_DUYET', 'NV033');
  don_nghi('NV_C',  'PHEP_NAM',    date '2026-02-05', date '2026-02-05', 'SANG',    'DA_DUYET', 'NV019');
  don_nghi('NV037', 'OM',          date '2026-01-22', date '2026-01-22', 'CA_NGAY', 'DA_DUYET', 'NV033');
  don_nghi('NV038', 'KHONG_LUONG', date '2026-03-20', date '2026-03-20', 'CHIEU',   'DA_DUYET', 'NV033');
  don_nghi('NV005', 'PHEP_NAM',    date '2026-01-27', date '2026-01-27', 'CA_NGAY', 'DA_DUYET', 'NV006');  -- HR -> HR khac
  don_nghi('NV019', 'PHEP_NAM',    date '2026-03-27', date '2026-03-27', 'CA_NGAY', 'DA_DUYET', 'NV005');  -- TP -> HR
  don_nghi('NV039', 'PHEP_NAM',    date '2026-02-24', date '2026-02-24', 'CA_NGAY', 'TU_CHOI',  'NV033',
           'Trùng lịch triển khai dự án');
  don_nghi('NV040', 'PHEP_NAM',    date '2026-03-02', date '2026-03-02', 'CA_NGAY', 'DA_RUT');
  don_nghi('NV_A',  'PHEP_NAM',    date '2026-04-13', date '2026-04-14', 'CA_NGAY', 'CHO_DUYET');  -- dang cho (VW-08)

  -- ===========================================================================
  -- 7. Lam them gio
  -- ===========================================================================
  ot('NV_A',  timestamp '2026-01-20 18:00:00', timestamp '2026-01-20 22:00:00', 'DA_DUYET', 'NV033', 4);   -- vi du 9.8
  ot('NV_B',  timestamp '2026-01-21 18:00:00', timestamp '2026-01-21 21:00:00', 'DA_DUYET', 'NV033', 3);
  ot('NV037', timestamp '2026-02-18 08:00:00', timestamp '2026-02-18 12:00:00', 'DA_DUYET', 'NV033', 4);   -- ngay le
  ot('NV024', timestamp '2026-02-26 17:30:00', timestamp '2026-02-26 20:00:00', 'DA_DUYET', 'NV019', 2.5);
  ot('NV038', timestamp '2026-03-07 08:00:00', timestamp '2026-03-07 12:00:00', 'DA_DUYET', 'NV033', 4);   -- thu Bay
  ot('NV_C',  timestamp '2026-03-12 18:00:00', timestamp '2026-03-12 20:30:00', 'DA_DUYET', 'NV019', 2);   -- duyet it hon dang ky
  ot('NV033', timestamp '2026-03-19 18:00:00', timestamp '2026-03-19 21:00:00', 'DA_DUYET', 'NV005', 3);   -- TP -> HR
  ot('NV041', timestamp '2026-03-18 18:00:00', timestamp '2026-03-18 22:00:00', 'TU_CHOI',  'NV033');
  ot('NV_B',  timestamp '2026-04-15 18:00:00', timestamp '2026-04-15 20:00:00', 'CHO_DUYET');

  -- ===========================================================================
  -- 8. Cham cong 01-03/2026: moi ngay LAM_VIEC trong thoi gian lam viec.
  --    Gio = gio chuan - gio nghi da duyet; nhan vien co ID tan cung 7 di muon
  --    30 phut moi thu Hai (khi khong nghi) de du lieu co bien dong.
  -- ===========================================================================
  insert into cham_cong (nhan_vien_id, ngay, so_gio_lam_thuc_te, trang_thai_xac_nhan, nguoi_xac_nhan)
  select n.nhan_vien_id, l.ngay,
         l.so_gio_chuan - nvl(np.gio_nghi, 0)
           - case when np.gio_nghi is null and mod(n.nhan_vien_id, 10) = 7
                   and to_char(l.ngay, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN') = 'MON' then 0.5 else 0 end,
         'DA_XAC_NHAN', v_hr01
    from nhan_vien n
    join lich_lam_viec l
      on l.loai_ngay = 'LAM_VIEC'
     and l.ngay between date '2026-01-01' and date '2026-03-31'
     and l.ngay >= n.ngay_vao_lam
     and (n.ngay_nghi_viec is null or l.ngay <= n.ngay_nghi_viec)
    left join (
      select c.nhan_vien_id, c.ngay,
             sum(case c.buoi when 'SANG' then l2.gio_ket_thuc_sang - l2.gio_bat_dau_sang
                             else l2.gio_ket_thuc_chieu - l2.gio_bat_dau_chieu end) as gio_nghi
        from chi_tiet_nghi_phep c
        join don_nghi_phep d on d.don_nghi_id = c.don_nghi_id and d.trang_thai = 'DA_DUYET'
        join lich_lam_viec l2 on l2.ngay = c.ngay
       group by c.nhan_vien_id, c.ngay) np
      on np.nhan_vien_id = n.nhan_vien_id and np.ngay = l.ngay;

  -- ===========================================================================
  -- 9. Khen thuong, ky luat, phat sinh luong
  -- ===========================================================================
  -- Thuong tien da duyet cho NV_A (vi du 9.8); chuyen sang luong bang SP-10 o giai doan 4
  v_id := id_nv('NV_A');
  insert into khen_thuong (nhan_vien_id, so_quyet_dinh, ngay_quyet_dinh, ly_do, hinh_thuc, so_tien,
                           nguoi_tao, trang_thai_duyet, nguoi_duyet, thoi_diem_duyet)
  values (v_id, '001/2026/QĐ-KT', date '2026-01-20', 'Hoàn thành dự án ERP trước hạn', 'TIEN', 12000000,
          v_hr01, 'DA_DUYET', v_hr02, timestamp '2026-01-21 10:00:00');

  v_id := id_nv('NV019');
  insert into khen_thuong (nhan_vien_id, so_quyet_dinh, ngay_quyet_dinh, ly_do, hinh_thuc,
                           nguoi_tao, trang_thai_duyet, nguoi_duyet, thoi_diem_duyet)
  values (v_id, '002/2026/QĐ-KT', date '2026-02-05', 'Phòng đạt doanh số quý IV/2025', 'GIAY_KHEN',
          v_hr01, 'DA_DUYET', v_hr02, timestamp '2026-02-06 09:00:00');

  -- Dang cho duyet, do U_HR01 tao (TC-44: HR01 khong duoc tu duyet)
  v_id := id_nv('NV024');
  insert into khen_thuong (nhan_vien_id, so_quyet_dinh, ngay_quyet_dinh, ly_do, hinh_thuc, so_tien, nguoi_tao)
  values (v_id, '003/2026/QĐ-KT', date '2026-03-10', 'Ký hợp đồng khách hàng lớn', 'TIEN', 3000000, v_hr01);

  v_id := id_nv('NV042');
  insert into ky_luat (nhan_vien_id, so_quyet_dinh, ngay_quyet_dinh, ly_do, hinh_thuc, nguoi_tao, nguoi_phe_duyet)
  values (v_id, '001/2026/QĐ-KL', date '2026-02-10', 'Đi muộn nhiều lần không có lý do', 'KHIEN_TRACH',
          v_hr01, v_tp_ns);

  v_id  := id_nv('NV016');
  v_id2 := id_ky(1);
  v_id3 := id_lk('DIEU_CHINH_TANG');
  insert into phat_sinh_luong (nhan_vien_id, ky_luong_id, loai_khoan_id, so_tien, chieu_dieu_chinh, can_cu,
                               nguoi_tao, trang_thai_duyet, nguoi_duyet)
  values (v_id, v_id2, v_id3, 300000, 'TANG', 'Truy lĩnh phụ cấp ăn trưa tháng 12/2025',
          v_pay01, 'DA_DUYET', v_hr02);

  -- Chua duyet: khong duoc tinh (TC-34)
  v_id  := id_nv('NV015');
  v_id2 := id_ky(2);
  v_id3 := id_lk('THUONG');
  insert into phat_sinh_luong (nhan_vien_id, ky_luong_id, loai_khoan_id, so_tien, chieu_dieu_chinh, can_cu, nguoi_tao)
  values (v_id, v_id2, v_id3, 2000000, 'TANG', 'Thưởng doanh số tháng 02/2026', v_pay01);

  v_id  := id_nv('NV014');
  v_id2 := id_ky(3);
  v_id3 := id_lk('KHAU_TRU');
  insert into phat_sinh_luong (nhan_vien_id, ky_luong_id, loai_khoan_id, so_tien, chieu_dieu_chinh, can_cu,
                               nguoi_tao, trang_thai_duyet, nguoi_duyet)
  values (v_id, v_id2, v_id3, 500000, 'GIAM', 'Bồi thường thiết bị hỏng theo biên bản 05/03/2026',
          v_pay01, 'DA_DUYET', v_hr02);

  commit;
end;
/
