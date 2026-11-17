-- =============================================================================
-- 02_tables.sql - 32 bang (tu dien du lieu muc 3-6)
-- Bang tao kem PK, UK, CHECK. FK nam o 03_foreign_keys.sql de khong phu thuoc
-- thu tu tao bang. Index bo sung nam o 04_indexes.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- NHOM A - TAI KHOAN VA TO CHUC
-- ---------------------------------------------------------------------------

create table tai_khoan (
  tai_khoan_id          number generated always as identity,
  ten_dang_nhap         varchar2(50)  not null,
  mat_khau_bam          varchar2(255) not null,
  nhan_vien_id          number,
  oracle_username       varchar2(128),
  trang_thai            varchar2(10)  default 'HOAT_DONG' not null,
  so_lan_dang_nhap_sai  number(2)     default 0 not null,
  thoi_diem_tao         timestamp     default systimestamp not null,
  constraint pk_tai_khoan primary key (tai_khoan_id),
  constraint uk_tai_khoan_nv unique (nhan_vien_id),
  constraint uk_tai_khoan_oracle_user unique (oracle_username),
  constraint ck_tai_khoan_ten check (regexp_like(ten_dang_nhap, '^[A-Za-z0-9._]{3,50}$')),
  constraint ck_tai_khoan_mat_khau check (mat_khau_bam like '$2%' or mat_khau_bam like '$argon2%'),
  constraint ck_tai_khoan_oracle_user check (oracle_username = upper(oracle_username)),
  constraint ck_tai_khoan_trang_thai check (trang_thai in ('HOAT_DONG', 'KHOA')),
  constraint ck_tai_khoan_sai check (so_lan_dang_nhap_sai >= 0)
);

create table vai_tro (
  vai_tro_id   number generated always as identity,
  ma_vai_tro   d_ma not null,
  ten_vai_tro  varchar2(100) not null,
  constraint pk_vai_tro primary key (vai_tro_id),
  constraint uk_vai_tro_ma unique (ma_vai_tro),
  constraint ck_vai_tro_ma check (ma_vai_tro in ('ADMIN', 'HR', 'PAYROLL', 'MANAGER', 'EMPLOYEE'))
);

create table tai_khoan_vai_tro (
  tai_khoan_id  number not null,
  vai_tro_id    number not null,
  ngay_gan      d_ngay default trunc(sysdate) not null,
  nguoi_gan     number,
  constraint pk_tai_khoan_vai_tro primary key (tai_khoan_id, vai_tro_id)
);

create table phong_ban (
  phong_ban_id   number generated always as identity,
  ma_phong_ban   d_ma not null,
  ten_phong_ban  varchar2(100) not null,
  mo_ta          varchar2(500),
  trang_thai     varchar2(10) default 'HOAT_DONG' not null,
  constraint pk_phong_ban primary key (phong_ban_id),
  constraint uk_phong_ban_ma unique (ma_phong_ban),
  constraint ck_phong_ban_trang_thai check (trang_thai in ('HOAT_DONG', 'NGUNG'))
);

create table chuc_vu (
  chuc_vu_id   number generated always as identity,
  ma_chuc_vu   d_ma not null,
  ten_chuc_vu  varchar2(100) not null,
  la_quan_ly   boolean default false not null,
  trang_thai   varchar2(10) default 'HOAT_DONG' not null,
  constraint pk_chuc_vu primary key (chuc_vu_id),
  constraint uk_chuc_vu_ma unique (ma_chuc_vu),
  constraint ck_chuc_vu_trang_thai check (trang_thai in ('HOAT_DONG', 'NGUNG'))
);

create table nhat_ky_he_thong (
  nhat_ky_id       number generated always as identity,
  tai_khoan_id     number,
  oracle_username  varchar2(128) default sys_context('USERENV', 'SESSION_USER') not null,
  doi_tuong        varchar2(30)  not null,
  khoa_ban_ghi     varchar2(100) not null,
  thao_tac         varchar2(6)   not null,
  gia_tri_cu       json,
  gia_tri_moi      json,
  thoi_diem        timestamp default systimestamp not null,
  constraint pk_nhat_ky_he_thong primary key (nhat_ky_id),
  constraint ck_nhat_ky_thao_tac check (thao_tac in ('INSERT', 'UPDATE', 'DELETE')),
  constraint ck_nhat_ky_gia_tri check (
       (thao_tac = 'INSERT' and gia_tri_cu is null     and gia_tri_moi is not null)
    or (thao_tac = 'DELETE' and gia_tri_cu is not null and gia_tri_moi is null)
    or (thao_tac = 'UPDATE' and gia_tri_cu is not null and gia_tri_moi is not null))
);

