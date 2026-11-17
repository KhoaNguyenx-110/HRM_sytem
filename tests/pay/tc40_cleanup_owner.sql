-- TC-40 don dep (HRM_OWNER): xoa trigger gay loi tam
set feedback off
begin
  execute immediate 'drop trigger tc40_loi_co_chu_dich';
  dbms_output.put_line('Da xoa trigger tc40_loi_co_chu_dich');
end;
/
