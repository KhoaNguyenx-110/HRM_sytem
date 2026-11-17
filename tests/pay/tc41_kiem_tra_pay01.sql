-- =============================================================================
-- Sau TC-41 - chay bang U_PAY01
--   Ky 02 co dung 1 phieu/nguoi (khong trung phieu sau hai phien)
--   TC-33b: phu cap het hieu luc 31/01 khong vao phieu thang 02
--   TC-45 : thuong TC45/2026 vao phieu thang 02 cua NV_B
--   BR-32 : dieu chinh co phieu goc chua duyet -> chua vao phieu
-- =============================================================================
set feedback off
declare
  v_phieu number;
  v_nguoi number;
  v_tt    varchar2(10);
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  function khoan(p_ma_nv varchar2, p_ma_khoan varchar2) return number is
    v number;
  begin
    select nvl(sum(thanh_tien), 0) into v from hrm_owner.vw_phieu_luong_ca_nhan
     where nam = 2026 and thang = 2 and ma_nhan_vien = p_ma_nv and ma_khoan = p_ma_khoan;
    return v;
  end;
begin
  select count(*), count(distinct ma_nhan_vien) into v_phieu, v_nguoi
    from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 2;
  select trang_thai into v_tt from hrm_owner.ky_luong where nam = 2026 and thang = 2;
  dat('TC-41 Ky 02/2026 ' || v_tt || ': ' || v_phieu || ' phieu cho ' || v_nguoi || ' nguoi (khong trung)',
      v_tt = 'DA_TINH' and v_phieu = 50 and v_nguoi = v_phieu);
  dat('TC-33 Phu cap het hieu luc (31/01) khong vao phieu 02: ' || khoan('NV_B', 'PC_TRACH_NHIEM'),
      khoan('NV_B', 'PC_TRACH_NHIEM') = 0);
  dat('TC-45 Thuong TC45/2026 vao phieu 02 cua NV_B: ' || khoan('NV_B', 'THUONG'),
      khoan('NV_B', 'THUONG') = 1000000);
  dat('TC-34 Dieu chinh NV_A chua duyet chua vao phieu 02: ' || khoan('NV_A', 'DIEU_CHINH_TANG'),
      khoan('NV_A', 'DIEU_CHINH_TANG') = 0);
end;
/