-- ---------------------------------------------------------------------------
-- NHOM B - HO SO, HOP DONG, QUYET DINH
-- ---------------------------------------------------------------------------

create table nhan_vien (
  nhan_vien_id    number generated always as identity,
  ma_nhan_vien    d_ma not null,
  ho_ten          varchar2(100) not null,
  ngay_sinh       d_ngay not null,
  so_dinh_danh    varchar2(12) not null,
  ma_so_thue      varchar2(13),
  email           varchar2(100),
  so_dien_thoai   varchar2(15),
  dia_chi         varchar2(255),
  ngay_vao_lam    d_ngay not null,
  ngay_nghi_viec  d_ngay,
  constraint pk_nhan_vien primary key (nhan_vien_id),
  constraint uk_nhan_vien_ma unique (ma_nhan_vien),
  constraint uk_nhan_vien_dinh_danh unique (so_dinh_danh),
  constraint uk_nhan_vien_mst unique (ma_so_thue),
  constraint ck_nhan_vien_dinh_danh check (regexp_like(so_dinh_danh, '^[0-9]{12}$')),
  constraint ck_nhan_vien_mst check (regexp_like(ma_so_thue, '^[0-9]{10,13}$')),
  constraint ck_nhan_vien_email check (regexp_like(email, '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')),
  constraint ck_nhan_vien_sdt check (regexp_like(so_dien_thoai, '^\+?[0-9]{8,14}$')),
  constraint ck_nhan_vien_ngay_nghi check (ngay_nghi_viec >= ngay_vao_lam),
  constraint ck_nhan_vien_tuoi check (ngay_vao_lam >= add_months(ngay_sinh, 180))
);

create table qua_trinh_cong_tac (
  cong_tac_id         number generated always as identity,
  nhan_vien_id        number not null,
  phong_ban_id        number not null,
  chuc_vu_id          number not null,
  ngay_bat_dau        d_ngay not null,
  ngay_ket_thuc       d_ngay,
  can_cu_dieu_chuyen  varchar2(255),
  constraint pk_qua_trinh_cong_tac primary key (cong_tac_id),
  constraint uk_qtct_nv_ngay unique (nhan_vien_id, ngay_bat_dau),
  constraint ck_qtct_ngay check (ngay_ket_thuc >= ngay_bat_dau)
);

create table loai_hop_dong (
  loai_hop_dong_id       number generated always as identity,
  ma_loai                d_ma not null,
  ten_loai               varchar2(100) not null,
  yeu_cau_ngay_ket_thuc  boolean not null,
  constraint pk_loai_hop_dong primary key (loai_hop_dong_id),
  constraint uk_loai_hop_dong_ma unique (ma_loai)
);

create table hop_dong (
  hop_dong_id       number generated always as identity,
  so_hop_dong       varchar2(30) not null,
  nhan_vien_id      number not null,
  loai_hop_dong_id  number not null,
  ngay_bat_dau      d_ngay not null,
  ngay_ket_thuc     d_ngay,
  da_huy            boolean default false not null,
  constraint pk_hop_dong primary key (hop_dong_id),
  constraint uk_hop_dong_so unique (so_hop_dong),
  constraint uk_hop_dong_nv unique (hop_dong_id, nhan_vien_id),
  constraint ck_hop_dong_ngay check (ngay_ket_thuc > ngay_bat_dau)
);

create table muc_luong_hop_dong (
  muc_luong_id          number generated always as identity,
  hop_dong_id           number not null,
  tu_ngay               d_ngay not null,
  den_ngay              d_ngay,
  luong_co_ban          d_tien not null,
  can_cu_dong_bao_hiem  d_tien not null,
  constraint pk_muc_luong_hop_dong primary key (muc_luong_id),
  constraint uk_mlhd_hd_tu_ngay unique (hop_dong_id, tu_ngay),
  constraint ck_mlhd_ngay_1 check (tu_ngay = trunc(tu_ngay, 'MM')),
  constraint ck_mlhd_ngay check (den_ngay >= tu_ngay),
  constraint ck_mlhd_luong check (luong_co_ban > 0)
);

