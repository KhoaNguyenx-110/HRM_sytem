-- TC-54: than phan EXPLAIN PLAN cho QR-08, QR-17, QR-18, QR-21 (goi tu tc54_plan_owner.sql)
-- --------------------------------------------------------------------- PLAN
explain plan set statement_id = 'QR08' for
select ma_phong_ban, ma_nhan_vien, ho_ten, so_ngay_co_cong, gio_cong,
       ngay_nghi_huong_luong, ngay_nghi_khong_luong, gio_huong_luong,
       ot_ngay_thuong + ot_nghi_tuan + ot_le as gio_ot
  from hrm_owner.vw_cong_thang
 where nam = :p_nam and thang = :p_thang
   and (:p_phong is null or ma_phong_ban = :p_phong)
 order by ma_phong_ban, ma_nhan_vien;

explain plan set statement_id = 'QR17' for
select ma_khoan, ten_khoan, nhom_khoan_ap_dung, so_luong, don_gia, he_so, thanh_tien, phan_chiu_thue
  from hrm_owner.vw_phieu_luong_ca_nhan
 where ma_nhan_vien = upper(:p_ma) and nam = :p_nam and thang = :p_thang
 order by chi_tiet_id;

explain plan set statement_id = 'QR18' for
select case grouping(ten_phong_ban) when 1 then '== TONG CONG TY' else ten_phong_ban end as phong,
       count(*), sum(tong_gross), sum(bao_hiem_nld), sum(thue_tncn), sum(tong_net),
       sum(bao_hiem_nsdld), sum(chi_phi_doanh_nghiep)
  from hrm_owner.vw_bang_luong_tong_hop
 where nam = :p_nam and thang = :p_thang
 group by rollup (ten_phong_ban);

explain plan set statement_id = 'QR21' for
with thang as (
  select add_months(to_date(:p_tu_ky, 'YYYY-MM'), level - 1) as dau_thang
    from dual
 connect by level <= months_between(to_date(:p_den_ky, 'YYYY-MM'), to_date(:p_tu_ky, 'YYYY-MM')) + 1),
quy as (
  select to_date(nam || '-' || thang, 'YYYY-MM') as dau_thang, sum(tong_gross) as gross
    from hrm_owner.vw_bang_luong_tong_hop group by nam, thang)
select t.dau_thang, nvl(q.gross, 0), lag(nvl(q.gross, 0)) over (order by t.dau_thang)
  from thang t left join quy q on q.dau_thang = t.dau_thang;

select 'PLAN ' || :p_che_do || ' ' || s.id || ' | ' || t.plan_table_output
  from (select 'QR08' as id from dual union all select 'QR17' from dual
        union all select 'QR18' from dual union all select 'QR21' from dual) s,
       table(dbms_xplan.display('PLAN_TABLE', s.id, 'BASIC +ROWS +COST +PREDICATE')) t;

