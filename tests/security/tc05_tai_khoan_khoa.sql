-- =============================================================================
-- TC-05 (AUTH-04, BR-04): tai khoan nghiep vu KHOA
-- Chay bang: scripts/run.sh U_NV_KHOA tests/security/tc05_tai_khoan_khoa.sql
-- Oracle van cho dang nhap, nhung pkg_ctx khong gan danh tinh => procedure tu choi.
-- (Phan "view 0 dong" kiem tra lai o giai doan 5 khi co view.)
-- =============================================================================
set feedback off
declare
  procedure kq(p_ten varchar2, p_dat boolean) is
  begin
    dbms_output.put_line(case when p_dat then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  kq('TC-05 Tai khoan KHOA khong co danh tinh phien', sys_context('HRM_CTX', 'TAI_KHOAN_ID') is null);
  kq('TC-05 Khong co vai tro trong phien',            sys_context('HRM_CTX', 'VAI_TRO') is null);
  begin
    hrm_owner.pkg_auth.sp_doi_mat_khau('$2b$12$bat.ky', '$2b$12$moi');
    kq('TC-05 Procedure tu choi tai khoan KHOA', false);
  exception when others then
    kq('TC-05 Procedure tu choi tai khoan KHOA (' || sqlcode || ')', sqlcode = -20003);
  end;
  rollback;
end;
/
