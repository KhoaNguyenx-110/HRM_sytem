-- =============================================================================
-- TC-54 phan do (U_PAY01) - goi tu tc54_truoc_pay01.sql / tc54_sau_pay01.sql.
-- Bien :p_che_do = 'TRUOC' | 'SAU' do file goi dat.
--   (Execution plan lay rieng bang owner: tests/perf/tc54_plan_owner.sql, vi EXPLAIN PLAN
--    tren view cua schema khac can quyen tren bang goc - ORA-01039.)
--   Chay moi truy van 30 lan voi tham so doi dan (ky, nhan vien khac nhau),
--      doc het dong; ghi thoi gian tung lan (ms) va logical reads (v$mystat).
--      Dong ket qua:  DO <che do> <QR> <so lan> <p50 ms> <p95 ms> <max ms> <gets/lan> <dong/lan>
-- Truy van giong file queries/qrNN (cung view, cung dieu kien).
-- =============================================================================
set feedback off
set linesize 200
set pagesize 0
set trimspool on
variable p_nam   number
variable p_thang number
variable p_phong varchar2(20)
variable p_ma    varchar2(20)
variable p_tu_ky  varchar2(7)
variable p_den_ky varchar2(7)
exec :p_nam := 2025; :p_thang := 6; :p_phong := 'KY_THUAT'; :p_ma := 'NV150'; :p_tu_ky := '2023-04'; :p_den_ky := '2026-03'

-- --------------------------------------------------------------------- DO
declare
  c_lan  constant pls_integer := 30;
  v_che_do varchar2(5) := :p_che_do;
  v_ms   sys.odcinumberlist := sys.odcinumberlist();
  v_t    timestamp;
  v_g0   number;
  v_gets number;
  v_dong number;
  v_n    number;
  v_ma   varchar2(20);
  v_d    date;

  function gets return number is
    v number;
  begin
    select m.value into v from v$mystat m join v$statname s on s.statistic# = m.statistic#
     where s.name = 'session logical reads';
    return v;
  end;
  procedure bat_dau is
  begin
    v_g0 := gets;
    v_t  := systimestamp;
  end;
  procedure ket_thuc is
    d interval day to second := systimestamp - v_t;
  begin
    v_ms.extend;
    v_ms(v_ms.count) := (extract(minute from d) * 60 + extract(second from d)) * 1000;
    v_gets := v_gets + (gets - v_g0);
  end;
  procedure in_ket_qua(p_qr varchar2) is
    v_p50 number; v_p95 number; v_max number;
  begin
    select percentile_disc(0.5)  within group (order by column_value),
           percentile_disc(0.95) within group (order by column_value),
           max(column_value)
      into v_p50, v_p95, v_max
      from table(v_ms);
    dbms_output.put_line('DO ' || v_che_do || ' ' || p_qr || ' ' || v_ms.count
      || ' ' || to_char(v_p50, 'FM99990.0') || ' ' || to_char(v_p95, 'FM99990.0')
      || ' ' || to_char(v_max, 'FM99990.0') || ' ' || round(v_gets / v_ms.count)
      || ' ' || round(v_dong / v_ms.count));
    v_ms.delete; v_ms := sys.odcinumberlist(); v_gets := 0; v_dong := 0;
  end;
begin
  v_gets := 0; v_dong := 0;

  -- QR-08: 30 lan, moi lan mot ky (04/2023 + i) va mot phong
  for i in 1 .. c_lan loop
    v_d := add_months(date '2023-04-01', mod(i * 7, 36));
    bat_dau;
    for r in (select ma_phong_ban, ma_nhan_vien, gio_cong, gio_huong_luong,
                     ot_ngay_thuong + ot_nghi_tuan + ot_le as gio_ot
                from hrm_owner.vw_cong_thang
               where nam = extract(year from v_d) and thang = extract(month from v_d)
                 and ma_phong_ban = case mod(i, 2) when 0 then 'KY_THUAT' else 'KINH_DOANH' end
               order by ma_phong_ban, ma_nhan_vien) loop
      v_dong := v_dong + 1;
    end loop;
    ket_thuc;
  end loop;
  in_ket_qua('QR08');

  -- QR-17: 30 lan, moi lan mot nguoi va mot ky co phieu
  for i in 1 .. c_lan loop
    v_d  := add_months(date '2023-04-01', mod(i * 5, 33));
    v_ma := 'NV' || (101 + mod(i * 13, 170));
    bat_dau;
    for r in (select ma_khoan, so_luong, don_gia, he_so, thanh_tien
                from hrm_owner.vw_phieu_luong_ca_nhan
               where ma_nhan_vien = v_ma and nam = extract(year from v_d) and thang = extract(month from v_d)
               order by chi_tiet_id) loop
      v_dong := v_dong + 1;
    end loop;
    ket_thuc;
  end loop;
  in_ket_qua('QR17');

  -- QR-18: 30 lan, moi lan mot ky
  for i in 1 .. c_lan loop
    v_d := add_months(date '2023-04-01', mod(i * 7, 36));
    bat_dau;
    for r in (select ten_phong_ban, count(*) as so, sum(tong_gross) as gross, sum(tong_net) as net,
                     sum(chi_phi_doanh_nghiep) as chi_phi
                from hrm_owner.vw_bang_luong_tong_hop
               where nam = extract(year from v_d) and thang = extract(month from v_d)
               group by rollup (ten_phong_ban)) loop
      v_dong := v_dong + 1;
    end loop;
    ket_thuc;
  end loop;
  in_ket_qua('QR18');

  -- QR-21: 30 lan, khoang 12 thang truot dan trong 3 nam
  for i in 1 .. c_lan loop
    v_d := add_months(date '2023-04-01', mod(i, 25));
    bat_dau;
    for r in (with thang as (
                select add_months(v_d, level - 1) as dau_thang from dual connect by level <= 12),
              quy as (
                select to_date(nam || '-' || thang, 'YYYY-MM') as dau_thang, sum(tong_gross) as gross
                  from hrm_owner.vw_bang_luong_tong_hop group by nam, thang)
              select t.dau_thang, nvl(q.gross, 0) as gross,
                     lag(nvl(q.gross, 0)) over (order by t.dau_thang) as truoc
                from thang t left join quy q on q.dau_thang = t.dau_thang) loop
      v_dong := v_dong + 1;
    end loop;
    ket_thuc;
  end loop;
  in_ket_qua('QR21');
end;
/
