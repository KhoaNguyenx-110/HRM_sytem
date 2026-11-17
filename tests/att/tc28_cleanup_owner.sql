-- Xoa 2 don thu cua TC-28 va kiem tra so du (HRM_OWNER)
set feedback off
declare
  v_con number;
begin
  select fn_phep_con_lai(nhan_vien_id, 2026) into v_con from nhan_vien where ma_nhan_vien = 'NV019';
  dbms_output.put_line(case when v_con >= 0 then 'PASS  ' else 'FAIL  ' end
    || 'TC-28 So du NV019 sau hai phien: ' || v_con || ' ngay (khong am)');
  delete from lich_su_duyet_nghi where don_nghi_id in (select don_nghi_id from don_nghi_phep where ly_do like 'TC-28%');
  delete from chi_tiet_nghi_phep where don_nghi_id in (select don_nghi_id from don_nghi_phep where ly_do like 'TC-28%');
  delete from don_nghi_phep where ly_do like 'TC-28%';
  commit;
end;
/
