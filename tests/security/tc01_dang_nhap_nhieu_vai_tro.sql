-- =============================================================================
-- TC-01 (AUTH-01): dang nhap dung bang U_TP_NS -> phien co ca vai tro HR va MANAGER
-- Chay bang: scripts/run.sh U_TP_NS tests/security/tc01_dang_nhap_nhieu_vai_tro.sql
-- Danh tinh do TR-05 gan luc dang nhap, khong goi gi them.
-- =============================================================================
set feedback off
declare
  v_vt varchar2(400) := sys_context('HRM_CTX', 'VAI_TRO');
  procedure kq(p_ten varchar2, p_dat boolean) is
  begin
    dbms_output.put_line(case when p_dat then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  dbms_output.put_line('[U_TP_NS] TAI_KHOAN_ID=' || sys_context('HRM_CTX', 'TAI_KHOAN_ID')
    || ' NHAN_VIEN_ID=' || sys_context('HRM_CTX', 'NHAN_VIEN_ID')
    || ' VAI_TRO=' || v_vt || ' KENH=' || sys_context('HRM_CTX', 'KENH'));
  kq('TC-01 Co danh tinh phien sau dang nhap', sys_context('HRM_CTX', 'TAI_KHOAN_ID') is not null);
  kq('TC-01 Phien co vai tro HR',      instr(v_vt, ',HR,') > 0);
  kq('TC-01 Phien co vai tro MANAGER', instr(v_vt, ',MANAGER,') > 0);
  kq('TC-01 Kenh DBEAVER',             sys_context('HRM_CTX', 'KENH') = 'DBEAVER');
end;
/
