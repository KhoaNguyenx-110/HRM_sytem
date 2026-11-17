-- =============================================================================
-- TC-52 buoc 7 (HRM_OWNER): lop bao ve thu hai va do phu 100% (NFR-11, NFR-15)
--   - Ke ca owner cung khong UPDATE/DELETE duoc nhat ky (trigger -20021).
--   - Moi dong audit do phien user nghiep vu (U_*) ghi deu gan tai khoan (nguoi).
-- =============================================================================
set feedback off
set linesize 250
declare
  v_truoc number;
  v_sau   number;
  v_n     number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
begin
  select count(*) into v_truoc from nhat_ky_he_thong;
  begin
    delete from nhat_ky_he_thong where rownum = 1;
    dat('TC-52 Owner DELETE nhat ky -> khong bi chan', false);
  exception when others then
    dat('TC-52 Owner DELETE nhat ky bi tu choi (' || sqlcode || ')', sqlcode = -20021);
  end;
  begin
    update nhat_ky_he_thong set khoa_ban_ghi = 'X' where rownum = 1;
    dat('TC-52 Owner UPDATE nhat ky -> khong bi chan', false);
  exception when others then
    dat('TC-52 Owner UPDATE nhat ky bi tu choi (' || sqlcode || ')', sqlcode = -20021);
  end;
  rollback;
  select count(*) into v_sau from nhat_ky_he_thong;
  dat('TC-52 So dong nhat ky khong doi: ' || v_truoc || ' -> ' || v_sau, v_truoc = v_sau);

  select count(*), count(case when tai_khoan_id is null or thoi_diem is null then 1 end)
    into v_sau, v_n
    from nhat_ky_he_thong where oracle_username like 'U\_%' escape '\';
  dat('TC-52 ' || v_sau || ' dong audit do user nghiep vu ghi, ' || v_n || ' dong thieu nguoi/thoi diem',
      v_sau > 0 and v_n = 0);

  -- Thong ke theo doi tuong (bang chung cho bien ban)
  for r in (select doi_tuong, thao_tac, count(*) as so from nhat_ky_he_thong
             where oracle_username like 'U\_%' escape '\'
             group by doi_tuong, thao_tac order by 1, 2) loop
    dbms_output.put_line('TK    ' || rpad(r.doi_tuong, 20) || rpad(r.thao_tac, 7) || r.so);
  end loop;
end;
/
