-- TC-54 (SYS): cho U_PAY01 doc thong ke phien cua chinh minh (logical reads)
grant select on sys.v_$mystat   to u_pay01;
grant select on sys.v_$statname to u_pay01;
