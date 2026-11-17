-- =============================================================================
-- QR-24 Truy vet sua luong: ai, luc nao, doi tuong nao, gia tri truoc/sau
--   Actor: Payroll (U_PAY01)   Nguon: VW-10 vw_nhat_ky (phan luong: PHAT_SINH_LUONG,
--                              KY_LUONG, MUC_LUONG_HOP_DONG) - ghi boi TR-01
--   Dau vao: :p_tu, :p_den (YYYY-MM-DD), :p_doi_tuong (NULL = tat ca)
--   Ky thuat: JSON_VALUE tren cot JSON gia tri cu/moi, ORDER BY thoi diem
-- Chay: scripts/run.sh U_PAY01 queries/qr24_truy_vet_sua_luong.sql
-- =============================================================================
@@_dinh_dang.sql
column thoi_diem     format a19
column ten_dang_nhap format a10
column doi_tuong     format a18
column khoa_ban_ghi  format a6
column thao_tac      format a6
column truong        format a18
column truoc         format a14
column sau           format a14
variable p_tu        varchar2(10)
variable p_den       varchar2(10)
variable p_doi_tuong varchar2(30)
exec :p_tu := '2026-01-01'; :p_den := '2027-12-31'; :p_doi_tuong := null
set feedback on

-- Moi dong audit tach thanh cac truong nghiep vu quan trong bang JSON_VALUE;
-- chi hien truong co thay doi (hoac them/xoa).
with nk as (
  select nhat_ky_id, thoi_diem, ten_dang_nhap, doi_tuong, khoa_ban_ghi, thao_tac, gia_tri_cu, gia_tri_moi
    from hrm_owner.vw_nhat_ky
   where thoi_diem >= to_timestamp(:p_tu, 'YYYY-MM-DD')
     and thoi_diem <  to_timestamp(:p_den, 'YYYY-MM-DD') + interval '1' day
     and (:p_doi_tuong is null or doi_tuong = upper(:p_doi_tuong))
     and doi_tuong in ('PHAT_SINH_LUONG', 'KY_LUONG', 'MUC_LUONG_HOP_DONG')
     -- bo dong do cai dat du lieu mau (khong co tai khoan phien)
     and ten_dang_nhap is not null
),
truong as (
  select nk.*, t.truong,
         case t.truong
           when 'TRANG_THAI'        then json_value(gia_tri_cu, '$.TRANG_THAI')
           when 'PHIEN_BAN_DAU_VAO' then json_value(gia_tri_cu, '$.PHIEN_BAN_DAU_VAO')
           when 'SO_TIEN'           then json_value(gia_tri_cu, '$.SO_TIEN')
           when 'TRANG_THAI_DUYET'  then json_value(gia_tri_cu, '$.TRANG_THAI_DUYET')
           when 'LUONG_CO_BAN'      then json_value(gia_tri_cu, '$.LUONG_CO_BAN')
         end as truoc,
         case t.truong
           when 'TRANG_THAI'        then json_value(gia_tri_moi, '$.TRANG_THAI')
           when 'PHIEN_BAN_DAU_VAO' then json_value(gia_tri_moi, '$.PHIEN_BAN_DAU_VAO')
           when 'SO_TIEN'           then json_value(gia_tri_moi, '$.SO_TIEN')
           when 'TRANG_THAI_DUYET'  then json_value(gia_tri_moi, '$.TRANG_THAI_DUYET')
           when 'LUONG_CO_BAN'      then json_value(gia_tri_moi, '$.LUONG_CO_BAN')
         end as sau
    from nk
    join (select 'KY_LUONG' as dt, 'TRANG_THAI' as truong from dual
          union all select 'KY_LUONG', 'PHIEN_BAN_DAU_VAO' from dual
          union all select 'PHAT_SINH_LUONG', 'SO_TIEN' from dual
          union all select 'PHAT_SINH_LUONG', 'TRANG_THAI_DUYET' from dual
          union all select 'MUC_LUONG_HOP_DONG', 'LUONG_CO_BAN' from dual) t
      on t.dt = nk.doi_tuong
)
select to_char(thoi_diem, 'DD/MM/YYYY HH24:MI:SS') as thoi_diem, ten_dang_nhap, doi_tuong,
       khoa_ban_ghi, thao_tac, truong, truoc, sau
  from truong
 where decode(truoc, sau, 0, 1) = 1
 order by nhat_ky_id, truong;
