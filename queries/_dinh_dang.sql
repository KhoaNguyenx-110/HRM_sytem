-- =============================================================================
-- _dinh_dang.sql - Dinh dang SQL*Plus dung chung cho cac file QR (khong phai truy van).
-- Moi file QR goi @@_dinh_dang.sql truoc. Trong DBeaver bo qua file nay: chi chay
-- cau SELECT va nhap gia tri cho cac bind :p_...
-- =============================================================================
set linesize 220 pagesize 200 tab off trimout on feedback off verify off
alter session set nls_date_format = 'DD/MM/YYYY';
alter session set nls_numeric_characters = ',.';
column ma_nhan_vien   format a12
column ma_phong_ban   format a12
column ma_chuc_vu     format a14
column ho_ten         format a24
column ten_phong_ban  format a18
column ten_chuc_vu    format a16
column so_hop_dong    format a14
column ma_khoan       format a15
column ten_khoan      format a28
column tinh_trang     format a11
column trang_thai_ky  format a10
