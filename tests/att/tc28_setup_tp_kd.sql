-- =============================================================================
-- TC-28 buoc 1 (U_TP_KD): tao 2 don phep nam 6 ngay, COMMIT.
-- NV019 co han muc 12, da duyet 1 ngay (27/03): du cho mot don, khong du cho ca hai.
-- Nguoi gui la truong phong nen moi HR deu duyet duoc (muc 2.4).
-- =============================================================================
set feedback off
declare
  v1 number; v2 number;
begin
  hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-06-01', date '2026-06-08', 'CA_NGAY', 'TC-28 đơn 1', v1);
  hrm_owner.pkg_leave.sp_dang_ky_nghi('PHEP_NAM', date '2026-06-15', date '2026-06-22', 'CA_NGAY', 'TC-28 đơn 2', v2);
  commit;
  dbms_output.put_line('PASS  TC-28 Chuan bi: 2 don 6 ngay (' || v1 || ', ' || v2 || ')');
end;
/
