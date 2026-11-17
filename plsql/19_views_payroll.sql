-- =============================================================================
-- 19_views_payroll.sql - View luong (dac ta muc 7.4)
--
--   VW-04 vw_bang_luong_tong_hop : moi phieu mot dong, phong/chuc vu LUU TREN PHIEU
--                                  (snapshot, BR-29), co trang thai ky. Chi Payroll.
--                                  Truy van ngoai tu GROUP BY (QR-18, QR-19, QR-21).
--   VW-05 vw_phieu_luong_ca_nhan : moi dong chi tiet mot dong, kem tong cua phieu.
--                                  Nhan vien: phieu cua minh o ky DA_KHOA.
--                                  Payroll: tat ca (QR-17, QR-22).
-- WITH READ ONLY, loc theo FN-06 (khong nhan tham so).
-- =============================================================================

create or replace view vw_bang_luong_tong_hop as
select k.ky_luong_id,
       k.nam,
       k.thang,
       k.trang_thai               as trang_thai_ky,
       p.phieu_luong_id,
       pb.ma_phong_ban,
       pb.ten_phong_ban,
       cv.ma_chuc_vu,
       cv.ten_chuc_vu,
       n.ma_nhan_vien,
       n.ho_ten,
       p.luong_co_ban_ap_dung,
       p.gio_huong_luong,
       p.tong_gross,
       p.thu_nhap_chiu_thue,
       p.thu_nhap_tinh_thue,
       p.bao_hiem_nld,
       p.thue_tncn,
       p.khau_tru_khac,
       p.tong_net,
       p.bao_hiem_nsdld,
       p.tong_gross + p.bao_hiem_nsdld as chi_phi_doanh_nghiep
  from phieu_luong p
  join ky_luong k    on k.ky_luong_id   = p.ky_luong_id
  join phong_ban pb  on pb.phong_ban_id = p.phong_ban_id
  join chuc_vu cv    on cv.chuc_vu_id   = p.chuc_vu_id
  join nhan_vien n   on n.nhan_vien_id  = p.nhan_vien_id
 where fn_co_vai_tro('PAYROLL')
with read only;
comment on table vw_bang_luong_tong_hop is 'VW-04 Quỹ lương theo kỳ, phòng, chức vụ lưu trên phiếu; chỉ Payroll';

create or replace view vw_phieu_luong_ca_nhan as
select k.nam,
       k.thang,
       k.trang_thai               as trang_thai_ky,
       p.phieu_luong_id,
       n.ma_nhan_vien,
       n.ho_ten,
       pb.ten_phong_ban,
       cv.ten_chuc_vu,
       p.luong_co_ban_ap_dung,
       p.gio_huong_luong,
       p.tong_gross,
       p.thu_nhap_chiu_thue,
       p.giam_tru_ap_dung,
       p.thu_nhap_tinh_thue,
       p.bao_hiem_nld,
       p.thue_tncn,
       p.khau_tru_khac,
       p.tong_net,
       p.bao_hiem_nsdld,
       c.chi_tiet_id,
       l.ma_khoan,
       l.ten_khoan,
       c.nhom_khoan_ap_dung,
       c.so_luong,
       c.don_gia,
       c.he_so,
       c.thanh_tien,
       c.phan_chiu_thue
  from phieu_luong p
  join ky_luong k               on k.ky_luong_id    = p.ky_luong_id
  join nhan_vien n              on n.nhan_vien_id   = p.nhan_vien_id
  join phong_ban pb             on pb.phong_ban_id  = p.phong_ban_id
  join chuc_vu cv               on cv.chuc_vu_id    = p.chuc_vu_id
  join chi_tiet_phieu_luong c   on c.phieu_luong_id = p.phieu_luong_id
  join loai_khoan_luong l       on l.loai_khoan_id  = c.loai_khoan_id
 where fn_co_vai_tro('PAYROLL')
    or (p.nhan_vien_id = fn_nhan_vien_hien_tai and k.trang_thai = 'DA_KHOA')
with read only;
comment on table vw_phieu_luong_ca_nhan is 'VW-05 Phiếu lương chi tiết: NV xem phiếu mình ở kỳ đã khóa; Payroll xem tất cả';
