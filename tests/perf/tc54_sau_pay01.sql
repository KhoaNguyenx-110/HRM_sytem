-- TC-54 (U_PAY01): do lai trong phien cho phep optimizer dung index INVISIBLE
-- (tuong duong "sau khi tao index"; khong phai xoa/tao lai index tren CSDL that)
alter session set optimizer_use_invisible_indexes = true;
variable p_che_do varchar2(5)
exec :p_che_do := 'SAU'
@@tc54_do.sql
