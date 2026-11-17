-- =============================================================================
-- seed/perf/05_dem.sql - So dong thuc te so voi uoc luong "Sau 3 nam" (muc 5.6)
-- Thu thap thong ke optimizer sau khi nap (execution plan TC-54 dua vao do).
-- =============================================================================
set feedback off
set linesize 200
begin
  dbms_stats.gather_schema_stats(user, cascade => true);
end;
/
declare
  procedure dong(p_bang varchar2, p_muc_tieu number) is
    v number;
  begin
    execute immediate 'select count(*) from ' || p_bang into v;
    dbms_output.put_line('DEM   ' || rpad(p_bang, 24) || lpad(to_char(v, 'FM999G999G990'), 10)
                         || '   (muc 5.6: ' || to_char(p_muc_tieu, 'FM999G999G990') || ')');
  end;
begin
  dong('NHAN_VIEN', 240);              dong('TAI_KHOAN', 245);
  dong('QUA_TRINH_CONG_TAC', 360);     dong('HOP_DONG', 420);
  dong('MUC_LUONG_HOP_DONG', 700);     dong('NGUOI_PHU_THUOC', 180);
  dong('LICH_LAM_VIEC', 1096);         dong('CHAM_CONG', 156000);
  dong('DANG_KY_TANG_CA', 7200);       dong('DON_NGHI_PHEP', 4800);
  dong('CHI_TIET_NGHI_PHEP', 14400);   dong('LICH_SU_DUYET_NGHI', 9600);
  dong('KY_LUONG', 36);                dong('PHIEU_LUONG', 7200);
  dong('CHI_TIET_PHIEU_LUONG', 108000); dong('PHAT_SINH_LUONG', 3600);
  dong('KHOAN_LUONG_NHAN_VIEN', 800);  dong('KHEN_THUONG', 360);
  dong('KY_LUAT', 60);                 dong('NHAT_KY_HE_THONG', 450000);
end;
/
