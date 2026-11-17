-- =============================================================================
-- check_seed.sql - Kiem tra du lieu mau sau seed.sql
-- In so dong tung bang va cac phep kiem tra nghiep vu (PASS/FAIL).
-- =============================================================================
set serveroutput on size unlimited
set feedback off
set linesize 200

declare
  v number;

  procedure kiem_tra(p_ten varchar2, p_thuc_te number, p_mong_doi number) is
  begin
    dbms_output.put_line(
      case when p_thuc_te = p_mong_doi then 'PASS  ' else 'FAIL  ' end ||
      rpad(p_ten, 58) || ' thuc te = ' || p_thuc_te || ', mong doi = ' || p_mong_doi);
  end;
begin
  -- --------------------------------------------------------------------------
  -- So dong tung bang
  -- --------------------------------------------------------------------------
  dbms_output.put_line('--- So dong tung bang');
  for r in (select table_name from user_tables where table_name not like 'BIN$%' order by table_name) loop
    execute immediate 'select count(*) from ' || r.table_name into v;
    dbms_output.put_line('      ' || rpad(r.table_name, 24) || lpad(v, 6));
  end loop;

  dbms_output.put_line('--- Kiem tra nghiep vu');

  -- Quy mo theo muc 12.3
  select count(*) into v from nhan_vien;
  kiem_tra('50 nhan vien', v, 50);
  select count(distinct q.phong_ban_id) into v from qua_trinh_cong_tac q;
  kiem_tra('5 phong co nhan su', v, 5);
  select count(*) into v from tai_khoan where oracle_username is not null;
  kiem_tra('11 tai khoan anh xa user demo (muc 12.2)', v, 11);
  select count(*) into v from tai_khoan t
   where t.nhan_vien_id is not null
     and not exists (select 1 from tai_khoan_vai_tro tv join vai_tro r on r.vai_tro_id = tv.vai_tro_id
                      where tv.tai_khoan_id = t.tai_khoan_id and r.ma_vai_tro = 'EMPLOYEE');
  kiem_tra('Tai khoan nhan vien thieu vai tro EMPLOYEE', v, 0);

  -- Lich: gio quy doi chuan thang 01/2026 = 176 (vi du muc 9.8)
  select sum(gio_quy_doi_luong) into v from lich_lam_viec
   where ngay between date '2026-01-01' and date '2026-01-31';
  kiem_tra('Hc thang 01/2026 (gio quy doi chuan)', v, 176);
  select count(*) into v from lich_lam_viec where extract(year from ngay) = 2026;
  kiem_tra('Lich du 365 ngay nam 2026', v, 365);

  -- NV_A khop vi du 9.8: 168 gio lam + 8 gio le quy doi = 176
  select sum(c.so_gio_lam_thuc_te) into v
    from cham_cong c join nhan_vien n on n.nhan_vien_id = c.nhan_vien_id
   where n.ma_nhan_vien = 'NV_A' and c.ngay between date '2026-01-01' and date '2026-01-31';
  kiem_tra('NV_A gio lam thuc te thang 01/2026', v, 168);
  select sum(m.luong_co_ban) into v
    from muc_luong_hop_dong m join hop_dong h on h.hop_dong_id = m.hop_dong_id
    join nhan_vien n on n.nhan_vien_id = h.nhan_vien_id
   where n.ma_nhan_vien = 'NV_A';
  kiem_tra('NV_A luong 26.400.000', v, 26400000);
  select sum(o.so_gio_duoc_duyet) into v
    from dang_ky_tang_ca o join nhan_vien n on n.nhan_vien_id = o.nhan_vien_id
   where n.ma_nhan_vien = 'NV_A' and o.trang_thai = 'DA_DUYET' and o.ngay < date '2026-02-01';
  kiem_tra('NV_A OT da duyet thang 01/2026 (gio)', v, 4);
  select count(*) into v
    from nguoi_phu_thuoc p join nhan_vien n on n.nhan_vien_id = p.nhan_vien_id
   where n.ma_nhan_vien = 'NV_A' and p.trang_thai_xac_minh = 'DA_XAC_MINH';
  kiem_tra('NV_A 1 nguoi phu thuoc da xac minh', v, 1);

  -- BR-11 / BR-12: gio cong + gio nghi da duyet khong vuot chuan ngay
  select count(*) into v
    from cham_cong c
    join lich_lam_viec l on l.ngay = c.ngay
    left join (select ct.nhan_vien_id, ct.ngay, count(*) * 4 as gio_nghi
                 from chi_tiet_nghi_phep ct join don_nghi_phep d on d.don_nghi_id = ct.don_nghi_id
                where d.trang_thai = 'DA_DUYET' group by ct.nhan_vien_id, ct.ngay) np
      on np.nhan_vien_id = c.nhan_vien_id and np.ngay = c.ngay
   where c.so_gio_lam_thuc_te + nvl(np.gio_nghi, 0) > l.so_gio_chuan;
  kiem_tra('BR-12 cong + nghi vuot chuan ngay', v, 0);

  -- BR-09: khong co cong ngoai thoi gian lam viec
  select count(*) into v
    from cham_cong c join nhan_vien n on n.nhan_vien_id = c.nhan_vien_id
   where c.ngay < n.ngay_vao_lam or c.ngay > n.ngay_nghi_viec;
  kiem_tra('BR-09 cong ngoai thoi gian lam viec', v, 0);

  -- Ngay lam viec nao cung du cong cho nguoi dang lam (dieu kien chot cong)
  select count(*) into v
    from nhan_vien n
    join lich_lam_viec l on l.loai_ngay = 'LAM_VIEC'
     and l.ngay between date '2026-01-01' and date '2026-03-31'
     and l.ngay >= n.ngay_vao_lam and (n.ngay_nghi_viec is null or l.ngay <= n.ngay_nghi_viec)
   where not exists (select 1 from cham_cong c where c.nhan_vien_id = n.nhan_vien_id and c.ngay = l.ngay);
  kiem_tra('Ngay lam viec thieu cong (01-03/2026)', v, 0);

  -- BR-06: dung 1 nguoi giu chuc vu quan ly moi phong tai 31/03/2026
  select count(*) into v from (
    select q.phong_ban_id
      from qua_trinh_cong_tac q join chuc_vu c on c.chuc_vu_id = q.chuc_vu_id
     where c.la_quan_ly
       and date '2026-03-31' between q.ngay_bat_dau and nvl(q.ngay_ket_thuc, date '9999-12-31')
     group by q.phong_ban_id having count(*) <> 1);
  kiem_tra('BR-06 phong khong co dung 1 truong phong', v, 0);

  -- BR-08: khong chong khoang phan cong
  select count(*) into v
    from qua_trinh_cong_tac a join qua_trinh_cong_tac b
      on a.nhan_vien_id = b.nhan_vien_id and a.cong_tac_id < b.cong_tac_id
     and a.ngay_bat_dau <= nvl(b.ngay_ket_thuc, date '9999-12-31')
     and b.ngay_bat_dau <= nvl(a.ngay_ket_thuc, date '9999-12-31');
  kiem_tra('BR-08 phan cong chong khoang', v, 0);

  -- Cot du thua CON_HIEU_LUC khop trang thai don (muc 9 tu dien du lieu)
  select count(*) into v
    from chi_tiet_nghi_phep c join don_nghi_phep d on d.don_nghi_id = c.don_nghi_id
   where c.con_hieu_luc <> case when d.trang_thai in ('CHO_DUYET', 'DA_DUYET') then 1 else 0 end;
  kiem_tra('CON_HIEU_LUC lech trang thai don', v, 0);

  -- Don nghi du 4 trang thai (TC-48)
  select count(distinct trang_thai) into v from don_nghi_phep;
  kiem_tra('Don nghi co du 4 trang thai', v, 4);

  -- Truong hop bien
  select count(*) into v from hop_dong
   where ngay_ket_thuc between date '2026-11-15' and date '2026-11-15' + 30 and not da_huy;
  kiem_tra('Hop dong het han trong 30 ngay tu 15/11/2026', v, 2);
  select count(*) into v from dang_ky_tang_ca o join lich_lam_viec l on l.ngay = o.ngay
   where l.loai_ngay = 'LE' and o.trang_thai = 'DA_DUYET';
  kiem_tra('OT ngay le da duyet', v, 1);
  select count(*) into v from nhan_vien where ngay_nghi_viec is not null;
  kiem_tra('Nhan vien nghi viec giua ky', v, 1);
  select count(*) into v from tai_khoan where trang_thai = 'KHOA';
  kiem_tra('Tai khoan KHOA (NV_KHOA, NV050)', v, 2);
end;
/
