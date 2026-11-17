-- =============================================================================
-- 03_foreign_keys.sql - Khoa ngoai
-- Khong FK nao dung ON DELETE CASCADE (BR-33).
-- FK ghep (ID, NHAN_VIEN_ID) giu nhat quan cot du thua co chu dich (muc 9).
-- =============================================================================

-- Nhom A
alter table tai_khoan          add constraint fk_tai_khoan_nhan_vien  foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table tai_khoan_vai_tro  add constraint fk_tkvt_tai_khoan       foreign key (tai_khoan_id) references tai_khoan (tai_khoan_id);
alter table tai_khoan_vai_tro  add constraint fk_tkvt_vai_tro         foreign key (vai_tro_id)   references vai_tro (vai_tro_id);
alter table tai_khoan_vai_tro  add constraint fk_tkvt_nguoi_gan       foreign key (nguoi_gan)    references tai_khoan (tai_khoan_id);
alter table nhat_ky_he_thong   add constraint fk_nhat_ky_tai_khoan    foreign key (tai_khoan_id) references tai_khoan (tai_khoan_id);

-- Nhom B
alter table qua_trinh_cong_tac add constraint fk_qtct_nhan_vien       foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table qua_trinh_cong_tac add constraint fk_qtct_phong_ban       foreign key (phong_ban_id) references phong_ban (phong_ban_id);
alter table qua_trinh_cong_tac add constraint fk_qtct_chuc_vu         foreign key (chuc_vu_id)   references chuc_vu (chuc_vu_id);
alter table hop_dong           add constraint fk_hop_dong_nhan_vien   foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table hop_dong           add constraint fk_hop_dong_loai        foreign key (loai_hop_dong_id) references loai_hop_dong (loai_hop_dong_id);
alter table muc_luong_hop_dong add constraint fk_mlhd_hop_dong        foreign key (hop_dong_id)  references hop_dong (hop_dong_id);
alter table nguoi_phu_thuoc    add constraint fk_npt_nhan_vien        foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table khen_thuong        add constraint fk_kt_nhan_vien         foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table khen_thuong        add constraint fk_kt_nguoi_tao         foreign key (nguoi_tao)    references tai_khoan (tai_khoan_id);
alter table khen_thuong        add constraint fk_kt_nguoi_duyet       foreign key (nguoi_duyet)  references tai_khoan (tai_khoan_id);
alter table ky_luat            add constraint fk_kl_nhan_vien         foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table ky_luat            add constraint fk_kl_nguoi_tao         foreign key (nguoi_tao)    references tai_khoan (tai_khoan_id);
alter table ky_luat            add constraint fk_kl_nguoi_phe_duyet   foreign key (nguoi_phe_duyet) references tai_khoan (tai_khoan_id);

-- Nhom C
alter table cham_cong          add constraint fk_cc_nhan_vien         foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table cham_cong          add constraint fk_cc_ngay              foreign key (ngay)         references lich_lam_viec (ngay);
alter table cham_cong          add constraint fk_cc_nguoi_xac_nhan    foreign key (nguoi_xac_nhan) references tai_khoan (tai_khoan_id);
alter table dang_ky_tang_ca    add constraint fk_ot_nhan_vien         foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table dang_ky_tang_ca    add constraint fk_ot_ngay              foreign key (ngay)         references lich_lam_viec (ngay);
alter table dang_ky_tang_ca    add constraint fk_ot_nguoi_duyet       foreign key (nguoi_duyet)  references tai_khoan (tai_khoan_id);
alter table don_nghi_phep      add constraint fk_don_nhan_vien        foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table don_nghi_phep      add constraint fk_don_loai_nghi        foreign key (loai_nghi_id) references loai_nghi_phep (loai_nghi_id);
alter table don_nghi_phep      add constraint fk_don_nguoi_duyet      foreign key (nguoi_duyet)  references tai_khoan (tai_khoan_id);
alter table chi_tiet_nghi_phep add constraint fk_ctnp_don             foreign key (don_nghi_id, nhan_vien_id) references don_nghi_phep (don_nghi_id, nhan_vien_id);
alter table chi_tiet_nghi_phep add constraint fk_ctnp_ngay            foreign key (ngay)         references lich_lam_viec (ngay);
alter table han_muc_phep_nam   add constraint fk_hmpn_nhan_vien       foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table lich_su_duyet_nghi add constraint fk_lsdn_don             foreign key (don_nghi_id)  references don_nghi_phep (don_nghi_id);
alter table lich_su_duyet_nghi add constraint fk_lsdn_nguoi_xu_ly     foreign key (nguoi_xu_ly)  references tai_khoan (tai_khoan_id);

