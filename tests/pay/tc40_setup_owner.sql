-- =============================================================================
-- TC-40 chuan bi (HRM_OWNER): trigger TAM gay loi co chu dich khi ghi phieu cua
-- NV_B, tuc la GIUA buoc ghi ket qua (sau khi da xoa phieu cu va ghi mot so
-- phieu moi). tc40_cleanup_owner.sql xoa trigger.
-- =============================================================================
set feedback off
declare
  v_nv number;
begin
  select nhan_vien_id into v_nv from nhan_vien where ma_nhan_vien = 'NV_B';
  execute immediate '
    create or replace trigger tc40_loi_co_chu_dich
      before insert on phieu_luong for each row
      when (new.nhan_vien_id = ' || v_nv || ')
    begin
      raise_application_error(-20999, ''TC-40 loi co chu dich khi ghi phieu NV_B'');
    end;';
  dbms_output.put_line('Da tao trigger tc40_loi_co_chu_dich (NV_B id ' || v_nv || ')');
end;
/
