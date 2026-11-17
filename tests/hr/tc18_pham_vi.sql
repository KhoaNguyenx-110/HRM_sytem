-- =============================================================================
-- TC-18 (FR-EMP-07): tra cuu ho so bang cac vai tro khac nhau qua VW-01
-- Chay lan luot bang U_NV_A, U_TP_KT, U_TP_KD, U_HR01:
--   scripts/run.sh U_NV_A tests/hr/tc18_pham_vi.sql
-- Ky vong theo SESSION_USER.
-- =============================================================================
set feedback off
declare
  v_user  varchar2(30) := sys_context('USERENV', 'SESSION_USER');
  v_dem   number;
  v_khac  number;
  v_che   number;
  v_mst   number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || '[' || v_user || '] ' || p_ten);
  end;
begin
  select count(*) into v_dem from hrm_owner.vw_ho_so_nhan_vien;

  if v_user = 'U_NV_A' then
    select count(*) into v_che from hrm_owner.vw_ho_so_nhan_vien where so_dinh_danh like '*%';
    dat('TC-18 Nhan vien chi thay chinh minh (' || v_dem || ' dong)', v_dem = 1);
    select count(*) into v_khac from hrm_owner.vw_ho_so_nhan_vien where ma_nhan_vien = 'NV_A';
    dat('TC-18 Dong do la NV_A, dinh danh khong bi che', v_khac = 1 and v_che = 0);

  elsif v_user in ('U_TP_KT', 'U_TP_KD') then
    select count(*) into v_khac from hrm_owner.vw_ho_so_nhan_vien
     where ma_phong_ban <> case v_user when 'U_TP_KT' then 'KY_THUAT' else 'KINH_DOANH' end;
    select count(*) into v_che from hrm_owner.vw_ho_so_nhan_vien
     where so_dinh_danh not like '********%' and ma_nhan_vien not in ('NV033', 'NV019');
    select count(*) into v_mst from hrm_owner.vw_ho_so_nhan_vien
     where ma_so_thue is not null and ma_nhan_vien not in ('NV033', 'NV019');
    dat('TC-18 Truong phong thay ' || v_dem || ' nguoi, khong ai phong khac', v_dem > 1 and v_khac = 0);
    dat('TC-18 Dinh danh nguoi khac chi hien 4 so cuoi', v_che = 0);
    dat('TC-18 Ma so thue nguoi khac bi an', v_mst = 0);
    -- SQL dong: user khong co quyen VW-07 van bien dich duoc khoi lenh
    execute immediate 'select count(*) from hrm_owner.vw_nhan_su_phong' into v_dem;
    dat('VW-07 Nhan su phong minh (' || v_dem || ' nguoi)', v_dem > 1);

  elsif v_user = 'U_HR01' then
    select count(*) into v_che from hrm_owner.vw_ho_so_nhan_vien where so_dinh_danh like '*%';
    dat('TC-18 HR thay du 50 ho so (' || v_dem || ')', v_dem = 50);
    dat('TC-18 HR thay dinh danh day du', v_che = 0);
  end if;
end;
/