-- Nhom D
alter table ky_luong           add constraint fk_kl_chinh_sach        foreign key (chinh_sach_id)   references chinh_sach_luong (chinh_sach_id);
alter table ky_luong           add constraint fk_kl_nguoi_chot_cong   foreign key (nguoi_chot_cong) references tai_khoan (tai_khoan_id);
alter table ky_luong           add constraint fk_kl_nguoi_khoa        foreign key (nguoi_khoa)      references tai_khoan (tai_khoan_id);
alter table phieu_luong        add constraint fk_phieu_ky_luong       foreign key (ky_luong_id)  references ky_luong (ky_luong_id);
alter table phieu_luong        add constraint fk_phieu_nhan_vien      foreign key (nhan_vien_id) references nhan_vien (nhan_vien_id);
alter table phieu_luong        add constraint fk_phieu_hop_dong       foreign key (hop_dong_id, nhan_vien_id) references hop_dong (hop_dong_id, nhan_vien_id);
alter table phieu_luong        add constraint fk_phieu_phong_ban      foreign key (phong_ban_id) references phong_ban (phong_ban_id);
alter table phieu_luong        add constraint fk_phieu_chuc_vu        foreign key (chuc_vu_id)   references chuc_vu (chuc_vu_id);
alter table chi_tiet_phieu_luong add constraint fk_ctpl_phieu         foreign key (phieu_luong_id)     references phieu_luong (phieu_luong_id);
alter table chi_tiet_phieu_luong add constraint fk_ctpl_loai_khoan    foreign key (loai_khoan_id)      references loai_khoan_luong (loai_khoan_id);
alter table chi_tiet_phieu_luong add constraint fk_ctpl_phat_sinh     foreign key (phat_sinh_id)       references phat_sinh_luong (phat_sinh_id);
alter table chi_tiet_phieu_luong add constraint fk_ctpl_khoan_nv      foreign key (khoan_nhan_vien_id) references khoan_luong_nhan_vien (khoan_nhan_vien_id);
alter table chi_tiet_phieu_luong add constraint fk_ctpl_tang_ca       foreign key (tang_ca_id)         references dang_ky_tang_ca (tang_ca_id);
alter table khoan_luong_nhan_vien add constraint fk_klnv_nhan_vien    foreign key (nhan_vien_id)  references nhan_vien (nhan_vien_id);
alter table khoan_luong_nhan_vien add constraint fk_klnv_loai_khoan   foreign key (loai_khoan_id) references loai_khoan_luong (loai_khoan_id);
alter table phat_sinh_luong    add constraint fk_ps_nhan_vien         foreign key (nhan_vien_id)  references nhan_vien (nhan_vien_id);
alter table phat_sinh_luong    add constraint fk_ps_ky_luong          foreign key (ky_luong_id)   references ky_luong (ky_luong_id);
alter table phat_sinh_luong    add constraint fk_ps_loai_khoan        foreign key (loai_khoan_id) references loai_khoan_luong (loai_khoan_id);
alter table phat_sinh_luong    add constraint fk_ps_nguoi_tao         foreign key (nguoi_tao)     references tai_khoan (tai_khoan_id);
alter table phat_sinh_luong    add constraint fk_ps_nguoi_duyet       foreign key (nguoi_duyet)   references tai_khoan (tai_khoan_id);
alter table phat_sinh_luong    add constraint fk_ps_khen_thuong       foreign key (khen_thuong_id, nhan_vien_id)     references khen_thuong (khen_thuong_id, nhan_vien_id);
alter table phat_sinh_luong    add constraint fk_ps_phieu_goc         foreign key (phieu_luong_goc_id, nhan_vien_id) references phieu_luong (phieu_luong_id, nhan_vien_id);
alter table he_so_ot           add constraint fk_hsot_chinh_sach      foreign key (chinh_sach_id) references chinh_sach_luong (chinh_sach_id);
alter table ty_le_bao_hiem     add constraint fk_tlbh_chinh_sach      foreign key (chinh_sach_id) references chinh_sach_luong (chinh_sach_id);
alter table bac_thue_tncn      add constraint fk_btt_chinh_sach       foreign key (chinh_sach_id) references chinh_sach_luong (chinh_sach_id);
