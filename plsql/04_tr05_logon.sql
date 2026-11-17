-- =============================================================================
-- 04_tr05_logon.sql - TR-05: gan danh tinh khi dang nhap (kenh DBeaver, muc 8.1)
--
-- AFTER LOGON ON DATABASE, thuoc HRM_OWNER (can ADMINISTER DATABASE TRIGGER).
-- An toan van hanh: trigger KHONG BAO GIO nem loi. Loi trong logon trigger se
-- chan dang nhap cua moi user khong co quyen ADMINISTER DATABASE TRIGGER, ke ca
-- HRM_APP. Vi vay uninstall.sql xoa trigger nay TRUOC khi xoa pkg_ctx.
-- =============================================================================

create or replace trigger tr05_gan_danh_tinh
  after logon on database
begin
  -- Bo qua user he thong va user ky thuat; chi user anh xa tai khoan moi duoc nap
  if sys_context('USERENV', 'SESSION_USER') not in ('SYS', 'SYSTEM', 'HRM_OWNER', 'HRM_APP') then
    pkg_ctx.dat_phien_dang_nhap;
  end if;
exception
  when others then
    null;   -- khong chan dang nhap; phien se khong co danh tinh (view 0 dong)
end;
/
show errors
