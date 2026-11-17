-- =============================================================================
-- 10_views_hr.sql - View giai doan 4a (dac ta muc 7.4)
-- Moi view WITH READ ONLY va loc theo danh tinh phien (FN-06). View khong nhan
-- tham so; bo loc khac dung WHERE cua truy van ngoai.
-- Nguoi dung chi co SELECT tren view, khong tren bang goc (BR-35).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- VW-01 vw_ho_so_nhan_vien: ho so + phan cong hien tai (FR-EMP-07, TC-18)
--   HR, PAYROLL : tat ca, day du
--   MANAGER     : phong minh dang quan ly; dinh danh chi hien 4 so cuoi, an MST
--   EMPLOYEE    : chinh minh, day du
-- Phan cong "hien tai" = phan cong bat dau gan nhat tinh den hom nay (nguoi da
-- nghi viec giu phan cong cuoi cung).
-- -----------------------------------------------------------------------------
create or replace view vw_ho_so_nhan_vien as
with pc as (
  select q.nhan_vien_id, q.phong_ban_id, q.chuc_vu_id, q.ngay_bat_dau,
         row_number() over (partition by q.nhan_vien_id order by q.ngay_bat_dau desc) as rn
    from qua_trinh_cong_tac q
   where q.ngay_bat_dau <= trunc(sysdate)
),
nv as (
  select n.*, p.phong_ban_id, p.chuc_vu_id, p.ngay_bat_dau as ngay_bat_dau_phan_cong,
         case when fn_co_vai_tro('HR') or fn_co_vai_tro('PAYROLL')
                or n.nhan_vien_id = fn_nhan_vien_hien_tai then 1 else 0 end as xem_day_du,
         case when fn_co_vai_tro('MANAGER')
               and fn_truong_phong_tai_ngay(p.phong_ban_id, trunc(sysdate)) = fn_nhan_vien_hien_tai
              then 1 else 0 end as thuoc_phong_quan_ly
    from nhan_vien n
    left join pc p on p.nhan_vien_id = n.nhan_vien_id and p.rn = 1
)
select nv.nhan_vien_id,
       nv.ma_nhan_vien,
       nv.ho_ten,
       nv.ngay_sinh,
       case when nv.xem_day_du = 1 then nv.so_dinh_danh
            else '********' || substr(nv.so_dinh_danh, -4) end            as so_dinh_danh,
       case when nv.xem_day_du = 1 then nv.ma_so_thue end                 as ma_so_thue,
       nv.email,
       nv.so_dien_thoai,
       nv.dia_chi,
       nv.ngay_vao_lam,
       nv.ngay_nghi_viec,
       case when nv.ngay_nghi_viec < trunc(sysdate) then 'DA_NGHI' else 'DANG_LAM' end as trang_thai_lam_viec,
       b.ma_phong_ban,
       b.ten_phong_ban,
       c.ma_chuc_vu,
       c.ten_chuc_vu,
       c.la_quan_ly,
       nv.ngay_bat_dau_phan_cong
  from nv
  left join phong_ban b on b.phong_ban_id = nv.phong_ban_id
  left join chuc_vu   c on c.chuc_vu_id   = nv.chuc_vu_id
 where nv.xem_day_du = 1 or nv.thuoc_phong_quan_ly = 1
with read only;

comment on table vw_ho_so_nhan_vien is 'VW-01 Hồ sơ và phân công hiện tại, lọc theo vai trò phiên';

-- -----------------------------------------------------------------------------
-- VW-07 vw_nhan_su_phong: nhan su dang thuoc phong ma nguoi dang nhap quan ly
-- -----------------------------------------------------------------------------
create or replace view vw_nhan_su_phong as
select n.ma_nhan_vien,
       n.ho_ten,
       b.ma_phong_ban,
       b.ten_phong_ban,
       c.ma_chuc_vu,
       c.ten_chuc_vu,
       q.ngay_bat_dau,
       n.email,
       n.so_dien_thoai
  from qua_trinh_cong_tac q
  join nhan_vien n on n.nhan_vien_id = q.nhan_vien_id
  join phong_ban b on b.phong_ban_id = q.phong_ban_id
  join chuc_vu   c on c.chuc_vu_id   = q.chuc_vu_id
 where trunc(sysdate) between q.ngay_bat_dau and nvl(q.ngay_ket_thuc, date '9999-12-31')
   and fn_co_vai_tro('MANAGER')
   and fn_truong_phong_tai_ngay(q.phong_ban_id, trunc(sysdate)) = fn_nhan_vien_hien_tai
with read only;

comment on table vw_nhan_su_phong is 'VW-07 Nhân sự phòng do người đăng nhập quản lý';

-- -----------------------------------------------------------------------------
-- VW-09 vw_tai_khoan_quan_tri: tai khoan va vai tro, KHONG co MAT_KHAU_BAM; chi Admin
-- -----------------------------------------------------------------------------
create or replace view vw_tai_khoan_quan_tri as
select t.tai_khoan_id,
       t.ten_dang_nhap,
       n.ma_nhan_vien,
       n.ho_ten,
       t.oracle_username,
       t.trang_thai,
       t.so_lan_dang_nhap_sai,
       t.thoi_diem_tao,
       (select listagg(v.ma_vai_tro, ', ') within group (order by v.ma_vai_tro)
          from tai_khoan_vai_tro tv join vai_tro v on v.vai_tro_id = tv.vai_tro_id
         where tv.tai_khoan_id = t.tai_khoan_id) as vai_tro
  from tai_khoan t
  left join nhan_vien n on n.nhan_vien_id = t.nhan_vien_id
 where fn_co_vai_tro('ADMIN')
with read only;

comment on table vw_tai_khoan_quan_tri is 'VW-09 Tài khoản và vai trò (không có hash mật khẩu), chỉ Admin';

-- -----------------------------------------------------------------------------
-- VW-10 vw_nhat_ky: audit theo pham vi vai tro
--   ADMIN   : tai khoan, vai tro
--   HR      : ho so, hop dong, muc luong, han muc phep (TC-52)
--   PAYROLL : phat sinh luong, ky luong, muc luong, phieu luong (QR-24, TC-52)
-- -----------------------------------------------------------------------------
create or replace view vw_nhat_ky as
select k.nhat_ky_id,
       k.thoi_diem,
       t.ten_dang_nhap,
       k.oracle_username,
       k.doi_tuong,
       k.khoa_ban_ghi,
       k.thao_tac,
       k.gia_tri_cu,
       k.gia_tri_moi
  from nhat_ky_he_thong k
  left join tai_khoan t on t.tai_khoan_id = k.tai_khoan_id
 where (fn_co_vai_tro('ADMIN')   and k.doi_tuong in ('TAI_KHOAN', 'TAI_KHOAN_VAI_TRO'))
    or (fn_co_vai_tro('HR')      and k.doi_tuong in ('NHAN_VIEN', 'HOP_DONG', 'MUC_LUONG_HOP_DONG', 'HAN_MUC_PHEP_NAM'))
    or (fn_co_vai_tro('PAYROLL') and k.doi_tuong in ('PHAT_SINH_LUONG', 'KY_LUONG', 'MUC_LUONG_HOP_DONG', 'PHIEU_LUONG'))
with read only;

comment on table vw_nhat_ky is 'VW-10 Nhật ký audit theo phạm vi vai trò';
