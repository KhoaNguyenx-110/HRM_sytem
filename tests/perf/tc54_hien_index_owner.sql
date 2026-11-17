-- TC-54 (HRM_OWNER): tra moi index INVISIBLE ve VISIBLE sau khi do
set feedback off
begin
  for r in (select index_name from user_indexes where visibility = 'INVISIBLE') loop
    execute immediate 'alter index ' || r.index_name || ' visible';
    dbms_output.put_line('HIEN  ' || r.index_name);
  end loop;
end;
/
