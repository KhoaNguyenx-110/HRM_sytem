-- =============================================================================
-- Bo hieu nang buoc 1 (U_HR01): chot cong 36 ky 04/2023 -> 03/2026 bang SP-07
-- (cung procedure nghiep vu, khong cap nhat trang thai truc tiep). COMMIT tung ky.
-- =============================================================================
set feedback off
set linesize 250
declare
  v_so  number;
  v_loi clob;
  v_d   date;
  v_t   timestamp;
begin
  for i in 0 .. 35 loop
    v_d := add_months(date '2023-04-01', i);
    v_t := systimestamp;
    hrm_owner.pkg_att.sp_chot_cong(extract(month from v_d), extract(year from v_d), v_so, v_loi);
    if v_so > 0 then
      dbms_output.put_line('FAIL  chot cong ' || to_char(v_d, 'MM/YYYY') || ': ' || v_so || ' loi: '
                           || dbms_lob.substr(v_loi, 300, 1));
      rollback;
      return;
    end if;
    commit;
    if mod(i, 6) = 5 or i = 35 then
      dbms_output.put_line('Da chot cong den ' || to_char(v_d, 'MM/YYYY') || ' ('
        || round(extract(second from systimestamp - v_t) + 60 * extract(minute from systimestamp - v_t), 2) || ' s ky cuoi)');
    end if;
  end loop;
end;
/
