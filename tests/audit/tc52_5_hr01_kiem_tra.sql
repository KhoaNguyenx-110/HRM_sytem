-- =============================================================================
-- TC-52 buoc 5 (U_HR01): doi chieu audit phan HR qua VW-10 va thu xoa nhat ky
--   Moi thay doi phai co: nguoi (ten dang nhap), thoi diem, gia tri truoc/sau.
-- =============================================================================
set feedback off
set linesize 250
declare
  v_n   number;
  v_cu  varchar2(200);
  v_moi varchar2(200);
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  -- Chay mot cau DML/DDL dong, mong doi bi tu choi vi thieu quyen
  -- (23ai bao ORA-41900 "missing ... privilege" thay cho ORA-01031 khi chi co SELECT)
  procedure thu_xoa(p_ten varchar2, p_sql varchar2) is
  begin
    execute immediate p_sql;
    dat('TC-52 ' || p_ten || ' -> khong bi chan', false);
    rollback;
  exception when others then
    dat('TC-52 ' || p_ten || ' bi tu choi (' || sqlcode || ')', sqlcode in (-942, -1031, -41900, -42399));
  end;
begin
  -- TC-13: email NV_C, ai sua, luc nao
  select count(*), max(json_value(gia_tri_cu, '$.EMAIL')), max(json_value(gia_tri_moi, '$.EMAIL'))
    into v_n, v_cu, v_moi
    from hrm_owner.vw_nhat_ky
   where doi_tuong = 'NHAN_VIEN' and thao_tac = 'UPDATE' and ten_dang_nhap = 'nv005'
     and json_value(gia_tri_moi, '$.EMAIL') = 'nv.c.tc52@hrm.example.com'
     and thoi_diem > systimestamp - interval '1' hour;
  dat('TC-52 NHAN_VIEN UPDATE boi nv005: email ' || v_cu || ' -> ' || v_moi,
      v_n = 1 and v_cu = 'nv.c@hrm.example.com');

  -- TC-14: muc luong moi (INSERT, chi co gia tri moi)
  select count(*), max(json_value(gia_tri_moi, '$.LUONG_CO_BAN'))
    into v_n, v_moi
    from hrm_owner.vw_nhat_ky
   where doi_tuong = 'MUC_LUONG_HOP_DONG' and thao_tac = 'INSERT' and ten_dang_nhap = 'nv005'
     and gia_tri_cu is null and json_value(gia_tri_moi, '$.TU_NGAY') like '2026-12-01%';
  dat('TC-52 MUC_LUONG_HOP_DONG INSERT boi nv005: luong moi ' || v_moi, v_n = 1 and v_moi = '28000000');

  -- TC-14: hop dong bi tu choi khong de lai audit
  select count(*) into v_n from hrm_owner.vw_nhat_ky
   where doi_tuong = 'HOP_DONG' and json_value(gia_tri_moi, '$.SO_HOP_DONG') = 'HD-TC52-LOI';
  dat('TC-52 Hop dong bi tu choi khong co dong audit (' || v_n || ')', v_n = 0);

  -- Han muc phep: dieu chinh truoc/sau
  select count(*), max(json_value(gia_tri_cu, '$.SO_NGAY_DIEU_CHINH')), max(json_value(gia_tri_moi, '$.SO_NGAY_DIEU_CHINH'))
    into v_n, v_cu, v_moi
    from hrm_owner.vw_nhat_ky
   where doi_tuong = 'HAN_MUC_PHEP_NAM' and thao_tac = 'UPDATE' and ten_dang_nhap = 'nv005'
     and json_value(gia_tri_moi, '$.CAN_CU_DIEU_CHINH') like 'TC-52%';
  dat('TC-52 HAN_MUC_PHEP_NAM UPDATE boi nv005: dieu chinh ' || v_cu || ' -> ' || v_moi, v_n = 1 and v_moi = '1');

  -- Moi dong do nv005 ghi deu co thoi diem va gia tri dung theo thao tac
  select count(*) into v_n from hrm_owner.vw_nhat_ky
   where ten_dang_nhap = 'nv005'
     and (thoi_diem is null
          or (thao_tac = 'UPDATE' and (gia_tri_cu is null or gia_tri_moi is null))
          or (thao_tac = 'INSERT' and gia_tri_moi is null)
          or (thao_tac = 'DELETE' and gia_tri_cu is null));
  dat('TC-52 Dong audit cua nv005 thieu thoi diem/truoc/sau: ' || v_n, v_n = 0);

  -- HR khong thay audit phan luong (pham vi VW-10)
  select count(*) into v_n from hrm_owner.vw_nhat_ky
   where doi_tuong in ('PHIEU_LUONG', 'KY_LUONG', 'PHAT_SINH_LUONG');
  dat('TC-52 U_HR01 khong thay audit phieu/ky/phat sinh (' || v_n || ' dong)', v_n = 0);

  -- Thu xoa/sua nhat ky
  thu_xoa('U_HR01 DELETE bang nhat ky',   'delete from hrm_owner.nhat_ky_he_thong');
  thu_xoa('U_HR01 TRUNCATE bang nhat ky', 'truncate table hrm_owner.nhat_ky_he_thong');
  thu_xoa('U_HR01 DELETE qua VW-10',      'delete from hrm_owner.vw_nhat_ky');
  thu_xoa('U_HR01 UPDATE qua VW-10',      'update hrm_owner.vw_nhat_ky set thao_tac = thao_tac');
end;
/
