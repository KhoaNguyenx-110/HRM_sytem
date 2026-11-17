-- =============================================================================
-- check_vd98.sql - Doi chieu du lieu seed voi vi du chuan muc 9.8 (dap an TC-36)
-- Tinh bang SQL thuan tu bang chinh sach va du lieu NV_A ky 01/2026.
-- Day KHONG phai FN-01..FN-05 (viet o giai doan 4); muc dich: chung minh so lieu
-- chinh sach va du lieu demo da du va dung de procedure tinh ra 35.635.200.
-- Thuong 12 trieu lay tu KHEN_THUONG da duyet (se chuyen bang SP-10).
-- =============================================================================
set serveroutput on size unlimited
set feedback off
set linesize 200

declare
  c_tu   constant date := date '2026-01-01';
  c_den  constant date := date '2026-01-31';
  v_cs   number;  v_nv number;
  v_l    number;  v_cc_bh number;
  v_hc   number;  v_hh number;
  v_ot_gio number; v_he_so number; v_thuong number;
  v_luong_cong number; v_ot number; v_gross number;
  v_bh number; v_tnct number; v_npt number; v_giam_tru number; v_tntt number;
  v_thue number; v_net number; v_bh_dn number;

  procedure dong(p_ten varchar2, p_gia_tri number, p_mong_doi number) is
  begin
    dbms_output.put_line(
      case when p_gia_tri = p_mong_doi then 'PASS  ' else 'FAIL  ' end
      || rpad(p_ten, 34) || lpad(to_char(p_gia_tri, 'FM999G999G999'), 14)
      || '   mong doi ' || to_char(p_mong_doi, 'FM999G999G999'));
  end;
begin
  select chinh_sach_id into v_cs from chinh_sach_luong
   where c_tu between tu_ngay and nvl(den_ngay, date '9999-12-31');
  select nhan_vien_id into v_nv from nhan_vien where ma_nhan_vien = 'NV_A';

  select m.luong_co_ban, m.can_cu_dong_bao_hiem into v_l, v_cc_bh
    from muc_luong_hop_dong m join hop_dong h on h.hop_dong_id = m.hop_dong_id
   where h.nhan_vien_id = v_nv and c_tu between m.tu_ngay and nvl(m.den_ngay, date '9999-12-31');

  -- Hc: tong gio quy doi chuan cua thang; Hh: gio lam + gio le quy doi (khong nghi)
  select sum(gio_quy_doi_luong) into v_hc from lich_lam_viec where ngay between c_tu and c_den;
  select sum(so_gio_lam_thuc_te) into v_hh from cham_cong
   where nhan_vien_id = v_nv and ngay between c_tu and c_den;
  select v_hh + nvl(sum(gio_quy_doi_luong), 0) into v_hh from lich_lam_viec
   where loai_ngay = 'LE' and ngay between c_tu and c_den;

  select sum(o.so_gio_duoc_duyet), max(h.he_so) into v_ot_gio, v_he_so
    from dang_ky_tang_ca o
    join lich_lam_viec l on l.ngay = o.ngay
    join he_so_ot h on h.chinh_sach_id = v_cs and h.loai_ngay = l.loai_ngay
   where o.nhan_vien_id = v_nv and o.trang_thai = 'DA_DUYET' and o.ngay between c_tu and c_den;

  select nvl(sum(so_tien), 0) into v_thuong from khen_thuong
   where nhan_vien_id = v_nv and hinh_thuc = 'TIEN' and trang_thai_duyet = 'DA_DUYET'
     and ngay_quyet_dinh between c_tu and c_den;

  v_luong_cong := round(v_l * v_hh / v_hc, 0);
  v_ot         := round(v_ot_gio * (v_l / v_hc) * v_he_so, 0);   -- OT mien thue (MIEN_TOAN_BO)
  v_gross      := v_luong_cong + v_thuong + v_ot;

  -- Bao hiem NLD: tung loai lam tron rieng, can cu sau san/tran
  select sum(round(least(greatest(v_cc_bh, nvl(san_dong, 0)), nvl(tran_dong, v_cc_bh)) * ty_le_nld, 0)),
         sum(round(least(greatest(v_cc_bh, nvl(san_dong, 0)), nvl(tran_dong, v_cc_bh)) * ty_le_nsdld, 0))
    into v_bh, v_bh_dn
    from ty_le_bao_hiem where chinh_sach_id = v_cs;

  v_tnct := v_gross - v_ot;
  select count(*) into v_npt from nguoi_phu_thuoc
   where nhan_vien_id = v_nv and trang_thai_xac_minh = 'DA_XAC_MINH'
     and tu_ngay <= c_den and nvl(den_ngay, date '9999-12-31') >= c_tu;
  select giam_tru_ban_than + v_npt * giam_tru_nguoi_phu_thuoc into v_giam_tru
    from chinh_sach_luong where chinh_sach_id = v_cs;
  v_tntt := greatest(v_tnct - v_bh - v_giam_tru, 0);

  -- Thue luy tien: doc bac tu bang, khong gia dinh so bac
  select round(sum(greatest(least(v_tntt, nvl(can_tren, v_tntt)) - can_duoi, 0) * thue_suat), 0)
    into v_thue from bac_thue_tncn where chinh_sach_id = v_cs;

  v_net := v_gross - v_bh - v_thue;

  dbms_output.put_line('Vi du muc 9.8 - NV_A, ky 01/2026 (Hc = ' || v_hc || ', Hh = ' || v_hh || ')');
  dong('1 Luong theo cong',        v_luong_cong, 26400000);
  dong('2 OT',                     v_ot,           900000);
  dong('3 Gross',                  v_gross,      39300000);
  dong('4 Bao hiem NLD',           v_bh,          2772000);
  dong('5 Thu nhap chiu thue',     v_tnct,       38400000);
  dong('6 Thu nhap tinh thue',     v_tntt,       13928000);
  dong('7 Thue TNCN',              v_thue,         892800);
  dong('8 NET (dap an TC-36)',     v_net,        35635200);
  dong('9 Bao hiem NSDLD',         v_bh_dn,       5676000);
  dong('10 Chi phi mo hinh',       v_gross + v_bh_dn, 44976000);
end;
/
