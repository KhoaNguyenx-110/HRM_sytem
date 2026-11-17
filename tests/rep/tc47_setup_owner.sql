-- =============================================================================
-- TC-47 chuan bi (HRM_OWNER): hop dong DA HUY cua NV010, het han 25/11/2026 - nam
-- trong nguong 30 ngay ke tu 15/11/2026 nhung phai bi loai khoi VW-06.
-- (run_rep.sh dung lai CSDL o cuoi nen khong can don dep.)
-- =============================================================================
set feedback off
declare
  v_nv  number;
  v_lhd number;
begin
  select nhan_vien_id into v_nv from nhan_vien where ma_nhan_vien = 'NV010';
  select loai_hop_dong_id into v_lhd from loai_hop_dong where ma_loai = 'XAC_DINH';
  insert into hop_dong (so_hop_dong, nhan_vien_id, loai_hop_dong_id, ngay_bat_dau, ngay_ket_thuc, da_huy)
  values ('TC47-HUY', v_nv, v_lhd, date '2026-06-01', date '2026-11-25', true);
  commit;
  dbms_output.put_line('Da tao hop dong da huy TC47-HUY (NV010, het han 25/11/2026)');
end;
/
