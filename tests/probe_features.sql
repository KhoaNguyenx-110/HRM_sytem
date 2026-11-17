-- =============================================================================
-- probe_features.sql
-- Kiem tra cac tinh nang Oracle 23 ma tu dien du lieu dua vao, truoc khi viet DDL.
-- Chay bang HRM_OWNER. Tu don dep doi tuong thu khi ket thuc.
-- Moi ca in PASS/FAIL.
-- =============================================================================
set serveroutput on size unlimited
set feedback off

declare
  procedure ok(p_name varchar2) is begin dbms_output.put_line('PASS  ' || p_name); end;
  procedure ko(p_name varchar2, p_err varchar2) is
  begin dbms_output.put_line('FAIL  ' || p_name || ' -> ' || p_err); end;

  procedure ddl(p_sql varchar2) is begin execute immediate p_sql; end;

  procedure drop_if_exists(p_type varchar2, p_name varchar2) is
  begin
    execute immediate 'drop ' || p_type || ' ' || p_name ||
      case when p_type = 'table' then ' cascade constraints purge' end;
  exception when others then null;
  end;

  -- Chay mot cau DML mong doi bi tu choi voi ma loi cho truoc
  procedure expect_error(p_name varchar2, p_sql varchar2, p_code number) is
  begin
    execute immediate p_sql;
    ko(p_name, 'khong bi tu choi');
    rollback;
  exception when others then
    if sqlcode = p_code then ok(p_name || ' (ORA' || p_code || ')');
    else ko(p_name, sqlerrm); end if;
    rollback;
  end;
begin
  drop_if_exists('table', 'probe_ct');
  drop_if_exists('table', 'probe_ot');
  drop_if_exists('table', 'probe_lich');
  drop_if_exists('domain', 'd_probe_tien');

  -- 1. SQL Domain
  begin
    ddl('create domain d_probe_tien as number(18,2) '
     || 'constraint ck_d_probe_tien check (d_probe_tien >= 0)');
    ok('CREATE DOMAIN');
  exception when others then ko('CREATE DOMAIN', sqlerrm);
  end;

  -- 2. Bang cha cho FK tren cot ao
  ddl('create table probe_lich (ngay date primary key)');
  ddl('insert into probe_lich values (date ''2026-01-05'')');

  -- 3. BOOLEAN, IDENTITY, cot ao, FK tren cot ao, domain, JSON, DEFAULT SYS_CONTEXT
  begin
    ddl('create table probe_ot ('
     || ' id number generated always as identity primary key,'
     || ' bat_dau timestamp(0) not null,'
     || ' ket_thuc timestamp(0) not null,'
     || ' da_huy boolean default false not null,'
     || ' tien d_probe_tien,'
     || ' gia_tri json,'
     || ' nguoi varchar2(128) default sys_context(''USERENV'',''SESSION_USER'') not null,'
     || ' ngay date generated always as (trunc(cast(bat_dau as date))) virtual,'
     || ' constraint fk_probe_ot_ngay foreign key (ngay) references probe_lich (ngay),'
     || ' constraint ck_probe_ot_ban_ngay check ('
     || '   cast(bat_dau as date) >= ngay + 6/24 and cast(ket_thuc as date) <= ngay + 22/24))');
    ok('BOOLEAN + cot ao + FK tren cot ao + CHECK tham chieu cot ao + JSON + DEFAULT SYS_CONTEXT');
  exception when others then ko('Tao bang probe_ot', sqlerrm);
  end;

  begin
    ddl('insert into probe_ot (bat_dau, ket_thuc, tien, gia_tri) values '
     || '(timestamp ''2026-01-05 18:00:00'', timestamp ''2026-01-05 20:00:00'', 100, json(''{"a":1}''))');
    ok('Ghi dong hop le (FK cot ao tim thay ngay trong lich)');
    rollback;
  exception when others then ko('Ghi dong hop le', sqlerrm); rollback;
  end;

  expect_error('FK tren cot ao chan ngay khong co trong lich',
    'insert into probe_ot (bat_dau, ket_thuc) values '
 || '(timestamp ''2026-01-06 18:00:00'', timestamp ''2026-01-06 20:00:00'')', -2291);

  expect_error('CHECK chan OT ban dem',
    'insert into probe_ot (bat_dau, ket_thuc) values '
 || '(timestamp ''2026-01-05 21:00:00'', timestamp ''2026-01-05 23:00:00'')', -2290);

  -- Loi vi pham CHECK cua domain co ma rieng, nen chi kiem tra la bi tu choi
  begin
    execute immediate 'insert into probe_ot (bat_dau, ket_thuc, tien) values '
      || '(timestamp ''2026-01-05 18:00:00'', timestamp ''2026-01-05 20:00:00'', -1)';
    ko('Domain chan tien am', 'khong bi tu choi'); rollback;
  exception when others then ok('Domain chan tien am (' || substr(sqlerrm, 1, 9) || ')'); rollback;
  end;

  -- 4. Unique index ham kieu IX-14
  ddl('create table probe_ct (don number, nv number, ngay date, buoi varchar2(5), con number(1))');
  begin
    ddl('create unique index ix_probe_ct on probe_ct ('
     || ' case when con = 1 then nv end,'
     || ' case when con = 1 then ngay end,'
     || ' case when con = 1 then buoi end)');
    ok('Tao unique index ham IX-14');
  exception when others then ko('Tao unique index ham IX-14', sqlerrm);
  end;
  ddl('insert into probe_ct values (1, 7, date ''2026-01-05'', ''SANG'', 1)');
  ddl('insert into probe_ct values (2, 7, date ''2026-01-05'', ''SANG'', 0)');
  ok('Buoi trung nhung het hieu luc duoc ghi');
  expect_error('IX-14 chan hai don hieu luc cung buoi',
    'insert into probe_ct values (3, 7, date ''2026-01-05'', ''SANG'', 1)', -1);
  rollback;

  -- 5. FK ghep (ID, NHAN_VIEN_ID) toi UK tren bang cha
  begin
    ddl('alter table probe_ot add constraint uk_probe_ot_id_nguoi unique (id, nguoi)');
    ok('UK (ID, cot khac) chong len PK de lam dich FK ghep');
  exception when others then ko('UK chong len PK', sqlerrm);
  end;

  -- Don dep
  drop_if_exists('table', 'probe_ct');
  drop_if_exists('table', 'probe_ot');
  drop_if_exists('table', 'probe_lich');
  drop_if_exists('domain', 'd_probe_tien');
  dbms_output.put_line('Da don dep doi tuong thu');
end;
/