create table nguoi_phu_thuoc (
  nguoi_phu_thuoc_id   number generated always as identity,
  nhan_vien_id         number not null,
  ho_ten               varchar2(100) not null,
  quan_he              varchar2(10) not null,
  dinh_danh_chuan_hoa  varchar2(20) not null,
  tu_ngay              d_ngay not null,
  den_ngay             d_ngay,
  trang_thai_xac_minh  varchar2(12) default 'CHO_XAC_MINH' not null,
  constraint pk_nguoi_phu_thuoc primary key (nguoi_phu_thuoc_id),
  constraint ck_npt_quan_he check (quan_he in ('CON', 'VO_CHONG', 'CHA_ME', 'KHAC')),
  constraint ck_npt_dinh_danh check (regexp_like(dinh_danh_chuan_hoa, '^[A-Z0-9]+$')),
  constraint ck_npt_ngay check (den_ngay >= tu_ngay),
  constraint ck_npt_xac_minh check (trang_thai_xac_minh in ('CHO_XAC_MINH', 'DA_XAC_MINH', 'TU_CHOI'))
);

create table khen_thuong (
  khen_thuong_id    number generated always as identity,
  nhan_vien_id      number not null,
  so_quyet_dinh     varchar2(30) not null,
  ngay_quyet_dinh   d_ngay not null,
  ly_do             varchar2(500) not null,
  hinh_thuc         varchar2(10) not null,
  so_tien           d_tien,
  nguoi_tao         number not null,
  trang_thai_duyet  varchar2(10) default 'CHO_DUYET' not null,
  nguoi_duyet       number,
  thoi_diem_duyet   timestamp,
  ly_do_tu_choi     varchar2(500),
  constraint pk_khen_thuong primary key (khen_thuong_id),
  constraint uk_kt_so_quyet_dinh unique (so_quyet_dinh),
  constraint uk_kt_nv unique (khen_thuong_id, nhan_vien_id),
  constraint ck_kt_hinh_thuc check (hinh_thuc in ('TIEN', 'GIAY_KHEN', 'KHAC')),
  constraint ck_kt_so_tien check (
       (hinh_thuc = 'TIEN' and so_tien > 0)
    or (hinh_thuc <> 'TIEN' and so_tien is null)),
  constraint ck_kt_trang_thai check (trang_thai_duyet in ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI')),
  constraint ck_kt_duyet check (
       (trang_thai_duyet = 'CHO_DUYET' and nguoi_duyet is null and thoi_diem_duyet is null and ly_do_tu_choi is null)
    or (trang_thai_duyet = 'DA_DUYET'  and nguoi_duyet is not null and thoi_diem_duyet is not null and ly_do_tu_choi is null)
    or (trang_thai_duyet = 'TU_CHOI'   and nguoi_duyet is not null and thoi_diem_duyet is not null and ly_do_tu_choi is not null)),
  constraint ck_kt_khong_tu_duyet check (nguoi_duyet <> nguoi_tao)
);

create table ky_luat (
  ky_luat_id       number generated always as identity,
  nhan_vien_id     number not null,
  so_quyet_dinh    varchar2(30) not null,
  ngay_quyet_dinh  d_ngay not null,
  ly_do            varchar2(500) not null,
  hinh_thuc        varchar2(20) not null,
  nguoi_tao        number not null,
  nguoi_phe_duyet  number,
  constraint pk_ky_luat primary key (ky_luat_id),
  constraint uk_kl_so_quyet_dinh unique (so_quyet_dinh),
  constraint ck_kl_hinh_thuc check (hinh_thuc in ('KHIEN_TRACH', 'KEO_DAI_NANG_LUONG', 'CACH_CHUC', 'SA_THAI')),
  constraint ck_kl_khong_tu_duyet check (nguoi_phe_duyet <> nguoi_tao)
);

-- ---------------------------------------------------------------------------
-- NHOM C - CONG, OT, NGHI PHEP
-- ---------------------------------------------------------------------------

create table lich_lam_viec (
  ngay                d_ngay not null,
  loai_ngay           varchar2(10) not null,
  gio_bat_dau_sang    number(4,2),
  gio_ket_thuc_sang   number(4,2),
  gio_bat_dau_chieu   number(4,2),
  gio_ket_thuc_chieu  number(4,2),
  so_gio_chuan        number(5,2) generated always as (
                        nvl(gio_ket_thuc_sang - gio_bat_dau_sang, 0)
                      + nvl(gio_ket_thuc_chieu - gio_bat_dau_chieu, 0)) virtual,
  gio_quy_doi_luong   d_gio not null,
  ten_ngay_le         varchar2(100),
  constraint pk_lich_lam_viec primary key (ngay),
  constraint ck_lich_loai_ngay check (loai_ngay in ('LAM_VIEC', 'NGHI_TUAN', 'LE')),
  constraint ck_lich_gio_pham_vi check (
        gio_bat_dau_sang   between 0 and 24 and gio_ket_thuc_sang  between 0 and 24
    and gio_bat_dau_chieu  between 0 and 24 and gio_ket_thuc_chieu between 0 and 24),
  constraint ck_lich_buoi check (
        ((gio_bat_dau_sang is null and gio_ket_thuc_sang is null)
          or (gio_bat_dau_sang is not null and gio_ket_thuc_sang is not null and gio_bat_dau_sang < gio_ket_thuc_sang))
    and ((gio_bat_dau_chieu is null and gio_ket_thuc_chieu is null)
          or (gio_bat_dau_chieu is not null and gio_ket_thuc_chieu is not null and gio_bat_dau_chieu < gio_ket_thuc_chieu))
    and (gio_ket_thuc_sang is null or gio_bat_dau_chieu is null or gio_ket_thuc_sang <= gio_bat_dau_chieu)),
  constraint ck_lich_loai check (
       (loai_ngay = 'LAM_VIEC'
          and (gio_bat_dau_sang is not null or gio_bat_dau_chieu is not null)
          and gio_quy_doi_luong = so_gio_chuan)
    or (loai_ngay = 'NGHI_TUAN'
          and gio_bat_dau_sang is null and gio_bat_dau_chieu is null and gio_quy_doi_luong = 0)
    or (loai_ngay = 'LE'
          and gio_bat_dau_sang is null and gio_bat_dau_chieu is null)),
  constraint ck_lich_ten_le check (
       (loai_ngay = 'LE' and ten_ngay_le is not null)
    or (loai_ngay <> 'LE' and ten_ngay_le is null))
);

create table cham_cong (
  cham_cong_id         number generated always as identity,
  nhan_vien_id         number not null,
  ngay                 d_ngay not null,
  so_gio_lam_thuc_te   d_gio not null,
  trang_thai_xac_nhan  varchar2(13) default 'CHUA_XAC_NHAN' not null,
  nguoi_xac_nhan       number,
  constraint pk_cham_cong primary key (cham_cong_id),
  constraint uk_cham_cong_nv_ngay unique (nhan_vien_id, ngay),
  constraint ck_cc_gio check (so_gio_lam_thuc_te <= 24),
  constraint ck_cc_trang_thai check (trang_thai_xac_nhan in ('CHUA_XAC_NHAN', 'DA_XAC_NHAN')),
  constraint ck_cc_xac_nhan check (
       (trang_thai_xac_nhan = 'CHUA_XAC_NHAN' and nguoi_xac_nhan is null)
    or (trang_thai_xac_nhan = 'DA_XAC_NHAN'   and nguoi_xac_nhan is not null))
);

create table dang_ky_tang_ca (
  tang_ca_id         number generated always as identity,
  nhan_vien_id       number not null,
  bat_dau            timestamp(0) not null,
  ket_thuc           timestamp(0) not null,
  ngay               date generated always as (trunc(cast(bat_dau as date))) virtual,
  so_gio_duoc_duyet  d_gio,
  ly_do              varchar2(500) not null,
  trang_thai         varchar2(10) default 'CHO_DUYET' not null,
  nguoi_duyet        number,
  thoi_diem_duyet    timestamp,
  constraint pk_dang_ky_tang_ca primary key (tang_ca_id),
  constraint ck_ot_khoang check (ket_thuc > bat_dau),
  constraint ck_ot_ban_ngay check (
        cast(bat_dau as date)  >= ngay + 6/24
    and cast(ket_thuc as date) <= ngay + 22/24),
  constraint ck_ot_gio_duyet check (
        so_gio_duoc_duyet <= (cast(ket_thuc as date) - cast(bat_dau as date)) * 24),
  constraint ck_ot_trang_thai check (trang_thai in ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI')),
  constraint ck_ot_duyet check (
       (trang_thai = 'CHO_DUYET' and nguoi_duyet is null and thoi_diem_duyet is null and so_gio_duoc_duyet is null)
    or (trang_thai = 'DA_DUYET'  and nguoi_duyet is not null and thoi_diem_duyet is not null and so_gio_duoc_duyet > 0)
    or (trang_thai = 'TU_CHOI'   and nguoi_duyet is not null and thoi_diem_duyet is not null and so_gio_duoc_duyet is null))
);

create table loai_nghi_phep (
  loai_nghi_id               number generated always as identity,
  ma_loai                    d_ma not null,
  ten_loai                   varchar2(100) not null,
  tru_phep_nam               boolean not null,
  huong_luong_doanh_nghiep   boolean not null,
  constraint pk_loai_nghi_phep primary key (loai_nghi_id),
  constraint uk_loai_nghi_phep_ma unique (ma_loai)
);

create table don_nghi_phep (
  don_nghi_id      number generated always as identity,
  nhan_vien_id     number not null,
  loai_nghi_id     number not null,
  ly_do            varchar2(500) not null,
  trang_thai       varchar2(10) default 'CHO_DUYET' not null,
  thoi_diem_tao    timestamp default systimestamp not null,
  nguoi_duyet      number,
  thoi_diem_duyet  timestamp,
  constraint pk_don_nghi_phep primary key (don_nghi_id),
  constraint uk_don_nv unique (don_nghi_id, nhan_vien_id),
  constraint ck_don_trang_thai check (trang_thai in ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI', 'DA_RUT')),
  constraint ck_don_duyet check (
       (trang_thai in ('CHO_DUYET', 'DA_RUT') and nguoi_duyet is null and thoi_diem_duyet is null)
    or (trang_thai in ('DA_DUYET', 'TU_CHOI') and nguoi_duyet is not null and thoi_diem_duyet is not null))
);

create table chi_tiet_nghi_phep (
  don_nghi_id   number not null,
  ngay          d_ngay not null,
  buoi          varchar2(5) not null,
  nhan_vien_id  number not null,
  con_hieu_luc  number(1) default 1 not null,
  constraint pk_chi_tiet_nghi_phep primary key (don_nghi_id, ngay, buoi),
  constraint ck_ctnp_buoi check (buoi in ('SANG', 'CHIEU')),
  constraint ck_ctnp_hieu_luc check (con_hieu_luc in (0, 1))
);

create table han_muc_phep_nam (
  nhan_vien_id        number not null,
  nam                 number(4) not null,
  so_ngay_duoc_cap    number(4,1) not null,
  so_ngay_dieu_chinh  number(4,1) default 0 not null,
  can_cu_dieu_chinh   varchar2(255),
  constraint pk_han_muc_phep_nam primary key (nhan_vien_id, nam),
  constraint ck_hmpn_nam check (nam between 2000 and 2100),
  constraint ck_hmpn_cap check (so_ngay_duoc_cap >= 0),
  constraint ck_hmpn_tong check (so_ngay_duoc_cap + so_ngay_dieu_chinh >= 0),
  constraint ck_hmpn_can_cu check (so_ngay_dieu_chinh = 0 or can_cu_dieu_chinh is not null)
);

create table lich_su_duyet_nghi (
  lich_su_id   number generated always as identity,
  don_nghi_id  number not null,
  hanh_dong    varchar2(8) not null,
  nguoi_xu_ly  number not null,
  thoi_diem    timestamp default systimestamp not null,
  y_kien       varchar2(500),
  constraint pk_lich_su_duyet_nghi primary key (lich_su_id),
  constraint ck_lsdn_hanh_dong check (hanh_dong in ('GUI', 'DUYET', 'TU_CHOI', 'RUT')),
  constraint ck_lsdn_ly_do check (hanh_dong <> 'TU_CHOI' or y_kien is not null)
);

-- ---------------------------------------------------------------------------
-- NHOM D - LUONG VA CHINH SACH
-- ---------------------------------------------------------------------------

create table ky_luong (
  ky_luong_id           number generated always as identity,
  thang                 number(2) not null,
  nam                   number(4) not null,
  ngay_chi_tra_du_kien  d_ngay not null,
  trang_thai            varchar2(10) default 'MO' not null,
  phien_ban_dau_vao     number(10) default 0 not null,
  phien_ban_da_tinh     number(10),
  chinh_sach_id         number,
  nguoi_chot_cong       number,
  thoi_diem_chot_cong   timestamp,
  nguoi_khoa            number,
  thoi_diem_khoa        timestamp,
  constraint pk_ky_luong primary key (ky_luong_id),
  constraint uk_ky_luong_nam_thang unique (nam, thang),
  constraint ck_kl_thang check (thang between 1 and 12),
  constraint ck_kl_nam check (nam between 2000 and 2100),
  constraint ck_kl_trang_thai check (trang_thai in ('MO', 'CHOT_CONG', 'DA_TINH', 'DA_KHOA')),
  constraint ck_kl_ngay_tra check (
        extract(month from ngay_chi_tra_du_kien) = thang
    and extract(year  from ngay_chi_tra_du_kien) = nam),
  constraint ck_kl_pb_dau_vao check (phien_ban_dau_vao >= 0),
  constraint ck_kl_phien_ban check (phien_ban_da_tinh <= phien_ban_dau_vao),
  constraint ck_kl_chot_cong check (
       (trang_thai = 'MO'  and nguoi_chot_cong is null     and thoi_diem_chot_cong is null)
    or (trang_thai <> 'MO' and nguoi_chot_cong is not null and thoi_diem_chot_cong is not null)),
  constraint ck_kl_da_tinh check (
       trang_thai not in ('DA_TINH', 'DA_KHOA')
    or (phien_ban_da_tinh is not null and chinh_sach_id is not null)),
  constraint ck_kl_khoa check (
       (trang_thai = 'DA_KHOA' and nguoi_khoa is not null and thoi_diem_khoa is not null
          and phien_ban_da_tinh = phien_ban_dau_vao)
    or (trang_thai <> 'DA_KHOA' and nguoi_khoa is null and thoi_diem_khoa is null))
);

create table phieu_luong (
  phieu_luong_id        number generated always as identity,
  ky_luong_id           number not null,
  nhan_vien_id          number not null,
  hop_dong_id           number not null,
  phong_ban_id          number not null,
  chuc_vu_id            number not null,
  luong_co_ban_ap_dung  d_tien not null,
  gio_huong_luong       number(6,2) not null,
  thu_nhap_chiu_thue    d_tien not null,
  giam_tru_ap_dung      d_tien not null,
  tong_gross            d_tien not null,
  bao_hiem_nld          d_tien not null,
  bao_hiem_nsdld        d_tien not null,
  thue_tncn             d_tien not null,
  khau_tru_khac         d_tien not null,
  thu_nhap_tinh_thue    number(18,2) generated always as (
                          greatest(thu_nhap_chiu_thue - bao_hiem_nld - giam_tru_ap_dung, 0)) virtual,
  tong_net              number(18,2) generated always as (
                          tong_gross - bao_hiem_nld - thue_tncn - khau_tru_khac) virtual,
  constraint pk_phieu_luong primary key (phieu_luong_id),
  constraint uk_phieu_ky_nv unique (ky_luong_id, nhan_vien_id),
  constraint uk_phieu_nv unique (phieu_luong_id, nhan_vien_id),
  constraint ck_phieu_gio check (gio_huong_luong >= 0),
  constraint ck_phieu_tnct check (thu_nhap_chiu_thue <= tong_gross),
  constraint ck_phieu_net check (tong_net >= 0)
);

create table chi_tiet_phieu_luong (
  chi_tiet_id         number generated always as identity,
  phieu_luong_id      number not null,
  loai_khoan_id       number not null,
  so_luong            number(12,4) default 1 not null,
  don_gia             number not null,
  he_so               number(9,6) default 1 not null,
  thanh_tien          number(18,2) generated always as (round(so_luong * don_gia * he_so, 0)) virtual,
  nhom_khoan_ap_dung  varchar2(15) not null,
  phan_chiu_thue      d_tien default 0 not null,
  phat_sinh_id        number,
  khoan_nhan_vien_id  number,
  tang_ca_id          number,
  constraint pk_chi_tiet_phieu_luong primary key (chi_tiet_id),
  constraint ck_ctpl_so_luong check (so_luong >= 0),
  constraint ck_ctpl_don_gia check (don_gia >= 0),
  constraint ck_ctpl_he_so check (he_so >= 0),
  constraint ck_ctpl_nhom check (nhom_khoan_ap_dung in
    ('THU_NHAP', 'GIAM_THU_NHAP', 'BAO_HIEM_NLD', 'THUE_TNCN', 'KHAU_TRU', 'BAO_HIEM_NSDLD')),
  constraint ck_ctpl_chiu_thue check (phan_chiu_thue <= thanh_tien),
  constraint ck_ctpl_mot_nguon check (
    nvl2(phat_sinh_id, 1, 0) + nvl2(khoan_nhan_vien_id, 1, 0) + nvl2(tang_ca_id, 1, 0) <= 1)
);

create table loai_khoan_luong (
  loai_khoan_id         number generated always as identity,
  ma_khoan              d_ma not null,
  ten_khoan             varchar2(100) not null,
  nhom_khoan            varchar2(15) not null,
  cach_tinh             varchar2(15) not null,
  cach_xu_ly_thue       varchar2(20),
  cach_xu_ly_bao_hiem   varchar2(20),
  tinh_vao_don_gia_ot   boolean default false not null,
  tu_ngay               d_ngay not null,
  den_ngay              d_ngay,
  constraint pk_loai_khoan_luong primary key (loai_khoan_id),
  constraint uk_lkl_ma_tu_ngay unique (ma_khoan, tu_ngay),
  constraint ck_lkl_nhom check (nhom_khoan in
    ('THU_NHAP', 'GIAM_THU_NHAP', 'BAO_HIEM_NLD', 'THUE_TNCN', 'KHAU_TRU', 'BAO_HIEM_NSDLD')),
  constraint ck_lkl_cach_tinh check (cach_tinh in
    ('THEO_CONG', 'THEO_THANG', 'THEO_GIO_OT', 'THEO_TY_LE', 'THEO_BAC_THUE', 'THEO_PHAT_SINH')),
  constraint ck_lkl_thue check (cach_xu_ly_thue in ('CHIU_THUE', 'MIEN_TOAN_BO', 'MIEN_PHAN_CHENH_LECH')),
  constraint ck_lkl_bao_hiem check (cach_xu_ly_bao_hiem in ('TINH_CAN_CU', 'KHONG_TINH_CAN_CU')),
  constraint ck_lkl_xu_ly check (
       (nhom_khoan in ('THU_NHAP', 'GIAM_THU_NHAP')
          and cach_xu_ly_thue is not null and cach_xu_ly_bao_hiem is not null)
    or (nhom_khoan not in ('THU_NHAP', 'GIAM_THU_NHAP')
          and cach_xu_ly_thue is null and cach_xu_ly_bao_hiem is null)),
  constraint ck_lkl_ngay check (den_ngay >= tu_ngay)
);

create table khoan_luong_nhan_vien (
  khoan_nhan_vien_id  number generated always as identity,
  nhan_vien_id        number not null,
  loai_khoan_id       number not null,
  muc_tien            d_tien not null,
  tu_ngay             d_ngay not null,
  den_ngay            d_ngay,
  constraint pk_khoan_luong_nhan_vien primary key (khoan_nhan_vien_id),
  constraint ck_klnv_muc_tien check (muc_tien > 0),
  constraint ck_klnv_ngay check (den_ngay >= tu_ngay)
);

create table phat_sinh_luong (
  phat_sinh_id        number generated always as identity,
  nhan_vien_id        number not null,
  ky_luong_id         number not null,
  loai_khoan_id       number not null,
  so_tien             d_tien not null,
  chieu_dieu_chinh    varchar2(4) not null,
  can_cu              varchar2(500) not null,
  nguoi_tao           number not null,
  trang_thai_duyet    varchar2(10) default 'CHO_DUYET' not null,
  nguoi_duyet         number,
  khen_thuong_id      number,
  phieu_luong_goc_id  number,
  constraint pk_phat_sinh_luong primary key (phat_sinh_id),
  constraint uk_ps_khen_thuong unique (khen_thuong_id),
  constraint ck_ps_so_tien check (so_tien > 0),
  constraint ck_ps_chieu check (chieu_dieu_chinh in ('TANG', 'GIAM')),
  constraint ck_ps_trang_thai check (trang_thai_duyet in ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI')),
  constraint ck_ps_duyet check (
       (trang_thai_duyet = 'CHO_DUYET' and nguoi_duyet is null)
    or (trang_thai_duyet in ('DA_DUYET', 'TU_CHOI') and nguoi_duyet is not null)),
  constraint ck_ps_khong_tu_duyet check (khen_thuong_id is not null or nguoi_duyet <> nguoi_tao)
);

create table chinh_sach_luong (
  chinh_sach_id             number generated always as identity,
  tu_ngay                   d_ngay not null,
  den_ngay                  d_ngay,
  giam_tru_ban_than         d_tien not null,
  giam_tru_nguoi_phu_thuoc  d_tien not null,
  han_muc_ot_ngay           d_gio not null,
  han_muc_ot_thang          d_gio not null,
  han_muc_ot_nam            d_gio not null,
  nguon_can_cu              varchar2(500) not null,
  constraint pk_chinh_sach_luong primary key (chinh_sach_id),
  constraint ck_csl_tu_ngay check (tu_ngay = trunc(tu_ngay, 'MM')),
  constraint ck_csl_den_ngay check (den_ngay = last_day(den_ngay)),
  constraint ck_csl_ngay check (den_ngay > tu_ngay),
  constraint ck_csl_han_muc check (han_muc_ot_ngay <= han_muc_ot_thang and han_muc_ot_thang <= han_muc_ot_nam)
);

create table he_so_ot (
  chinh_sach_id  number not null,
  loai_ngay      varchar2(10) not null,
  he_so          number(4,2) not null,
  constraint pk_he_so_ot primary key (chinh_sach_id, loai_ngay),
  constraint ck_hsot_loai_ngay check (loai_ngay in ('LAM_VIEC', 'NGHI_TUAN', 'LE')),
  constraint ck_hsot_he_so check (he_so >= 1)
);

create table ty_le_bao_hiem (
  chinh_sach_id   number not null,
  loai_bao_hiem   varchar2(10) not null,
  ty_le_nld       d_ty_le not null,
  ty_le_nsdld     d_ty_le not null,
  san_dong        d_tien,
  tran_dong       d_tien,
  can_cu_ap_dung  varchar2(500) not null,
  constraint pk_ty_le_bao_hiem primary key (chinh_sach_id, loai_bao_hiem),
  constraint ck_tlbh_loai check (loai_bao_hiem in ('BHXH', 'BHTNLD', 'BHYT', 'BHTN')),
  constraint ck_tlbh_san_tran check (tran_dong > san_dong)
);

create table bac_thue_tncn (
  chinh_sach_id  number not null,
  bac            number(2) not null,
  can_duoi       d_tien not null,
  can_tren       d_tien,
  thue_suat      d_ty_le not null,
  constraint pk_bac_thue_tncn primary key (chinh_sach_id, bac),
  constraint uk_btt_can_duoi unique (chinh_sach_id, can_duoi),
  constraint ck_btt_bac check (bac >= 1),
  constraint ck_btt_can check (can_tren > can_duoi)
);

-- ---------------------------------------------------------------------------
-- Chu thich bang (xem bang USER_TAB_COMMENTS)
-- ---------------------------------------------------------------------------
comment on table tai_khoan             is 'Tài khoản nghiệp vụ; ánh xạ user demo qua ORACLE_USERNAME';
comment on table vai_tro               is 'Danh mục 5 vai trò';
comment on table tai_khoan_vai_tro     is 'Gán vai trò cho tài khoản (N-N)';
comment on table phong_ban             is 'Danh mục phòng ban; trưởng phòng suy ra từ QUA_TRINH_CONG_TAC';
comment on table chuc_vu               is 'Danh mục chức vụ; LA_QUAN_LY đánh dấu chức vụ quản lý';
comment on table nhat_ky_he_thong      is 'Audit thay đổi nhạy cảm; chỉ INSERT';
comment on table nhan_vien             is 'Hồ sơ nhân viên';
comment on table qua_trinh_cong_tac    is 'Phân công phòng ban, chức vụ theo thời gian';
comment on table loai_hop_dong         is 'Danh mục loại hợp đồng';
comment on table hop_dong              is 'Hợp đồng lao động; lương ở MUC_LUONG_HOP_DONG';
comment on table muc_luong_hop_dong    is 'Mức lương theo khoảng hiệu lực, bắt đầu ngày 1 của tháng';
comment on table nguoi_phu_thuoc       is 'Mỗi dòng là một lần đăng ký giảm trừ gia cảnh';
comment on table khen_thuong           is 'Quyết định khen thưởng';
comment on table ky_luat               is 'Quyết định kỷ luật; không sinh khoản tiền';
comment on table lich_lam_viec         is 'Lịch từng ngày: loại ngày, giờ hai buổi, giờ quy đổi lương';
comment on table cham_cong             is 'Giờ làm thực tế theo nhân viên, ngày';
comment on table dang_ky_tang_ca       is 'Đăng ký và duyệt làm thêm giờ';
comment on table loai_nghi_phep        is 'Danh mục loại nghỉ';
comment on table don_nghi_phep         is 'Đơn nghỉ phép';
comment on table chi_tiet_nghi_phep    is 'Từng buổi nghỉ của đơn; IX-14 chặn trùng buổi';
comment on table han_muc_phep_nam      is 'Hạn mức phép năm theo nhân viên, năm';
comment on table lich_su_duyet_nghi    is 'Sự kiện xử lý đơn nghỉ';
comment on table ky_luong              is 'Kỳ lương tháng, trạng thái, phiên bản đầu vào';
comment on table phieu_luong           is 'Phiếu lương: snapshot kết quả tính';
comment on table chi_tiet_phieu_luong  is 'Từng khoản của phiếu: số lượng x đơn giá x hệ số';
comment on table loai_khoan_luong      is 'Danh mục khoản lương có phiên bản theo TU_NGAY';
comment on table khoan_luong_nhan_vien is 'Phụ cấp cố định theo nhân viên';
comment on table phat_sinh_luong       is 'Thưởng, khấu trừ, điều chỉnh theo kỳ';
comment on table chinh_sach_luong      is 'Phiên bản chính sách lương, hiệu lực trọn tháng';
comment on table he_so_ot              is 'Hệ số OT theo loại ngày';
comment on table ty_le_bao_hiem        is 'Tỷ lệ, sàn, trần từng loại bảo hiểm';
comment on table bac_thue_tncn         is 'Bậc thuế TNCN lũy tiến từng phần';
