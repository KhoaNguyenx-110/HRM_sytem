-- =============================================================================
-- 01_fn_ctx.sql - FN-06: doc danh tinh phien tu HRM_CTX (dac ta muc 7.2, 8.1)
-- Day la nguon danh tinh DUY NHAT cho view va procedure (BR-37).
-- Tra NULL / FALSE khi chua co phien (tai khoan KHOA, user khong anh xa).
-- =============================================================================

create or replace function fn_tai_khoan_hien_tai return number
  authid definer
is
begin
  return to_number(sys_context('HRM_CTX', 'TAI_KHOAN_ID'));
end;
/
show errors

create or replace function fn_nhan_vien_hien_tai return number
  authid definer
is
begin
  return to_number(sys_context('HRM_CTX', 'NHAN_VIEN_ID'));
end;
/
show errors

-- VAI_TRO trong context co dang ',EMPLOYEE,HR,MANAGER,' nen tim ',HR,' khong nham voi ',HRX,'
create or replace function fn_co_vai_tro(p_ma_vai_tro varchar2) return boolean
  authid definer
is
begin
  return nvl(instr(sys_context('HRM_CTX', 'VAI_TRO'), ',' || upper(p_ma_vai_tro) || ','), 0) > 0;
end;
/
show errors
