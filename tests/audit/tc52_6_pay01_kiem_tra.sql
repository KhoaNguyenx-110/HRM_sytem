-- =============================================================================
-- TC-52 buoc 6 (U_PAY01): doi chieu audit phan luong qua VW-10 va thu xoa nhat ky
--   Phat sinh (nv012 lap, nv006 duyet), ky 03 (phien ban, DA_TINH, DA_KHOA),
--   phieu NV_C ky 03 (DELETE ban cu, INSERT ban moi: gross tang dung 2.000.000).
-- =============================================================================
set feedback off
set linesize 250
declare
  v_n     number;
  v_ky    number;
  v_nv    number;
  v_cu    number;
  v_moi   number;
  v_phieu number;
  v_xoa   number;
  v_them  number;
  v_s     varchar2(1000);
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure thu_xoa(p_ten varchar2, p_sql varchar2) is
  begin
    execute immediate p_sql;
    dat('TC-52 ' || p_ten || ' -> khong bi chan', false);
    rollback;
  exception when others then
    dat('TC-52 ' || p_ten || ' bi tu choi (' || sqlcode || ')', sqlcode in (-942, -1031, -41900, -42399));
  end;
begin
  select ky_luong_id into v_ky from hrm_owner.ky_luong where nam = 2026 and thang = 3;

  -- Phat sinh: INSERT boi nv012 (CHO_DUYET), UPDATE boi nv006 (CHO_DUYET -> DA_DUYET)
  select count(*) into v_n from hrm_owner.vw_nhat_ky
   where doi_tuong = 'PHAT_SINH_LUONG' and thao_tac = 'INSERT' and ten_dang_nhap = 'nv012'
     and json_value(gia_tri_moi, '$.KY_LUONG_ID' returning number) = v_ky
     and json_value(gia_tri_moi, '$.SO_TIEN' returning number) = 2000000
     and json_value(gia_tri_moi, '$.TRANG_THAI_DUYET') = 'CHO_DUYET';
  dat('TC-52 PHAT_SINH_LUONG INSERT boi nv012 (2.000.000, CHO_DUYET)', v_n = 1);
  select count(*) into v_n from hrm_owner.vw_nhat_ky
   where doi_tuong = 'PHAT_SINH_LUONG' and thao_tac = 'UPDATE' and ten_dang_nhap = 'nv006'
     and json_value(gia_tri_cu,  '$.TRANG_THAI_DUYET') = 'CHO_DUYET'
     and json_value(gia_tri_moi, '$.TRANG_THAI_DUYET') = 'DA_DUYET';
  dat('TC-52 PHAT_SINH_LUONG UPDATE boi nv006: CHO_DUYET -> DA_DUYET', v_n = 1);

  -- Ky 03: chuoi thay doi theo thu tu ghi (nguoi:trang thai cu>moi (phien ban dau vao))
  for r in (select ten_dang_nhap || ':' || json_value(gia_tri_cu, '$.TRANG_THAI') || '>'
                   || json_value(gia_tri_moi, '$.TRANG_THAI')
                   || '(v' || json_value(gia_tri_moi, '$.PHIEN_BAN_DAU_VAO') || ')' as buoc
              from hrm_owner.vw_nhat_ky
             where doi_tuong = 'KY_LUONG' and khoa_ban_ghi = to_char(v_ky)
               and ten_dang_nhap in ('nv006', 'nv012')
             order by nhat_ky_id) loop
    v_s := v_s || case when v_s is not null then ' ; ' end || r.buoc;
  end loop;
  dbms_output.put_line('TK    Ky 03 audit: ' || v_s);
  select count(*) into v_n from hrm_owner.vw_nhat_ky
   where doi_tuong = 'KY_LUONG' and khoa_ban_ghi = to_char(v_ky) and ten_dang_nhap = 'nv012'
     and json_value(gia_tri_cu, '$.TRANG_THAI') = 'DA_TINH'
     and json_value(gia_tri_moi, '$.TRANG_THAI') = 'DA_KHOA';
  dat('TC-52 KY_LUONG ky 03: co dong DA_TINH -> DA_KHOA boi nv012', v_n = 1);
  select count(*) into v_n from hrm_owner.vw_nhat_ky
   where doi_tuong = 'KY_LUONG' and khoa_ban_ghi = to_char(v_ky) and ten_dang_nhap = 'nv006'
     and json_value(gia_tri_moi, '$.PHIEN_BAN_DAU_VAO' returning number)
       > json_value(gia_tri_cu, '$.PHIEN_BAN_DAU_VAO' returning number);
  dat('TC-52 KY_LUONG ky 03: duyet phat sinh (nv006) tang phien ban dau vao', v_n = 1);

  -- Phieu: demo tinh ky 03 (INSERT) + tinh lai (DELETE ban cu, INSERT ban moi)
  select count(*) into v_phieu from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 3;
  select count(case when thao_tac = 'DELETE' then 1 end), count(case when thao_tac = 'INSERT' then 1 end)
    into v_xoa, v_them
    from hrm_owner.vw_nhat_ky
   where doi_tuong = 'PHIEU_LUONG' and khoa_ban_ghi like v_ky || '/%' and ten_dang_nhap = 'nv012';
  dat('TC-52 PHIEU_LUONG ky 03: ' || v_phieu || ' phieu; audit DELETE ' || v_xoa || ', INSERT ' || v_them
      || ' (demo + tinh lai)', v_xoa = v_phieu and v_them = 2 * v_phieu);

  select nhan_vien_id into v_nv from hrm_owner.vw_ho_so_nhan_vien where ma_nhan_vien = 'NV_C';
  select max(json_value(gia_tri_cu, '$.TONG_GROSS' returning number)) into v_cu
    from hrm_owner.vw_nhat_ky
   where doi_tuong = 'PHIEU_LUONG' and khoa_ban_ghi = v_ky || '/' || v_nv and thao_tac = 'DELETE';
  select json_value(gia_tri_moi, '$.TONG_GROSS' returning number) into v_moi
    from hrm_owner.vw_nhat_ky
   where doi_tuong = 'PHIEU_LUONG' and khoa_ban_ghi = v_ky || '/' || v_nv and thao_tac = 'INSERT'
   order by nhat_ky_id desc fetch first 1 row only;
  dat('TC-52 Phieu NV_C ky 03: gross ' || v_cu || ' -> ' || v_moi || ' (tang ' || (v_moi - v_cu) || ')',
      v_moi - v_cu = 2000000);

  -- Payroll khong thay audit ho so/han muc/tai khoan
  select count(*) into v_n from hrm_owner.vw_nhat_ky
   where doi_tuong in ('NHAN_VIEN', 'HAN_MUC_PHEP_NAM', 'TAI_KHOAN');
  dat('TC-52 U_PAY01 khong thay audit ho so/han muc/tai khoan (' || v_n || ' dong)', v_n = 0);

  thu_xoa('U_PAY01 DELETE bang nhat ky', 'delete from hrm_owner.nhat_ky_he_thong where doi_tuong = ''PHIEU_LUONG''');
  thu_xoa('U_PAY01 DELETE qua VW-10',    'delete from hrm_owner.vw_nhat_ky where doi_tuong = ''PHIEU_LUONG''');
  thu_xoa('U_PAY01 UPDATE qua VW-10',    'update hrm_owner.vw_nhat_ky set gia_tri_moi = null');
end;
/
