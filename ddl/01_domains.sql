-- =============================================================================
-- 01_domains.sql - Mien du lieu (tu dien du lieu muc 1.1)
-- CHECK cua domain chi kiem tra gia tri khac NULL; NOT NULL khai bao o cot.
-- =============================================================================

create domain d_tien as number(18,2)
  constraint ck_d_tien check (d_tien >= 0);

create domain d_ty_le as number(7,6)
  constraint ck_d_ty_le check (d_ty_le between 0 and 1);

create domain d_gio as number(5,2)
  constraint ck_d_gio check (d_gio >= 0);

create domain d_ngay as date
  constraint ck_d_ngay check (d_ngay = trunc(d_ngay));

create domain d_ma as varchar2(20)
  constraint ck_d_ma check (regexp_like(d_ma, '^[A-Z0-9_]+$'));
