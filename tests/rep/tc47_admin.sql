-- =============================================================================
-- QR-05 (U_ADMIN): nguoi dang lam chua co tai khoan = NV051; VW-13 khong co cot
-- nhay cam; Admin van khong doc duoc VW-01 (TC-08).
-- =============================================================================
set feedback off
declare
  v_ds varchar2(200);
  v_n  number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select listagg(d.ma_nhan_vien, ',') within group (order by d.ma_nhan_vien) into v_ds
    from hrm_owner.vw_danh_ba_nhan_vien d
   where d.ngay_vao_lam <= date '2026-11-15'
     and (d.ngay_nghi_viec is null or d.ngay_nghi_viec >= date '2026-11-15')
     and not exists (select 1 from hrm_owner.vw_tai_khoan_quan_tri t where t.ma_nhan_vien = d.ma_nhan_vien);
  dat('QR-05 Nguoi dang lam chua co tai khoan: ' || nvl(v_ds, '(khong co)'), v_ds = 'NV051');

  select count(*) into v_n from all_tab_columns
   where owner = 'HRM_OWNER' and table_name = 'VW_DANH_BA_NHAN_VIEN'
     and column_name in ('SO_DINH_DANH', 'MA_SO_THUE', 'NGAY_SINH', 'DIA_CHI', 'SO_DIEN_THOAI');
  dat('VW-13 Danh ba Admin khong co cot dinh danh, MST, ngay sinh, dia chi: ' || v_n, v_n = 0);
  begin
    execute immediate 'select count(*) from hrm_owner.vw_ho_so_nhan_vien' into v_n;
    dat('TC-08 Admin doc VW-01 -> khong bi chan', false);
  exception when others then
    dat('TC-08 Admin van khong doc duoc VW-01 (' || sqlcode || ')', sqlcode = -942);
  end;
end;
/
