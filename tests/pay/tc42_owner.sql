-- =============================================================================
-- TC-42, TR-02, TR-04 bang chinh chu schema (HRM_OWNER) - lop bao ve thu hai
--   Sua/xoa phieu, chi tiet, phat sinh cua ky DA_KHOA -> TR-02 tu choi
--   Sua chinh sach da dung o ky DA_KHOA -> TR-04 tu choi; chi doi den_ngay ma
--   ky khoa van nam trong khoang -> cho phep. ROLLBACK cuoi.
-- =============================================================================
set feedback off
declare
  v_ky  number;
  v_cs  number;
  v_nv  number;
  v_lk  number;
  v_tk  number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure bi_chan(p_ten varchar2, p_ma number) is
  begin
    dat(p_ten || ' bi tu choi (' || sqlcode || '): ' || substr(sqlerrm, 12, 80), sqlcode = p_ma);
  end;
begin
  select ky_luong_id, chinh_sach_id into v_ky, v_cs from ky_luong where nam = 2026 and thang = 1;
  select nhan_vien_id into v_nv from nhan_vien where ma_nhan_vien = 'NV_A';
  select loai_khoan_id into v_lk from loai_khoan_luong where ma_khoan = 'KHAU_TRU';
  select tai_khoan_id into v_tk from tai_khoan where ten_dang_nhap = 'admin';

  begin
    update chi_tiet_phieu_luong set he_so = 2
     where phieu_luong_id = (select phieu_luong_id from phieu_luong where ky_luong_id = v_ky and nhan_vien_id = v_nv)
       and rownum = 1;
    dat('TR-02 Sua chi tiet phieu ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('TR-02 Sua chi tiet phieu ky da khoa', -20501);
  end;
  begin
    delete from phieu_luong where ky_luong_id = v_ky and nhan_vien_id = v_nv;
    dat('TR-02 Xoa phieu ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('TR-02 Xoa phieu ky da khoa', -20501);
  end;
  begin
    insert into phat_sinh_luong (nhan_vien_id, ky_luong_id, loai_khoan_id, so_tien, chieu_dieu_chinh, can_cu, nguoi_tao)
    values (v_nv, v_ky, v_lk, 1000, 'GIAM', 'TR-02 thử', v_tk);
    dat('TR-02 Them phat sinh vao ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('TR-02 Them phat sinh vao ky da khoa', -20501);
  end;

  begin
    update he_so_ot set he_so = 1.6 where chinh_sach_id = v_cs and loai_ngay = 'LAM_VIEC';
    dat('TR-04 Sua he so OT cua chinh sach da dung -> khong bi chan', false);
  exception when others then bi_chan('TR-04 Sua he so OT chinh sach da dung', -20509);
  end;
  begin
    update chinh_sach_luong set giam_tru_ban_than = 16000000 where chinh_sach_id = v_cs;
    dat('TR-04 Sua giam tru chinh sach da dung -> khong bi chan', false);
  exception when others then bi_chan('TR-04 Sua giam tru chinh sach da dung', -20509);
  end;
  begin
    delete from bac_thue_tncn where chinh_sach_id = v_cs and bac = 5;
    dat('TR-04 Xoa bac thue chinh sach da dung -> khong bi chan', false);
  exception when others then bi_chan('TR-04 Xoa bac thue chinh sach da dung', -20509);
  end;
  update chinh_sach_luong set den_ngay = date '2026-12-31' where chinh_sach_id = v_cs;
  dat('TR-04 Chi dong hieu luc 31/12/2026 (ky khoa van trong khoang) -> cho phep', sql%rowcount = 1);
  rollback;
end;
/
