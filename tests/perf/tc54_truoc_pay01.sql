-- TC-54 (U_PAY01): do khi index nghiep vu dang INVISIBLE (chay sau tc54_an_index_owner.sql)
variable p_che_do varchar2(5)
exec :p_che_do := 'TRUOC'
@@tc54_do.sql
