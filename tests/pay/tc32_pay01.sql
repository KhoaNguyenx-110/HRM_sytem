-- =============================================================================
-- TC-32: chinh sach theo phien ban - chay bang U_PAY01 (sau khi ky 01 DA_KHOA)
--   Chong hieu luc; bac thue ho; sua chinh sach da dung o ky da khoa -> tu choi.
--   Them: thieu loai bao hiem, he so OT duoi muc luat, JSON sai -> tu choi;
--   dong phien ban 2026 roi tao phien ban 2027 hop le -> duoc. ROLLBACK cuoi.
-- =============================================================================
set feedback off
declare
  v_cs    number;
  v_moi   number;
  c_ot    constant varchar2(200) :=
    '[{"loai_ngay":"LAM_VIEC","he_so":1.5},{"loai_ngay":"NGHI_TUAN","he_so":2},{"loai_ngay":"LE","he_so":3}]';
  c_ot_thap constant varchar2(200) :=
    '[{"loai_ngay":"LAM_VIEC","he_so":1.5},{"loai_ngay":"NGHI_TUAN","he_so":2},{"loai_ngay":"LE","he_so":2.5}]';
  c_bh    constant varchar2(1000) :=
    '[{"loai":"BHXH","nld":0.08,"nsdld":0.17,"san":5310000,"tran":46800000,"can_cu":"TL-04"},'
 || '{"loai":"BHTNLD","nld":0,"nsdld":0.005,"san":5310000,"tran":46800000,"can_cu":"TL-04"},'
 || '{"loai":"BHYT","nld":0.015,"nsdld":0.03,"san":5310000,"tran":46800000,"can_cu":"TL-05"},'
 || '{"loai":"BHTN","nld":0.01,"nsdld":0.01,"san":5310000,"tran":106200000,"can_cu":"TL-06"}]';
  c_bh_thieu constant varchar2(1000) :=
    '[{"loai":"BHXH","nld":0.08,"nsdld":0.17,"san":5310000,"tran":46800000,"can_cu":"TL-04"}]';
  c_thue  constant varchar2(1000) :=
    '[{"bac":1,"can_duoi":0,"can_tren":10000000,"thue_suat":0.05},'
 || '{"bac":2,"can_duoi":10000000,"can_tren":30000000,"thue_suat":0.10},'
 || '{"bac":3,"can_duoi":30000000,"can_tren":60000000,"thue_suat":0.20},'
 || '{"bac":4,"can_duoi":60000000,"can_tren":100000000,"thue_suat":0.30},'
 || '{"bac":5,"can_duoi":100000000,"thue_suat":0.35}]';
  -- Bac 2 bat dau 12 trieu: ho 10-12 trieu
  c_thue_ho constant varchar2(1000) :=
    '[{"bac":1,"can_duoi":0,"can_tren":10000000,"thue_suat":0.05},'
 || '{"bac":2,"can_duoi":12000000,"thue_suat":0.10}]';
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure bi_chan(p_ten varchar2, p_ma number) is
  begin
    dat(p_ten || ' bi tu choi (' || sqlcode || '): ' || substr(sqlerrm, 12, 100), sqlcode = p_ma);
  end;
  procedure luu(p_tu date, p_den date, p_ot varchar2, p_bh varchar2, p_thue varchar2,
                p_id number default null) is
  begin
    hrm_owner.pkg_payroll.sp_luu_chinh_sach(p_tu, p_den, 15500000, 6200000, 4, 40, 200,
      'TC-32 kiểm thử', p_ot, p_bh, p_thue, p_id, v_moi);
  end;
begin
  select chinh_sach_id into v_cs from hrm_owner.chinh_sach_luong where tu_ngay = date '2026-01-01';

  begin
    luu(date '2026-06-01', null, c_ot, c_bh, c_thue);
    dat('TC-32 Chinh sach chong hieu luc -> khong bi chan', false);
  exception when others then bi_chan('TC-32 Chinh sach chong hieu luc', -20514);
  end;

  begin
    luu(date '2026-01-01', null, c_ot, c_bh, c_thue, v_cs);
    dat('TC-32 Sua chinh sach da dung o ky da khoa -> khong bi chan', false);
  exception when others then bi_chan('TC-32 Sua chinh sach da dung o ky 01 da khoa', -20509);
  end;

  -- Dong phien ban 2026 (ky 01 da khoa van nam trong khoang) de mo 2027
  hrm_owner.pkg_payroll.sp_ket_thuc_chinh_sach(v_cs, date '2026-12-31');
  dat('TC-32 Dong hieu luc phien ban 2026 den 31/12/2026', true);

  begin
    luu(date '2027-01-01', null, c_ot, c_bh, c_thue_ho);
    dat('TC-32 Bac thue ho -> khong bi chan', false);
  exception when others then bi_chan('TC-32 Bac thue ho', -20515);
  end;
  begin
    luu(date '2027-01-01', null, c_ot, c_bh_thieu, c_thue);
    dat('TC-32 Thieu loai bao hiem -> khong bi chan', false);
  exception when others then bi_chan('TC-32 Thieu loai bao hiem', -20516);
  end;
  begin
    luu(date '2027-01-01', null, c_ot_thap, c_bh, c_thue);
    dat('TC-32 He so OT le 2,5 -> khong bi chan', false);
  exception when others then bi_chan('TC-32 He so OT ngay le duoi muc luat', -20517);
  end;
  begin
    luu(date '2027-01-01', null, '[{"loai_ngay":"LE", he_so: }', c_bh, c_thue);
    dat('TC-32 JSON sai cu phap -> khong bi chan', false);
  exception when others then bi_chan('TC-32 JSON sai cu phap', -20528);
  end;
  begin
    luu(date '2027-01-15', null, c_ot, c_bh, c_thue);
    dat('TC-32 Hieu luc tu giua thang -> khong bi chan', false);
  exception when others then bi_chan('TC-32 Hieu luc tu giua thang', -20531);
  end;

  luu(date '2027-01-01', null, c_ot, c_bh, c_thue);
  dat('TC-32 Tao phien ban 2027 hop le (id ' || v_moi || ')', v_moi is not null);
  rollback;
end;
/
