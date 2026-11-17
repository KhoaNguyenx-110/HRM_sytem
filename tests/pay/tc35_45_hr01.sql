-- =============================================================================
-- Buoc HR chuan bi cho kiem thu luong - chay bang U_HR01, COMMIT
--   * Chot cong 12/2025, 01/2026, 02/2026 (TC-35b, TC-36, TC-41)
--   * Tao quyet dinh thuong tien TC45/2026 cho NV_B (U_HR02 duyet, TC-45)
-- =============================================================================
set feedback off
declare
  v_so  number;
  v_loi clob;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  for k in (select 12 as thang, 2025 as nam from dual
            union all select 1, 2026 from dual
            union all select 2, 2026 from dual) loop
    hrm_owner.pkg_att.sp_chot_cong(k.thang, k.nam, v_so, v_loi);
    dat('Chot cong ' || lpad(k.thang, 2, '0') || '/' || k.nam || ': ' || v_so || ' loi', v_so = 0);
  end loop;

  hrm_owner.pkg_hr.sp_luu_khen_thuong('NV_B', 'TC45/2026/QĐ-KT', date '2026-01-26',
    'TC-45 thưởng sáng kiến', 'TIEN', 1000000);
  commit;
end;
/
