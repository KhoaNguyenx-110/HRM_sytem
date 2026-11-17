-- TC-38 don dep (HRM_OWNER): xoa phat sinh kiem thu (ky 01 dang CHOT_CONG nen TR-02 cho phep)
set feedback off
begin
  delete from phat_sinh_luong where can_cu like 'TC-38%';
  dbms_output.put_line('Da xoa ' || sql%rowcount || ' phat sinh TC-38');
  commit;
end;
/
