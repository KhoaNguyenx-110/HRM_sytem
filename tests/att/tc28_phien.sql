-- =============================================================================
-- TC-28 phien duyet (chay dong thoi bang U_HR01 va U_HR02, xem tests/run_att.sh)
--   U_HR01: duyet don 1, giu khoa 6 giay roi COMMIT
--   U_HR02: bat dau sau 2 giay, duyet don 2 -> phai CHO khoa dong, roi bi tu choi
--           vi so du tinh lai sau khi phien 1 commit (BR-17)
-- =============================================================================
set feedback off
declare
  v_user varchar2(30) := sys_context('USERENV', 'SESSION_USER');
  v_don  number;
  v_bat_dau timestamp := systimestamp;
  v_cho  number;
begin
  select ma_yeu_cau into v_don from hrm_owner.vw_don_cho_duyet
   where loai_yeu_cau = 'NGHI_PHEP' and ma_nhan_vien = 'NV019'
     and tu_ngay = case v_user when 'U_HR01' then date '2026-06-01' else date '2026-06-15' end;

  hrm_owner.pkg_leave.sp_xu_ly_don_nghi(v_don, 'DUYET');
  v_cho := extract(second from (systimestamp - v_bat_dau));
  if v_user = 'U_HR01' then
    dbms_output.put_line('PASS  TC-28 Phien 1 (U_HR01) duyet don 1, giu khoa 6 giay');
    dbms_session.sleep(6);
    commit;
  else
    dbms_output.put_line('FAIL  TC-28 Phien 2 duyet duoc don 2 -> vuot han muc');
    rollback;
  end if;
exception when others then
  v_cho := extract(second from (systimestamp - v_bat_dau));
  dbms_output.put_line(case when v_user = 'U_HR02' and sqlcode = -20409 and v_cho >= 2 then 'PASS  ' else 'FAIL  ' end
    || 'TC-28 Phien 2 (' || v_user || ') cho khoa ' || round(v_cho, 1) || ' giay roi bi tu choi ('
    || sqlcode || '): ' || substr(sqlerrm, 12, 120));
  rollback;
end;
/
