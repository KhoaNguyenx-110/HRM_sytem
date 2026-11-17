-- =============================================================================
-- TC-24 (FR-ATT-06): tong cong, nghi, OT theo ky qua VW-03 - chay bang U_PAY01
--   scripts/run.sh U_PAY01 tests/att/tc24_pay01.sql
-- =============================================================================
set feedback off
declare
  v1 number; v2 number; v3 number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  function gt(p_ma varchar2, p_thang number, p_cot varchar2) return number is
    v number;
  begin
    execute immediate 'select ' || p_cot || ' from hrm_owner.vw_cong_thang where ma_nhan_vien = :1 and thang = :2 and nam = 2026'
      into v using p_ma, p_thang;
    return v;
  end;
begin
  dat('TC-24 OT da duyet cua NV_B thang 1 duoc cong: ' || gt('NV_B', 1, 'ot_ngay_thuong') || ' gio',
      gt('NV_B', 1, 'ot_ngay_thuong') = 3);
  dat('TC-24 OT bi tu choi cua NV041 thang 3 khong cong: ' || gt('NV041', 3, 'ot_ngay_thuong + ot_nghi_tuan + ot_le'),
      gt('NV041', 3, 'ot_ngay_thuong + ot_nghi_tuan + ot_le') = 0);
  dat('TC-24 OT ngay le cua NV037 thang 2 tach rieng: ' || gt('NV037', 2, 'ot_le') || ' gio',
      gt('NV037', 2, 'ot_le') = 4);
  dat('FN-02 NV_A thang 1: 168 gio cong + 8 gio le = ' || gt('NV_A', 1, 'gio_huong_luong'),
      gt('NV_A', 1, 'gio_cong') = 168 and gt('NV_A', 1, 'gio_huong_luong') = 176);
  dat('FN-02 NV037 thang 1: 158 gio cong, nghi om khong huong luong, + 8 le = ' || gt('NV037', 1, 'gio_huong_luong'),
      gt('NV037', 1, 'gio_cong') = 158 and gt('NV037', 1, 'gio_huong_luong') = 166);
  dat('FN-02 NV049 vao lam 15/01: chi tinh tu ngay vao lam (' || gt('NV049', 1, 'gio_huong_luong') || ' gio)',
      gt('NV049', 1, 'gio_huong_luong') = 96);

  select count(*) into v1 from hrm_owner.vw_cong_thang where nam = 2026 and thang = 3;
  dat('TC-24 Payroll thay ky 03/2026 cua ' || v1 || ' nhan vien (gom nguoi nghi viec giua thang)', v1 = 50);
end;
/
