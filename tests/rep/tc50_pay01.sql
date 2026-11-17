-- =============================================================================
-- TC-50 (U_PAY01): so sanh voi ky truoc co quy bang 0 (QR-21)
--   12/2025 khong co phieu -> quy 0; ty le cua 01/2026 la NULL, khong loi chia 0.
-- =============================================================================
set feedback off
declare
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  for r in (
    with thang as (
      select add_months(date '2025-12-01', level - 1) as dau_thang from dual connect by level <= 3
    ),
    quy as (
      select to_date(nam || '-' || thang, 'YYYY-MM') as dau_thang, sum(tong_gross) as gross
        from hrm_owner.vw_bang_luong_tong_hop group by nam, thang
    ),
    s as (
      select t.dau_thang, nvl(q.gross, 0) as gross from thang t left join quy q on q.dau_thang = t.dau_thang
    )
    select dau_thang, gross, lag(gross) over (order by dau_thang) as truoc,
           round((gross - lag(gross) over (order by dau_thang))
                 / nullif(lag(gross) over (order by dau_thang), 0) * 100, 2) as ty_le
      from s order by dau_thang)
  loop
    if r.dau_thang = date '2026-01-01' then
      dat('TC-50 01/2026: quy truoc = ' || r.truoc || ', ty le = ' || nvl(to_char(r.ty_le), 'NULL')
          || ' (khong loi chia 0)', r.truoc = 0 and r.ty_le is null);
    elsif r.dau_thang = date '2026-02-01' then
      dat('TC-50 02/2026: ty le so voi 01 = ' || r.ty_le || '%', r.ty_le is not null);
    end if;
  end loop;
end;
/
