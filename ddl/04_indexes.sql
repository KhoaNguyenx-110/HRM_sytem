-- =============================================================================
-- 04_indexes.sql - Index (dac ta muc 7.6 va tu dien du lieu muc 10)
-- IX-01, IX-03, IX-06, IX-10 da duoc UNIQUE constraint tao, khong tao lai.
-- Cac cot FK dung de noi bang hoac khoa dong deu co index dan dau.
-- Khong index FK toi bang danh muc nho (< 50 dong) va cot NGUOI_* chi dung de luu
-- dau vet: cac bang cha nay khong bao gio bi xoa hay doi khoa.
-- =============================================================================

-- Index theo dac ta 7.6
create unique index ix02_tai_khoan_ten     on tai_khoan (upper(ten_dang_nhap));
create index ix04_hop_dong_nv_ngay          on hop_dong (nhan_vien_id, ngay_bat_dau);
create index ix05_hop_dong_ket_thuc         on hop_dong (ngay_ket_thuc);
create index ix07_don_nv_trang_thai         on don_nghi_phep (nhan_vien_id, trang_thai);
create index ix08_ctnp_ngay_don             on chi_tiet_nghi_phep (ngay, don_nghi_id);
create index ix09_ot_nv_ngay_trang_thai     on dang_ky_tang_ca (nhan_vien_id, ngay, trang_thai);
create index ix11_ctpl_phieu                on chi_tiet_phieu_luong (phieu_luong_id);
create index ix12_ps_ky_nv                  on phat_sinh_luong (ky_luong_id, nhan_vien_id);
create index ix13_nhat_ky_doi_tuong         on nhat_ky_he_thong (doi_tuong, khoa_ban_ghi, thoi_diem);
-- IX-14: dong het hieu luc co khoa toan NULL nen khong vao index (BR-16)
create unique index ix14_ctnp_buoi_hieu_luc on chi_tiet_nghi_phep (
  case when con_hieu_luc = 1 then nhan_vien_id end,
  case when con_hieu_luc = 1 then ngay end,
  case when con_hieu_luc = 1 then buoi end);
create index ix15_phieu_nv_ky               on phieu_luong (nhan_vien_id, ky_luong_id);
create index ix16_qtct_phong_ngay           on qua_trinh_cong_tac (phong_ban_id, ngay_bat_dau);
-- IX-17 (bo sung o GD 6 sau TC-54): nghi cua mot nguoi trong mot khoang ngay -
-- FN-02 (moi nguoi moi lan tinh ky), FN-03, VW-03, kiem tra trung buoi khi dang ky.
-- IX-08 dan dau bang NGAY nen phai doc moi don trong thang roi loc theo nguoi.
create index ix17_ctnp_nv_ngay              on chi_tiet_nghi_phep (nhan_vien_id, ngay);

-- Index cho cot FK chua co index dan dau
create index ix_tkvt_vai_tro                on tai_khoan_vai_tro (vai_tro_id);
create index ix_nhat_ky_tai_khoan           on nhat_ky_he_thong (tai_khoan_id, thoi_diem);
create index ix_qtct_chuc_vu                on qua_trinh_cong_tac (chuc_vu_id);
create index ix_npt_nhan_vien               on nguoi_phu_thuoc (nhan_vien_id);
create index ix_npt_dinh_danh               on nguoi_phu_thuoc (dinh_danh_chuan_hoa);
create index ix_kt_nhan_vien                on khen_thuong (nhan_vien_id);
create index ix_kl_nhan_vien                on ky_luat (nhan_vien_id);
create index ix_cc_ngay                     on cham_cong (ngay);
create index ix_ot_ngay                     on dang_ky_tang_ca (ngay);
create index ix_lsdn_don                    on lich_su_duyet_nghi (don_nghi_id);
create index ix_phieu_hop_dong              on phieu_luong (hop_dong_id, nhan_vien_id);
create index ix_phieu_phong_ban             on phieu_luong (phong_ban_id);
create index ix_ctpl_phat_sinh              on chi_tiet_phieu_luong (phat_sinh_id);
create index ix_ctpl_khoan_nv               on chi_tiet_phieu_luong (khoan_nhan_vien_id);
create index ix_ctpl_tang_ca                on chi_tiet_phieu_luong (tang_ca_id);
create index ix_klnv_nhan_vien              on khoan_luong_nhan_vien (nhan_vien_id, loai_khoan_id);
create index ix_ps_nhan_vien                on phat_sinh_luong (nhan_vien_id);
create index ix_ps_phieu_goc                on phat_sinh_luong (phieu_luong_goc_id, nhan_vien_id);
