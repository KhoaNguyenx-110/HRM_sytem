-- =============================================================================
-- TC-49 (U_PAY01): quy luong phong cu cua ky cu khong doi sau dieu chuyen.
-- Chay hai lan (truoc va sau tc49_hr01.sql); run_rep.sh so sanh dong "QUY ..."
-- giua hai lan. Kem kiem tra: phieu luu phong tai thoi diem tinh (snapshot).
-- =============================================================================
set feedback off
declare
  v_gross number;
  v_so    number;
  v_pb    varchar2(20);
  v_n     number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select sum(tong_gross), count(*) into v_gross, v_so
    from hrm_owner.vw_bang_luong_tong_hop
   where nam = 2026 and thang = 1 and ma_phong_ban = 'KINH_DOANH';
  dbms_output.put_line('QUY KINH_DOANH 01/2026 = ' || v_gross || ' | ' || v_so || ' phieu');

  -- NV023 chuyen sang KY_THUAT tu 01/02/2026: phieu 01 van ghi KINH_DOANH
  select ma_phong_ban into v_pb from hrm_owner.vw_bang_luong_tong_hop
   where nam = 2026 and thang = 1 and ma_nhan_vien = 'NV023';
  select count(*) into v_n from hrm_owner.vw_bang_luong_tong_hop
   where nam = 2026 and thang = 2 and ma_nhan_vien = 'NV023' and ma_phong_ban = 'KY_THUAT';
  dat('TC-49 NV023: phieu 01 thuoc ' || v_pb || ', phieu 02 thuoc KY_THUAT (' || v_n || ')',
      v_pb = 'KINH_DOANH' and v_n = 1);

  -- NV024: phong hien tai (VW-01) va phong tren phieu 01
  select ma_phong_ban into v_pb from hrm_owner.vw_ho_so_nhan_vien where ma_nhan_vien = 'NV024';
  dbms_output.put_line('NV024 phong hien tai (VW-01) = ' || v_pb);
  select ma_phong_ban into v_pb from hrm_owner.vw_bang_luong_tong_hop
   where nam = 2026 and thang = 1 and ma_nhan_vien = 'NV024';
  dat('TC-49 NV024 tren phieu 01/2026 van thuoc ' || v_pb, v_pb = 'KINH_DOANH');
end;
/
