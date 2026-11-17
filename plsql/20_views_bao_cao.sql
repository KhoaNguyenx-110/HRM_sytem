-- =============================================================================
-- 20_views_bao_cao.sql - View cho bao cao (giai doan 5, dac ta muc 6, 7.4)
--
--   VW-06 vw_hop_dong_sap_het_han : hop dong co ngay ket thuc, khong huy (QR-04)
--   VW-12 vw_qua_trinh_cong_tac   : BO SUNG - lich su phan cong (QR-02, QR-06).
--                                   VW-01 chi co phan cong hien tai nen khong tra
--                                   loi duoc "nhan su tai mot ngay trong qua khu".
--   VW-13 vw_danh_ba_nhan_vien    : BO SUNG - danh ba cho Admin (QR-05). Admin khong
--                                   duoc doc VW-01 (TC-08) nhung can biet ai chua
--                                   co tai khoan. Khong co dinh danh, MST, luong.
--   VW-14 vw_nghi_phep_chi_tiet   : BO SUNG - tung buoi nghi kem loai va trang thai
--                                   don (QR-11, doi chieu TC-48). VW-03 chi co tong
--                                   theo thang, khong co loai nghi va ngay.
--
-- Nguyen tac nhu cac view khac: WITH READ ONLY, loc theo danh tinh (FN-06),
-- khong nhan tham so; nguong, ngay, ky la WHERE cua truy van ngoai.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- VW-06. Chi HR. Hop dong khong thoi han (NGAY_KET_THUC NULL) va hop dong da huy
-- bi loai ngay trong view (FR-REP-02). Phong ban la phong hien tai cua nguoi do.
-- -----------------------------------------------------------------------------
create or replace view vw_hop_dong_sap_het_han as
select h.so_hop_dong,
       n.ma_nhan_vien,
       n.ho_ten,
       b.ten_phong_ban,
       l.ma_loai           as ma_loai_hop_dong,
       l.ten_loai          as ten_loai_hop_dong,
       h.ngay_bat_dau,
       h.ngay_ket_thuc,
       n.ngay_nghi_viec
  from hop_dong h
  join nhan_vien n     on n.nhan_vien_id     = h.nhan_vien_id
  join loai_hop_dong l on l.loai_hop_dong_id = h.loai_hop_dong_id
  left join qua_trinh_cong_tac q
         on q.nhan_vien_id = n.nhan_vien_id
        and least(trunc(sysdate), nvl(n.ngay_nghi_viec, trunc(sysdate)))
            between q.ngay_bat_dau and nvl(q.ngay_ket_thuc, date '9999-12-31')
  left join phong_ban b on b.phong_ban_id = q.phong_ban_id
 where h.ngay_ket_thuc is not null
   and not h.da_huy
   and fn_co_vai_tro('HR')
with read only;
comment on table vw_hop_dong_sap_het_han is 'VW-06 Hợp đồng có ngày kết thúc, không hủy; ngưỡng do truy vấn ngoài truyền';

-- -----------------------------------------------------------------------------
-- VW-12. Moi giai doan phan cong. Pham vi:
--   HR, Payroll : tat ca
--   Truong phong: cac giai doan thuoc phong minh dang quan ly (ke ca nguoi da chuyen di)
--   Nhan vien   : lich su cua chinh minh
-- -----------------------------------------------------------------------------
create or replace view vw_qua_trinh_cong_tac as
select n.ma_nhan_vien,
       n.ho_ten,
       b.ma_phong_ban,
       b.ten_phong_ban,
       c.ma_chuc_vu,
       c.ten_chuc_vu,
       c.la_quan_ly,
       q.ngay_bat_dau,
       q.ngay_ket_thuc,
       q.can_cu_dieu_chuyen,
       n.ngay_vao_lam,
       n.ngay_nghi_viec
  from qua_trinh_cong_tac q
  join nhan_vien n on n.nhan_vien_id = q.nhan_vien_id
  join phong_ban b on b.phong_ban_id = q.phong_ban_id
  join chuc_vu c   on c.chuc_vu_id   = q.chuc_vu_id
 where fn_co_vai_tro('HR') or fn_co_vai_tro('PAYROLL')
    or n.nhan_vien_id = fn_nhan_vien_hien_tai
    or (fn_co_vai_tro('MANAGER')
        and fn_truong_phong_tai_ngay(q.phong_ban_id, trunc(sysdate)) = fn_nhan_vien_hien_tai)
