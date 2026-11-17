-- =============================================================================
-- seed/01_catalog.sql - Du lieu danh muc va chinh sach (dac ta muc 5.5, muc 9)
-- Chay sau install.sql, bang HRM_OWNER. Chi INSERT, khong sua du lieu da co.
--
-- CAN DOI CHIEU TRUOC KHI NOP (danh dau [DOI CHIEU] ben duoi):
--   * San/tran dong bao hiem 2026 (TL-04, TL-05, TL-06)
--   * Ngay le va nghi bu 2026 (lich nghi chinh thuc cua Chinh phu)
-- Neu so lieu khac, chi sua du lieu o file nay, khong sua ma (dac ta muc 9.6).
-- =============================================================================
set define off

-- ---------------------------------------------------------------------------
-- Vai tro (5)
-- ---------------------------------------------------------------------------
insert into vai_tro (ma_vai_tro, ten_vai_tro) values ('ADMIN',    'Quản trị hệ thống');
insert into vai_tro (ma_vai_tro, ten_vai_tro) values ('HR',       'Nhân sự');
insert into vai_tro (ma_vai_tro, ten_vai_tro) values ('PAYROLL',  'Kế toán lương');
insert into vai_tro (ma_vai_tro, ten_vai_tro) values ('MANAGER',  'Trưởng phòng');
insert into vai_tro (ma_vai_tro, ten_vai_tro) values ('EMPLOYEE', 'Nhân viên');

-- ---------------------------------------------------------------------------
-- Phong ban (5) va chuc vu (4)
-- ---------------------------------------------------------------------------
insert into phong_ban (ma_phong_ban, ten_phong_ban, mo_ta) values ('BGD',        'Ban Giám đốc',    'Điều hành doanh nghiệp');
insert into phong_ban (ma_phong_ban, ten_phong_ban, mo_ta) values ('NHAN_SU',    'Phòng Nhân sự',   'Hồ sơ, hợp đồng, công, phép');
insert into phong_ban (ma_phong_ban, ten_phong_ban, mo_ta) values ('KE_TOAN',    'Phòng Kế toán',   'Tính và chi trả lương');
insert into phong_ban (ma_phong_ban, ten_phong_ban, mo_ta) values ('KINH_DOANH', 'Phòng Kinh doanh', null);
insert into phong_ban (ma_phong_ban, ten_phong_ban, mo_ta) values ('KY_THUAT',   'Phòng Kỹ thuật',  null);

insert into chuc_vu (ma_chuc_vu, ten_chuc_vu, la_quan_ly) values ('GIAM_DOC',     'Giám đốc',     true);
insert into chuc_vu (ma_chuc_vu, ten_chuc_vu, la_quan_ly) values ('TRUONG_PHONG', 'Trưởng phòng', true);
insert into chuc_vu (ma_chuc_vu, ten_chuc_vu, la_quan_ly) values ('CHUYEN_VIEN',  'Chuyên viên',  false);
insert into chuc_vu (ma_chuc_vu, ten_chuc_vu, la_quan_ly) values ('NHAN_VIEN',    'Nhân viên',    false);

-- ---------------------------------------------------------------------------
-- Loai hop dong (2) va loai nghi (3)
-- ---------------------------------------------------------------------------
insert into loai_hop_dong (ma_loai, ten_loai, yeu_cau_ngay_ket_thuc) values ('XAC_DINH',       'Xác định thời hạn',       true);
insert into loai_hop_dong (ma_loai, ten_loai, yeu_cau_ngay_ket_thuc) values ('KHONG_XAC_DINH', 'Không xác định thời hạn', false);

insert into loai_nghi_phep (ma_loai, ten_loai, tru_phep_nam, huong_luong_doanh_nghiep) values ('PHEP_NAM',    'Nghỉ phép năm',   true,  true);
insert into loai_nghi_phep (ma_loai, ten_loai, tru_phep_nam, huong_luong_doanh_nghiep) values ('KHONG_LUONG', 'Nghỉ không lương', false, false);
-- Om dau: BHXH chi tra, doanh nghiep khong tra luong cho buoi nghi
insert into loai_nghi_phep (ma_loai, ten_loai, tru_phep_nam, huong_luong_doanh_nghiep) values ('OM',          'Nghỉ ốm',         false, false);

