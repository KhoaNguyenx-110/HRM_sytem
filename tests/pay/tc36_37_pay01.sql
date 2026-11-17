-- =============================================================================
-- TC-36, TC-37, TC-33b, TC-34a: tinh ky 01/2026 - chay bang U_PAY01, COMMIT
--   TC-36: vi du muc 9.8 cho NV_A tung buoc; net 35.635.200; BH NSDLD khong tru
--          net; FN-01 tai 0, 10, 30, 60, 100 trieu va moc cong 1 dong; FN-05
--          san/tran (NV001 vuot tran); FN-04 OT
--   TC-37: nhan vien khong di lam ngay le 01/01 van du luong (NV_B)
--   TC-33b: phu cap het hieu luc chi vao phieu thang con hieu luc (xem TC-41)
--   TC-34a: phat sinh chua duyet khong vao phieu
-- =============================================================================
set feedback off
declare
  v_so    number;
  v_loi   clob;
  v_cs    number;
  v_ky    hrm_owner.ky_luong%rowtype;
  p       hrm_owner.vw_bang_luong_tong_hop%rowtype;
  v_n     number;
  v_tien  number;
  procedure dat(p_ten varchar2, p_dk boolean) is
  begin
    dbms_output.put_line(case when p_dk then 'PASS  ' else 'FAIL  ' end || p_ten);
  end;
  procedure so(p_ten varchar2, p_thuc_te number, p_mong_doi number) is
  begin
    dat(rpad(p_ten, 44) || lpad(to_char(p_thuc_te, 'FM999G999G999G990'), 14)
        || '   mong doi ' || to_char(p_mong_doi, 'FM999G999G999G990'), p_thuc_te = p_mong_doi);
  end;
  -- Thanh tien mot khoan tren phieu (tong cac dong cung ma)
  function khoan(p_ma_nv varchar2, p_ma_khoan varchar2) return number is
    v number;
  begin
    select nvl(sum(thanh_tien), 0) into v from hrm_owner.vw_phieu_luong_ca_nhan
     where nam = 2026 and thang = 1 and ma_nhan_vien = p_ma_nv and ma_khoan = p_ma_khoan;
    return v;
  end;