with read only;
comment on table vw_qua_trinh_cong_tac is 'VW-12 Lịch sử phân công (bổ sung): nhân sự tại một ngày, lịch sử công tác';

-- -----------------------------------------------------------------------------
-- VW-13. Chi Admin: danh ba toi thieu de cap tai khoan cho nguoi moi vao.
-- -----------------------------------------------------------------------------
create or replace view vw_danh_ba_nhan_vien as
select n.ma_nhan_vien,
       n.ho_ten,
       n.email,
       n.ngay_vao_lam,
       n.ngay_nghi_viec,
       case when n.ngay_nghi_viec < trunc(sysdate) then 'DA_NGHI' else 'DANG_LAM' end as trang_thai_lam_viec,
       b.ten_phong_ban
  from nhan_vien n
  left join qua_trinh_cong_tac q
         on q.nhan_vien_id = n.nhan_vien_id
        and least(trunc(sysdate), nvl(n.ngay_nghi_viec, trunc(sysdate)))
            between q.ngay_bat_dau and nvl(q.ngay_ket_thuc, date '9999-12-31')
  left join phong_ban b on b.phong_ban_id = q.phong_ban_id
 where fn_co_vai_tro('ADMIN')
with read only;
comment on table vw_danh_ba_nhan_vien is 'VW-13 Danh bạ cho Admin (bổ sung): không định danh, MST, lương';

-- -----------------------------------------------------------------------------
-- VW-14. Moi buoi nghi mot dong, kem trang thai don (de doi chieu: bao cao chi
-- cong DA_DUYET, khong cong TU_CHOI / DA_RUT - TC-48). Phong ban tai ngay nghi.
-- Pham vi giong VW-03; truong phong thay nguoi thuoc phong minh tai ngay nghi.
-- -----------------------------------------------------------------------------
create or replace view vw_nghi_phep_chi_tiet as
with ct as (
  select c.don_nghi_id, c.nhan_vien_id, c.ngay, c.buoi,
         (select q.phong_ban_id from qua_trinh_cong_tac q
           where q.nhan_vien_id = c.nhan_vien_id
             and c.ngay between q.ngay_bat_dau and nvl(q.ngay_ket_thuc, date '9999-12-31')
           fetch first 1 row only) as phong_ban_id
    from chi_tiet_nghi_phep c
)
select ct.don_nghi_id,
       n.ma_nhan_vien,
       n.ho_ten,
       b.ma_phong_ban,
       t.ma_loai                  as ma_loai_nghi,
       t.ten_loai                 as ten_loai_nghi,
       t.huong_luong_doanh_nghiep as huong_luong,
       ct.ngay,
       ct.buoi,
       case ct.buoi when 'SANG' then l.gio_ket_thuc_sang - l.gio_bat_dau_sang
                    else l.gio_ket_thuc_chieu - l.gio_bat_dau_chieu end as so_gio,
       d.trang_thai               as trang_thai_don
  from ct
  join don_nghi_phep d  on d.don_nghi_id   = ct.don_nghi_id
  join nhan_vien n      on n.nhan_vien_id  = ct.nhan_vien_id
  join loai_nghi_phep t on t.loai_nghi_id  = d.loai_nghi_id
  join lich_lam_viec l  on l.ngay          = ct.ngay
  left join phong_ban b on b.phong_ban_id  = ct.phong_ban_id
 where fn_co_vai_tro('HR') or fn_co_vai_tro('PAYROLL')
    or ct.nhan_vien_id = fn_nhan_vien_hien_tai
    or (fn_co_vai_tro('MANAGER')
        and fn_truong_phong_tai_ngay(ct.phong_ban_id, trunc(sysdate)) = fn_nhan_vien_hien_tai)
with read only;
comment on table vw_nghi_phep_chi_tiet is 'VW-14 Chi tiết từng buổi nghỉ kèm loại và trạng thái đơn (bổ sung)';