-- ---------------------------------------------------------------------------
-- Khoan luong (16), hieu luc tu 01/01/2026
-- Cot: ma, ten, nhom, cach tinh, xu ly thue, xu ly bao hiem, tinh vao don gia OT
-- ---------------------------------------------------------------------------
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, cach_xu_ly_thue, cach_xu_ly_bao_hiem, tinh_vao_don_gia_ot, tu_ngay)
values ('LUONG_CONG', 'Lương theo công', 'THU_NHAP', 'THEO_CONG', 'CHIU_THUE', 'TINH_CAN_CU', true, date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, cach_xu_ly_thue, cach_xu_ly_bao_hiem, tinh_vao_don_gia_ot, tu_ngay)
values ('PC_TRACH_NHIEM', 'Phụ cấp trách nhiệm', 'THU_NHAP', 'THEO_THANG', 'CHIU_THUE', 'TINH_CAN_CU', true, date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, cach_xu_ly_thue, cach_xu_ly_bao_hiem, tinh_vao_don_gia_ot, tu_ngay)
values ('PC_AN_TRUA', 'Phụ cấp ăn trưa', 'THU_NHAP', 'THEO_CONG', 'CHIU_THUE', 'KHONG_TINH_CAN_CU', false, date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, cach_xu_ly_thue, cach_xu_ly_bao_hiem, tinh_vao_don_gia_ot, tu_ngay)
values ('OT', 'Tiền làm thêm giờ', 'THU_NHAP', 'THEO_GIO_OT', 'MIEN_TOAN_BO', 'KHONG_TINH_CAN_CU', false, date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, cach_xu_ly_thue, cach_xu_ly_bao_hiem, tinh_vao_don_gia_ot, tu_ngay)
values ('THUONG', 'Thưởng', 'THU_NHAP', 'THEO_PHAT_SINH', 'CHIU_THUE', 'KHONG_TINH_CAN_CU', false, date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, cach_xu_ly_thue, cach_xu_ly_bao_hiem, tinh_vao_don_gia_ot, tu_ngay)
values ('DIEU_CHINH_TANG', 'Điều chỉnh tăng thu nhập', 'THU_NHAP', 'THEO_PHAT_SINH', 'CHIU_THUE', 'KHONG_TINH_CAN_CU', false, date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, cach_xu_ly_thue, cach_xu_ly_bao_hiem, tinh_vao_don_gia_ot, tu_ngay)
values ('DIEU_CHINH_GIAM', 'Điều chỉnh giảm thu nhập', 'GIAM_THU_NHAP', 'THEO_PHAT_SINH', 'CHIU_THUE', 'KHONG_TINH_CAN_CU', false, date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('BHXH_NLD', 'BHXH người lao động', 'BAO_HIEM_NLD', 'THEO_TY_LE', date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('BHYT_NLD', 'BHYT người lao động', 'BAO_HIEM_NLD', 'THEO_TY_LE', date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('BHTN_NLD', 'BHTN người lao động', 'BAO_HIEM_NLD', 'THEO_TY_LE', date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('THUE_TNCN', 'Thuế thu nhập cá nhân', 'THUE_TNCN', 'THEO_BAC_THUE', date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('KHAU_TRU', 'Khấu trừ khác', 'KHAU_TRU', 'THEO_PHAT_SINH', date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('BHXH_NSDLD', 'BHXH doanh nghiệp đóng', 'BAO_HIEM_NSDLD', 'THEO_TY_LE', date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('BHTNLD_NSDLD', 'Bảo hiểm TNLĐ-BNN doanh nghiệp đóng', 'BAO_HIEM_NSDLD', 'THEO_TY_LE', date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('BHYT_NSDLD', 'BHYT doanh nghiệp đóng', 'BAO_HIEM_NSDLD', 'THEO_TY_LE', date '2026-01-01');
insert into loai_khoan_luong (ma_khoan, ten_khoan, nhom_khoan, cach_tinh, tu_ngay)
values ('BHTN_NSDLD', 'BHTN doanh nghiệp đóng', 'BAO_HIEM_NSDLD', 'THEO_TY_LE', date '2026-01-01');

-- ---------------------------------------------------------------------------
-- Chinh sach luong 2026 (muc 9) va 3 bang con
-- ---------------------------------------------------------------------------
declare
  v_cs number;
begin
  insert into chinh_sach_luong (
    tu_ngay, den_ngay, giam_tru_ban_than, giam_tru_nguoi_phu_thuoc,
    han_muc_ot_ngay, han_muc_ot_thang, han_muc_ot_nam, nguon_can_cu)
  values (
    date '2026-01-01', null, 15500000, 6200000,
    4, 40, 200,
    'OT: TL-01 (BLLĐ 2019 Đ.98, Đ.107), TL-02 (NĐ 145/2020 Đ.55); giảm trừ và biểu thuế: TL-03; '
    || 'bảo hiểm: TL-04, TL-05, TL-06; miễn thuế OT: TL-09 (Phụ lục A đặc tả)')
  returning chinh_sach_id into v_cs;

  -- He so OT toi thieu (muc 9.3)
  insert into he_so_ot values (v_cs, 'LAM_VIEC',  1.5);
  insert into he_so_ot values (v_cs, 'NGHI_TUAN', 2.0);
  insert into he_so_ot values (v_cs, 'LE',        3.0);

  -- Ty le bao hiem (muc 9.5). Tong NLD 10,5%, NSDLD 21,5%.
  -- [DOI CHIEU] San = luong toi thieu vung I 2026; tran BHXH/BHYT = 20 x muc tham chieu
  --             (2.340.000); tran BHTN = 20 x luong toi thieu vung I.
  insert into ty_le_bao_hiem values (v_cs, 'BHXH',   0.08,  0.17,  5310000, 46800000,
    'Sàn: lương tối thiểu vùng I; trần: 20 lần mức tham chiếu (TL-04)');
  insert into ty_le_bao_hiem values (v_cs, 'BHTNLD', 0,     0.005, 5310000, 46800000,
    'Cùng căn cứ BHXH (TL-04)');
  insert into ty_le_bao_hiem values (v_cs, 'BHYT',   0.015, 0.03,  5310000, 46800000,
    'Trần: 20 lần mức tham chiếu (TL-05)');
  insert into ty_le_bao_hiem values (v_cs, 'BHTN',   0.01,  0.01,  5310000, 106200000,
    'Trần: 20 lần lương tối thiểu vùng I (TL-06)');

  -- Bieu thue luy tien 5 bac (muc 9.7); can duoi khong tinh, can tren tinh
  insert into bac_thue_tncn values (v_cs, 1,          0,  10000000, 0.05);
  insert into bac_thue_tncn values (v_cs, 2,   10000000,  30000000, 0.10);
  insert into bac_thue_tncn values (v_cs, 3,   30000000,  60000000, 0.20);
  insert into bac_thue_tncn values (v_cs, 4,   60000000, 100000000, 0.30);
  insert into bac_thue_tncn values (v_cs, 5,  100000000,      null, 0.35);
end;
/

-- ---------------------------------------------------------------------------
-- Lich lam viec 2026: thu Hai - thu Sau 08:00-12:00, 13:00-17:00 (8 gio);
-- thu Bay, Chu nhat nghi tuan; ngay le gio quy doi 8.
-- [DOI CHIEU] Danh sach ngay le va nghi bu 2026 theo thong bao chinh thuc.
-- ---------------------------------------------------------------------------
declare
  type t_le is table of varchar2(100) index by varchar2(10);
  v_le   t_le;
  v_ngay date := date '2026-01-01';
  v_key  varchar2(10);
begin
  v_le('2026-01-01') := 'Tết Dương lịch';
  v_le('2026-02-16') := 'Tết Nguyên đán (30 Tết)';
  v_le('2026-02-17') := 'Tết Nguyên đán (mùng 1)';
  v_le('2026-02-18') := 'Tết Nguyên đán (mùng 2)';
  v_le('2026-02-19') := 'Tết Nguyên đán (mùng 3)';
  v_le('2026-02-20') := 'Tết Nguyên đán (mùng 4)';
  v_le('2026-04-27') := 'Nghỉ bù Giỗ Tổ Hùng Vương (26/4 rơi vào Chủ nhật)';
  v_le('2026-04-30') := 'Ngày Chiến thắng';
  v_le('2026-05-01') := 'Quốc tế Lao động';
  v_le('2026-09-01') := 'Quốc khánh (ngày liền kề)';
  v_le('2026-09-02') := 'Quốc khánh';

  while v_ngay < date '2027-01-01' loop
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

commit;
