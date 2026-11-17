-- =============================================================================
-- Bo hieu nang buoc 2 (U_PAY01): tinh va khoa 36 ky 04/2023 -> 03/2026 bang SP-09,
-- SP-11. Ghi thoi gian tinh tung ky (NFR-08: tinh ky ~300 nhan vien <= 30 giay).
-- Dong "TG" dang: TG <ky> <so phieu> <giay tinh> - scripts/seed_perf.sh gom lai.
-- =============================================================================
set feedback off
set linesize 250
declare
  v_so    number;
  v_loi   clob;
  v_id    number;
  v_d     date;
  v_t     timestamp;
  v_giay  number;
  v_phieu number;
  function giay(p_tu timestamp) return number is
    d interval day to second := systimestamp - p_tu;
  begin
    return extract(minute from d) * 60 + extract(second from d);
  end;
begin
  -- Nhu demo: chuyen thuong 001/2026 vao ky 01/2026
  hrm_owner.pkg_payroll.sp_chuyen_thuong('001/2026/QĐ-KT', 1, 2026, v_id);
  commit;
  for i in 0 .. 35 loop
    v_d := add_months(date '2023-04-01', i);
    v_t := systimestamp;
    hrm_owner.pkg_payroll.sp_tinh_luong_ky(extract(month from v_d), extract(year from v_d), v_so, v_loi);
    v_giay := giay(v_t);
    if v_so > 0 then
      dbms_output.put_line('FAIL  tinh ky ' || to_char(v_d, 'MM/YYYY') || ': ' || v_so || ' loi: '
                           || dbms_lob.substr(v_loi, 300, 1));
      rollback;
      return;
    end if;
    hrm_owner.pkg_payroll.sp_khoa_ky_luong(extract(month from v_d), extract(year from v_d));
    commit;
    select count(*) into v_phieu from hrm_owner.vw_bang_luong_tong_hop
     where nam = extract(year from v_d) and thang = extract(month from v_d);
    dbms_output.put_line('TG ' || to_char(v_d, 'YYYY-MM') || ' ' || v_phieu || ' ' || to_char(v_giay, 'FM990.000'));
  end loop;
end;
/
