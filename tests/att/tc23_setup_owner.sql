-- =============================================================================
-- Du lieu loi cho TC-23: don nghi DA_DUYET buoi sang 10/02/2026 cua NV_C trong
-- khi NV_C da co 8 gio cong ngay do. Chay bang HRM_OWNER, COMMIT.
-- tc23_cleanup_owner.sql xoa lai.
-- =============================================================================
set feedback off
declare
  v_nv  number;
  v_tk  number;
  v_don number;
  v_loai number;
begin
  select nhan_vien_id into v_nv from nhan_vien where ma_nhan_vien = 'NV_C';
  select tai_khoan_id into v_tk from tai_khoan where ten_dang_nhap = 'nv019';
  select loai_nghi_id into v_loai from loai_nghi_phep where ma_loai = 'PHEP_NAM';
  -- INSERT ... SELECT khong dung duoc RETURNING: dung VALUES
  insert into don_nghi_phep (nhan_vien_id, loai_nghi_id, ly_do, trang_thai, nguoi_duyet, thoi_diem_duyet)
  values (v_nv, v_loai, 'TC-23 dữ liệu lỗi', 'DA_DUYET', v_tk, systimestamp)
  returning don_nghi_id into v_don;
  insert into chi_tiet_nghi_phep (don_nghi_id, ngay, buoi, nhan_vien_id) values (v_don, date '2026-02-10', 'SANG', v_nv);
  commit;
  dbms_output.put_line('Da tao don loi ' || v_don);
end;
/
