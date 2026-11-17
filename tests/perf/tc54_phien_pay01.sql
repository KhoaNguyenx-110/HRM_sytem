-- =============================================================================
-- TC-54 / NFR-06 (U_PAY01): mot phien trong bai do 10 phien dong thoi.
-- Moi phien chay xen ke 20 lan QR-17 (phieu mot nguoi mot ky) va 20 lan QR-08
-- (cong mot phong mot ky); tham so doi theo SID va so lan de cac phien khong doc
-- cung mot ban ghi. Dong ket qua: PH <QR> <ms>
-- =============================================================================
set feedback off
set linesize 200
declare
  v_sid number := to_number(sys_context('USERENV', 'SID'));
  v_t   timestamp;
  v_d   date;
  v_ma  varchar2(20);
  v_n   number;
  function ms(p timestamp) return number is
    d interval day to second := systimestamp - p;
  begin
    return round((extract(minute from d) * 60 + extract(second from d)) * 1000, 1);
  end;
begin
  for i in 1 .. 20 loop
    v_d  := add_months(date '2023-04-01', mod(v_sid * 7 + i * 5, 33));
    v_ma := 'NV' || (101 + mod(v_sid * 11 + i * 13, 170));
    v_t  := systimestamp;
    v_n  := 0;
    for r in (select ma_khoan, thanh_tien from hrm_owner.vw_phieu_luong_ca_nhan
               where ma_nhan_vien = v_ma and nam = extract(year from v_d) and thang = extract(month from v_d)
               order by chi_tiet_id) loop
      v_n := v_n + 1;
    end loop;
    dbms_output.put_line('PH QR17 ' || ms(v_t));

    v_t := systimestamp;
    for r in (select ma_nhan_vien, gio_cong, gio_huong_luong from hrm_owner.vw_cong_thang
               where nam = extract(year from v_d) and thang = extract(month from v_d)
                 and ma_phong_ban = case mod(v_sid + i, 2) when 0 then 'KY_THUAT' else 'KINH_DOANH' end) loop
      v_n := v_n + 1;
    end loop;
    dbms_output.put_line('PH QR08 ' || ms(v_t));
  end loop;
end;
/