begin
  hrm_owner.pkg_payroll.sp_tinh_luong_ky(1, 2026, v_so, v_loi);
  dat('TC-36 Tinh ky 01/2026: ' || v_so || ' loi' || case when v_so > 0 then chr(10) || v_loi end, v_so = 0);

  select * into v_ky from hrm_owner.ky_luong where nam = 2026 and thang = 1;
  dat('TC-36 Ky 01/2026 -> DA_TINH, phien ban da tinh = dau vao (' || v_ky.phien_ban_da_tinh || ')',
      v_ky.trang_thai = 'DA_TINH' and v_ky.phien_ban_da_tinh = v_ky.phien_ban_dau_vao);
  select count(*) into v_n from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1;
  dat('TC-36 So phieu ky 01/2026: ' || v_n || ' (50 nguoi lam viec trong thang)', v_n = 50);
  dat('QR-23 Phieu lech chi tiet: ' || hrm_owner.pkg_payroll.so_phieu_lech(v_ky.ky_luong_id),
      hrm_owner.pkg_payroll.so_phieu_lech(v_ky.ky_luong_id) = 0);

  -- Vi du muc 9.8, tung buoc
  select * into p from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1 and ma_nhan_vien = 'NV_A';
  dbms_output.put_line('--- Vi du muc 9.8 - NV_A ky 01/2026 (Hh = ' || p.gio_huong_luong || ')');
  so('TC-36 1 Luong theo cong',          khoan('NV_A', 'LUONG_CONG'), 26400000);
  so('TC-36 2 OT (4 x 150.000 x 1,5)',   khoan('NV_A', 'OT'),           900000);
  so('TC-36 3 Gross',                    p.tong_gross,                39300000);
  so('TC-36 4 Bao hiem NLD',             p.bao_hiem_nld,               2772000);
  so('TC-36 5 TNCT (OT mien thue)',      p.thu_nhap_chiu_thue,        38400000);
  so('TC-36 6 TNTT',                     p.thu_nhap_tinh_thue,        13928000);
  so('TC-36 7 Thue TNCN',                p.thue_tncn,                   892800);
  so('TC-36 8 NET (dap an)',             p.tong_net,                  35635200);
  so('TC-36 9 Bao hiem NSDLD',           p.bao_hiem_nsdld,             5676000);
  so('TC-36 10 Chi phi mo hinh',         p.chi_phi_doanh_nghiep,      44976000);
  dat('BR-27 Net = gross - BH NLD - thue - khau tru (BH NSDLD khong tru)',
      p.tong_net = p.tong_gross - p.bao_hiem_nld - p.thue_tncn - p.khau_tru_khac);

  -- FN-01 tai cac moc (muc 9.7) - bac doc tu bang
  select chinh_sach_id into v_cs from hrm_owner.chinh_sach_luong where tu_ngay = date '2026-01-01';
  dbms_output.put_line('--- FN-01 thue tai cac moc');
  so('FN-01 TNTT 0',               hrm_owner.fn_tinh_thue_tncn(0, v_cs),                   0);
  so('FN-01 TNTT 10.000.000',      hrm_owner.fn_tinh_thue_tncn(10000000, v_cs),       500000);
  so('FN-01 TNTT 10.000.001',      hrm_owner.fn_tinh_thue_tncn(10000001, v_cs),       500000);
  so('FN-01 TNTT 30.000.000',      hrm_owner.fn_tinh_thue_tncn(30000000, v_cs),      2500000);
  so('FN-01 TNTT 30.000.001',      hrm_owner.fn_tinh_thue_tncn(30000001, v_cs),      2500000);
  so('FN-01 TNTT 60.000.000',      hrm_owner.fn_tinh_thue_tncn(60000000, v_cs),      8500000);
  so('FN-01 TNTT 60.000.001',      hrm_owner.fn_tinh_thue_tncn(60000001, v_cs),      8500000);
  so('FN-01 TNTT 100.000.000',     hrm_owner.fn_tinh_thue_tncn(100000000, v_cs),    20500000);
  so('FN-01 TNTT 100.000.001',     hrm_owner.fn_tinh_thue_tncn(100000001, v_cs),    20500000);
  so('FN-01 TNTT 100.000.010 (35%)', hrm_owner.fn_tinh_thue_tncn(100000010, v_cs),  20500004);
  so('FN-01 TNTT am -> 0',         hrm_owner.fn_tinh_thue_tncn(-5, v_cs),                  0);

  -- FN-04, FN-05
  dbms_output.put_line('--- FN-04, FN-05');
  so('FN-04 OT 4 gio ngay thuong don gia 150.000',  hrm_owner.fn_tinh_ot(4, 150000, 'LAM_VIEC', v_cs), 900000);
  so('FN-04 OT 2 gio ngay le (he so 3)',            hrm_owner.fn_tinh_ot(2, 150000, 'LE', v_cs),       900000);
  so('FN-05 Can cu BHXH 65 trieu -> tran',          hrm_owner.fn_can_cu_bao_hiem(65000000, 'BHXH', v_cs), 46800000);
  so('FN-05 Can cu BHTN 65 trieu (duoi tran)',      hrm_owner.fn_can_cu_bao_hiem(65000000, 'BHTN', v_cs), 65000000);
  so('FN-05 Can cu 3 trieu -> san',                 hrm_owner.fn_can_cu_bao_hiem(3000000, 'BHYT', v_cs),   5310000);
  so('FN-05 NV001 BHXH NLD tren phieu (46,8tr x 8%)', khoan('NV001', 'BHXH_NLD'), 3744000);
  so('FN-05 NV001 BHTN NLD tren phieu (65tr x 1%)',   khoan('NV001', 'BHTN_NLD'),  650000);

  -- TC-37: NV_B khong co ban ghi cong ngay le 01/01 nhung Hh = Hc, luong = L
  dbms_output.put_line('--- TC-37, TC-34a, TC-33b');
  select * into p from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1 and ma_nhan_vien = 'NV_B';
  so('TC-37 NV_B gio huong luong thang co ngay le', p.gio_huong_luong, 176);
  so('TC-37 NV_B luong theo cong = luong hop dong', khoan('NV_B', 'LUONG_CONG'), p.luong_co_ban_ap_dung);

  -- TC-34a: thuong 1.500.000 CHO_DUYET khong vao phieu
  so('TC-34 Phat sinh chua duyet khong vao phieu NV_B', khoan('NV_B', 'THUONG'), 0);
  -- TC-33b: phu cap trach nhiem 01/2026 co tren phieu thang 01
  so('TC-33 Phu cap con hieu luc vao phieu 01/2026', khoan('NV_B', 'PC_TRACH_NHIEM'), 2000000);

  -- Phieu NV049 vao lam 15/01: luong theo gio hop le (96/176)
  select * into p from hrm_owner.vw_bang_luong_tong_hop where nam = 2026 and thang = 1 and ma_nhan_vien = 'NV049';
  so('NV049 vao giua thang: gio huong luong', p.gio_huong_luong, 96);
  so('NV049 luong theo cong = round(L x 96/176)', khoan('NV049', 'LUONG_CONG'),
     round(p.luong_co_ban_ap_dung * 96 / 176));
  commit;
end;
/
