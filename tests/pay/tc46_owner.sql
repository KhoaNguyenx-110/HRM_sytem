-- =============================================================================
-- TC-46 buoc 2 (HRM_OWNER): ky luat khong sinh phat tien hay tru luong (BR-31)
--   * NV010 co quyet dinh ky luat nhung khong co dong PHAT_SINH_LUONG nao
--   * Khong co trigger nao tren KY_LUAT, khong doi tuong nao vua doc KY_LUAT vua
--     ghi PHAT_SINH_LUONG ngoai pkg_hr (pkg_hr chi INSERT KY_LUAT)
-- =============================================================================
set feedback off
declare
  v_kl number;
  v_ps number;
  v_tg number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select count(*) into v_kl from ky_luat k join nhan_vien n on n.nhan_vien_id = k.nhan_vien_id
   where n.ma_nhan_vien = 'NV010' and k.so_quyet_dinh = 'TC46/2026/QĐ-KL';
  select count(*) into v_ps from phat_sinh_luong s join nhan_vien n on n.nhan_vien_id = s.nhan_vien_id
   where n.ma_nhan_vien = 'NV010';
  select count(*) into v_tg from user_triggers where table_name = 'KY_LUAT';
  dat('TC-46 Ky luat da ghi: ' || v_kl || '; phat sinh luong cua NV010: ' || v_ps, v_kl = 1 and v_ps = 0);
  dat('TC-46 Khong co trigger tren KY_LUAT: ' || v_tg, v_tg = 0);
end;
/
