-- =============================================================================
-- TC-31 tao ky; TC-35 tinh khi cong chua chot - chay bang U_PAY01
--   TC-31: tao ky trung (01/2026), thang 13 -> ca hai bi tu choi
--   TC-35a: tinh ky 01/2026 khi con MO -> tu choi, khong co phieu nao
--   Chuan bi TC-35b: tao ky 12/2025 (chua co chinh sach 2025) - COMMIT
-- =============================================================================
set feedback off
declare
  v_id    number;
  v_so    number;
  v_loi   clob;
  v_phieu number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  -- Thu tuc noi bo danh_dau_tinh_lai: ACCESSIBLE BY chan goi truc tiep
  begin
    execute immediate 'begin hrm_owner.pkg_payroll.danh_dau_tinh_lai(sysdate, sysdate); end;';
    dat('BR-38 Payroll goi truc tiep danh_dau_tinh_lai -> khong bi chan', false);
  exception when others then
    dat('BR-38 Goi truc tiep danh_dau_tinh_lai bi chan boi ACCESSIBLE BY (' || sqlcode || ')',
        sqlcode = -6550 and sqlerrm like '%PLS-00904%');
  end;

  -- TC-31
  begin
    hrm_owner.pkg_payroll.sp_tao_ky_luong(1, 2026, null, v_id);
    dat('TC-31 Tao ky trung 01/2026 -> khong bi chan', false);
  exception when others then
    dat('TC-31 Tao ky trung 01/2026 bi tu choi (' || sqlcode || '): ' || substr(sqlerrm, 12, 80), sqlcode = -20510);
  end;
  begin
    hrm_owner.pkg_payroll.sp_tao_ky_luong(13, 2026, null, v_id);
    dat('TC-31 Tao ky thang 13 -> khong bi chan', false);
  exception when others then
    dat('TC-31 Tao ky thang 13 bi tu choi (' || sqlcode || '): ' || substr(sqlerrm, 12, 80), sqlcode = -20511);
  end;
  begin
    hrm_owner.pkg_payroll.sp_tao_ky_luong(4, 2026, date '2026-05-05', v_id);
    dat('TC-31 Ngay chi tra ngoai thang -> khong bi chan', false);
  exception when others then
    dat('TC-31 Ngay chi tra ngoai thang bi tu choi (' || sqlcode || ')', sqlcode = -20512);
  end;

  -- TC-35a
  begin
    hrm_owner.pkg_payroll.sp_tinh_luong_ky(1, 2026, v_so, v_loi);
    dat('TC-35 Tinh ky 01/2026 khi cong chua chot -> khong bi chan', false);
  exception when others then
    dat('TC-35 Tinh ky chua chot cong bi tu choi (' || sqlcode || '): ' || substr(sqlerrm, 12, 80), sqlcode = -20503);
  end;
  select count(*) into v_phieu from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1;
  dat('TC-35 Khong co phieu nao duoc ghi: ' || v_phieu, v_phieu = 0);

  -- Chuan bi TC-35b: ky 12/2025, truoc phien ban chinh sach dau tien (01/2026)
  hrm_owner.pkg_payroll.sp_tao_ky_luong(12, 2025, null, v_id);
  dat('TC-31 Tao ky hop le 12/2025 (MO)', v_id is not null);
  commit;
end;
/
