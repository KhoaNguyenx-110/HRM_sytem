-- =============================================================================
-- TR-03 (lop bao ve thu hai): ngay ca chu schema sua tay cung bi chan khi ky da chot
-- Chay bang HRM_OWNER (kiem tra trigger, KHONG dung de ket luan phan quyen). ROLLBACK.
-- =============================================================================
set feedback off
declare
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure thu(p_ten varchar2, p_sql varchar2) is
  begin
    execute immediate p_sql;
    dat(p_ten || ' -> khong bi chan', false);
  exception when others then
    dat(p_ten || ' bi chan (' || sqlcode || ')', sqlcode = -20301);
  end;
begin
  update ky_luong
     set trang_thai = 'CHOT_CONG', nguoi_chot_cong = (select min(tai_khoan_id) from tai_khoan),
         thoi_diem_chot_cong = systimestamp
   where nam = 2026 and thang = 3;

  thu('TR-03 UPDATE truc tiep CHAM_CONG thang da chot',
      'update cham_cong set so_gio_lam_thuc_te = 7 where ngay = date ''2026-03-02'' and rownum = 1');
  thu('TR-03 DELETE truc tiep CHAM_CONG thang da chot',
      'delete from cham_cong where ngay = date ''2026-03-02'' and rownum = 1');
  thu('TR-03 UPDATE truc tiep LICH_LAM_VIEC thang da chot',
      'update lich_lam_viec set gio_quy_doi_luong = 8 where ngay = date ''2026-03-07''');
  thu('TR-03 UPDATE truc tiep DANG_KY_TANG_CA thang da chot',
      'update dang_ky_tang_ca set ly_do = ''sửa tay'' where bat_dau >= timestamp ''2026-03-01 00:00:00'' and bat_dau < timestamp ''2026-04-01 00:00:00'' and rownum = 1');
  thu('TR-03 UPDATE truc tiep CHI_TIET_NGHI_PHEP thang da chot',
      'update chi_tiet_nghi_phep set con_hieu_luc = 0 where ngay = date ''2026-03-09'' and rownum = 1');
  rollback;
end;
/
