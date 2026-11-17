-- =============================================================================
-- 17_pkg_payroll_body.sql - pkg_payroll: PHAN BODY (spec o 06_pkg_payroll.sql)
--
-- Ma loi -205xx:
--   -20501 ky da khoa                      -20517 he so OT sai/thieu
--   -20502 ky dang duoc xu ly (WAIT 5)     -20518 phu cap chong cung loai
--   -20503 trang thai ky khong cho phep    -20519 loai khoan khong hop le
--   -20504 phien ban dau vao lech          -20520 ngoai thoi gian lam viec
--   -20505 thieu phieu khi khoa            -20521 phieu goc khong hop le
--   -20506 tong phieu lech chi tiet        -20522 so tien / can cu khong hop le
--   -20507 thuong da chuyen                -20523 phat sinh da xu ly
--   -20508 thuong khong chuyen duoc        -20524 tu duyet phat sinh
--   -20509 chinh sach da dung o ky khoa    -20525 lich thang chua du / Hc = 0
--   -20510 ky trung                        -20526 ky chua ton tai
--   -20511 thang/nam khong hop le          -20527 phu cap khong tron thang
--   -20512 ngay chi tra ngoai thang        -20528 JSON chinh sach sai cu phap
--   -20513 khong co chinh sach cho ky      -20529 khong tim thay phu cap de sua
--   -20514 chinh sach chong hieu luc       -20530 chinh sach khong ton tai
--   -20515 bieu thue sai/thieu             -20531 tham so khong hop le
--   -20516 bao hiem sai/thieu              -20532 thieu khoan luong he thong
--                                          -20533 net am (rang buoc CK_PHIEU_NET)
--
-- Thu tu khoa dong (muc 8.5): KY_LUONG (tang dan) -> NHAN_VIEN -> ban ghi.
-- Chinh sach dung them khoa nguoi dung DBMS_LOCK (chong hai phien cung tao
-- phien ban chong nhau, khi chua co dong nao de khoa).
-- =============================================================================

create or replace package body pkg_payroll
as
  c_xa constant date := pkg_chung.c_ngay_xa;

  -- Muc 9.5: nghi khong luong tu 14 ngay lam viec tro len trong thang la truong
  -- hop bao hiem CHUA MO HINH HOA -> bao loi, khong tu ap dung cach tinh thuong.
  -- 14 ngay x 8 gio chuan.
  c_gio_khong_luong_toi_da constant number := 14 * 8;

  -- He so OT toi thieu theo BLLD 2019 Dieu 98 (muc 9.3): chinh sach chi duoc cao hon
  c_ot_min_lam_viec  constant number := 1.5;
  c_ot_min_nghi_tuan constant number := 2.0;
  c_ot_min_le        constant number := 3.0;

  -- FOR UPDATE WAIT 5 het gio. Oracle 23ai bao ORA-00054; ban cu bao ORA-30006.
  e_ky_ban exception;
  pragma exception_init(e_ky_ban, -54);
  e_ky_ban_cu exception;
  pragma exception_init(e_ky_ban_cu, -30006);

  -- ===========================================================================
  -- Tien ich noi bo
  -- ===========================================================================
  function ngay_dau_thang(p_thang in number, p_nam in number) return date
  is
  begin
    if p_thang is null or p_nam is null or p_thang not between 1 and 12
       or p_nam not between 2000 and 2100 or p_thang <> trunc(p_thang) or p_nam <> trunc(p_nam) then
      raise_application_error(-20511, 'Kỳ ' || p_thang || '/' || p_nam
        || ' không hợp lệ: tháng 1–12, năm 2000–2100.');
    end if;
    return to_date(p_nam || '-' || p_thang || '-01', 'YYYY-MM-DD');
  end ngay_dau_thang;

  function ten_ky(p_thang in number, p_nam in number) return varchar2
  is
  begin
    return lpad(p_thang, 2, '0') || '/' || p_nam;
  end ten_ky;

  function id_nhan_vien(p_ma in varchar2) return number
  is
    v number;
  begin
    select nhan_vien_id into v from nhan_vien where ma_nhan_vien = upper(p_ma);
    return v;
  exception
    when no_data_found then
      raise_application_error(-20216, 'Nhân viên "' || p_ma || '" không tồn tại.');
  end id_nhan_vien;

  -- ID ky (khong khoa); chua co ky -> -20526
  function id_ky(p_thang in number, p_nam in number) return number
  is
    v number;
  begin
    select ky_luong_id into v from ky_luong where thang = p_thang and nam = p_nam;
    return v;
  exception
    when no_data_found then
      raise_application_error(-20526, 'Chưa có kỳ lương ' || ten_ky(p_thang, p_nam) || '.');
  end id_ky;

  -- Phien ban loai khoan co hieu luc tai p_ngay
  function khoan(p_ma in varchar2, p_ngay in date) return loai_khoan_luong%rowtype
  is
    v loai_khoan_luong%rowtype;
  begin
    select * into v from loai_khoan_luong
     where ma_khoan = upper(p_ma) and p_ngay between tu_ngay and nvl(den_ngay, c_xa);
    return v;
  exception
    when no_data_found then
      raise_application_error(-20532, 'Khoản lương "' || p_ma || '" không có hiệu lực tại '
        || to_char(p_ngay, 'DD/MM/YYYY') || '.');
  end khoan;

  -- Phien ban chinh sach phu tron thang [p_tu, p_den]; khong co -> -20513
  function chinh_sach_cua_thang(p_tu in date, p_den in date) return number
  is
    v number;
  begin
    select chinh_sach_id into v from chinh_sach_luong
     where tu_ngay <= p_tu and nvl(den_ngay, c_xa) >= p_den;
    return v;
  exception
    when no_data_found then
      raise_application_error(-20513, 'Không có chính sách lương hiệu lực cho tháng '
        || to_char(p_tu, 'MM/YYYY') || ' (BR-21).');
  end chinh_sach_cua_thang;

  -- Khoa nguoi dung cho moi thao tac ghi chinh sach (giai phong khi COMMIT/ROLLBACK)
  procedure khoa_chinh_sach
  is
    v_id integer;
    v_kq integer;
  begin
    -- ORA_HASH chi dung trong SQL
    select 1000000 + ora_hash('HRM_CHINH_SACH_LUONG', 999999999) into v_id from dual;
    v_kq := dbms_lock.request(id => v_id, lockmode => dbms_lock.x_mode,
                              timeout => 5, release_on_commit => true);
    if v_kq not in (0, 4) then
      raise_application_error(-20502, 'Chính sách lương đang được sửa ở phiên khác, thử lại sau.');
    end if;
  end khoa_chinh_sach;

  -- Phien ban da dung o ky DA_KHOA (sau p_sau_ngay neu truyen) thi tu choi
  procedure yeu_cau_chua_dung_o_ky_khoa(p_chinh_sach_id in number, p_sau_ngay in date default null)
  is
    v_ky varchar2(200);
  begin
    select listagg(lpad(thang, 2, '0') || '/' || nam, ', ') within group (order by nam, thang)
      into v_ky
      from ky_luong
     where chinh_sach_id = p_chinh_sach_id and trang_thai = 'DA_KHOA'
       and (p_sau_ngay is null
            or last_day(to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD')) > p_sau_ngay);
    if v_ky is not null then
      raise_application_error(-20509, 'Phiên bản chính sách đã dùng ở kỳ đã khóa (' || v_ky
        || '): không sửa/xóa được (BR-29). Tạo phiên bản mới cho giai đoạn sau.');
    end if;
  end yeu_cau_chua_dung_o_ky_khoa;

  procedure yeu_cau_khong_chong_chinh_sach(p_id in number, p_tu in date, p_den in date)
  is
    v_n number;
  begin
    select count(*) into v_n from chinh_sach_luong
     where chinh_sach_id <> nvl(p_id, -1)
       and tu_ngay <= nvl(p_den, c_xa) and nvl(den_ngay, c_xa) >= p_tu;
    if v_n > 0 then
      raise_application_error(-20514, 'Khoảng hiệu lực ' || to_char(p_tu, 'DD/MM/YYYY') || ' – '
        || nvl(to_char(p_den, 'DD/MM/YYYY'), '...') || ' chồng với phiên bản chính sách khác (BR-28).');
    end if;
  end yeu_cau_khong_chong_chinh_sach;

  -- ===========================================================================
  -- Co che phien ban dau vao (muc 7.7)
  -- ===========================================================================
  procedure danh_dau_tinh_lai(p_tu_ngay in date, p_den_ngay in date)
    accessible by (package pkg_hr, package pkg_att, package pkg_payroll)
  is
    v_den date := nvl(p_den_ngay, c_xa);
  begin
    for k in (select ky_luong_id, thang, nam, trang_thai
                from ky_luong
               where to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD') <= v_den
                 and last_day(to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD')) >= trunc(p_tu_ngay)
               order by nam, thang
                 for update)
    loop
      if k.trang_thai = 'DA_KHOA' then
        raise_application_error(-20501,
          'Kỳ ' || ten_ky(k.thang, k.nam) || ' đã khóa: không sửa dữ liệu làm thay đổi lương '
          || 'của kỳ này. Ghi phát sinh điều chỉnh ở kỳ chưa khóa (BR-32).');
      end if;

      update ky_luong
         set phien_ban_dau_vao = phien_ban_dau_vao + 1,
             trang_thai = case when trang_thai = 'DA_TINH' then 'CHOT_CONG' else trang_thai end
       where ky_luong_id = k.ky_luong_id;
    end loop;
  end danh_dau_tinh_lai;

  -- ===========================================================================
  -- SP-21 Tao ky
  -- ===========================================================================
  procedure sp_tao_ky_luong(
    p_thang        in  number,
    p_nam          in  number,
    p_ngay_chi_tra in  date default null,
    o_ky_luong_id  out number)
  is
    v_tu date;
  begin
    savepoint sp_tao_ky;
    pkg_chung.yeu_cau_vai_tro('PAYROLL');
    v_tu := ngay_dau_thang(p_thang, p_nam);

    -- Trung (thang, nam) do UNIQUE chan -> dich_loi ra -20510
    insert into ky_luong (thang, nam, ngay_chi_tra_du_kien)
    values (p_thang, p_nam, trunc(nvl(p_ngay_chi_tra, last_day(v_tu))))
    returning ky_luong_id into o_ky_luong_id;
  exception
    when others then
      rollback to sp_tao_ky;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_tao_ky_luong;

  -- ===========================================================================
  -- SP-12 Chinh sach theo phien ban
  -- ===========================================================================
  -- Kiem tra 3 bang con sau khi ghi (doc lai trong cung transaction)
  procedure kiem_tra_bang_con(p_cs in number)
  is
    v_n       number;
    v_truoc   bac_thue_tncn%rowtype;
    v_bac_ky  number := 0;
  begin
    -- He so OT: du 3 loai ngay va khong thap hon muc luat
    select count(*) into v_n from he_so_ot where chinh_sach_id = p_cs;
    if v_n <> 3 then
      raise_application_error(-20517, 'Cần đủ hệ số OT cho 3 loại ngày LAM_VIEC, NGHI_TUAN, LE.');
    end if;
    for h in (select loai_ngay, he_so from he_so_ot where chinh_sach_id = p_cs) loop
      if h.he_so < case h.loai_ngay when 'LAM_VIEC' then c_ot_min_lam_viec
                                    when 'NGHI_TUAN' then c_ot_min_nghi_tuan
                                    else c_ot_min_le end then
        raise_application_error(-20517, 'Hệ số OT ' || h.loai_ngay || ' = ' || h.he_so
          || ' thấp hơn mức tối thiểu của luật (BLLĐ 2019 Điều 98).');
      end if;
    end loop;

    -- Bao hiem: du 4 loai
    select count(*) into v_n from ty_le_bao_hiem where chinh_sach_id = p_cs;
    if v_n <> 4 then
      raise_application_error(-20516, 'Cần đủ tỷ lệ 4 loại bảo hiểm BHXH, BHTNLD, BHYT, BHTN.');
    end if;

    -- Bac thue lien tuc: bac 1..n, bac 1 tu 0, can duoi = can tren bac truoc,
    -- chi bac cuoi khong co can tren (BR-28)
    for b in (select * from bac_thue_tncn where chinh_sach_id = p_cs order by bac) loop
      v_bac_ky := v_bac_ky + 1;
      if b.bac <> v_bac_ky then
        raise_application_error(-20515, 'Biểu thuế thiếu bậc ' || v_bac_ky || ' (bậc phải liên tục từ 1).');
      end if;
      if v_bac_ky = 1 and b.can_duoi <> 0 then
        raise_application_error(-20515, 'Bậc 1 phải bắt đầu từ 0.');
      end if;
      if v_bac_ky > 1 then
        if v_truoc.can_tren is null then
          raise_application_error(-20515, 'Chỉ bậc cuối được bỏ trống cận trên (bậc ' || v_truoc.bac || ').');
        end if;
        if b.can_duoi <> v_truoc.can_tren then
          raise_application_error(-20515, 'Biểu thuế hở/chồng giữa bậc ' || v_truoc.bac || ' và bậc ' || b.bac
            || ': cận trên ' || v_truoc.can_tren || ' ≠ cận dưới ' || b.can_duoi || ' (BR-28).');
        end if;
      end if;
      v_truoc := b;
    end loop;
    if v_bac_ky = 0 then
      raise_application_error(-20515, 'Biểu thuế chưa có bậc nào.');
    end if;
    if v_truoc.can_tren is not null then
      raise_application_error(-20515, 'Bậc cuối (bậc ' || v_truoc.bac || ') không được có cận trên.');
    end if;
  end kiem_tra_bang_con;

  procedure sp_luu_chinh_sach(
    p_tu_ngay           in  date,
    p_den_ngay          in  date,
    p_giam_tru_ban_than in  number,
    p_giam_tru_npt      in  number,
    p_han_muc_ot_ngay   in  number,
    p_han_muc_ot_thang  in  number,
    p_han_muc_ot_nam    in  number,
    p_nguon_can_cu      in  varchar2,
    p_he_so_ot          in  clob,
    p_bao_hiem          in  clob,
    p_bac_thue          in  clob,
    p_chinh_sach_id     in  number default null,
    o_chinh_sach_id     out number)
  is
    v_cu chinh_sach_luong%rowtype;
  begin
    savepoint sp_cs;
    pkg_chung.yeu_cau_vai_tro('PAYROLL');
    khoa_chinh_sach;

    if p_chinh_sach_id is not null then
      begin
        select * into v_cu from chinh_sach_luong where chinh_sach_id = p_chinh_sach_id for update;
      exception
        when no_data_found then
          raise_application_error(-20530, 'Phiên bản chính sách ' || p_chinh_sach_id || ' không tồn tại.');
      end;
      yeu_cau_chua_dung_o_ky_khoa(p_chinh_sach_id);
      -- Khoang cu cung bi anh huong (ky tung dung phien ban nay phai tinh lai)
      danh_dau_tinh_lai(v_cu.tu_ngay, v_cu.den_ngay);
    end if;

    yeu_cau_khong_chong_chinh_sach(p_chinh_sach_id, p_tu_ngay, p_den_ngay);
    danh_dau_tinh_lai(p_tu_ngay, p_den_ngay);

    if p_chinh_sach_id is null then
      insert into chinh_sach_luong (tu_ngay, den_ngay, giam_tru_ban_than, giam_tru_nguoi_phu_thuoc,
                                    han_muc_ot_ngay, han_muc_ot_thang, han_muc_ot_nam, nguon_can_cu)
      values (p_tu_ngay, p_den_ngay, p_giam_tru_ban_than, p_giam_tru_npt,
              p_han_muc_ot_ngay, p_han_muc_ot_thang, p_han_muc_ot_nam, p_nguon_can_cu)
      returning chinh_sach_id into o_chinh_sach_id;
    else
      o_chinh_sach_id := p_chinh_sach_id;
      update chinh_sach_luong
         set tu_ngay = p_tu_ngay, den_ngay = p_den_ngay,
             giam_tru_ban_than = p_giam_tru_ban_than, giam_tru_nguoi_phu_thuoc = p_giam_tru_npt,
             han_muc_ot_ngay = p_han_muc_ot_ngay, han_muc_ot_thang = p_han_muc_ot_thang,
             han_muc_ot_nam = p_han_muc_ot_nam, nguon_can_cu = p_nguon_can_cu
       where chinh_sach_id = p_chinh_sach_id;
      delete from he_so_ot       where chinh_sach_id = p_chinh_sach_id;
      delete from ty_le_bao_hiem where chinh_sach_id = p_chinh_sach_id;
      delete from bac_thue_tncn  where chinh_sach_id = p_chinh_sach_id;
    end if;

    -- Ba bang con tu JSON (JSON_TABLE). Thieu truong -> NOT NULL chan (-20901).
    begin
      insert into he_so_ot (chinh_sach_id, loai_ngay, he_so)
      select o_chinh_sach_id, upper(j.loai_ngay), j.he_so
        from json_table(p_he_so_ot, '$[*]' error on error
               columns (loai_ngay varchar2(10) path '$.loai_ngay' null on empty,
                        he_so     number       path '$.he_so' null on empty)) j;

      insert into ty_le_bao_hiem (chinh_sach_id, loai_bao_hiem, ty_le_nld, ty_le_nsdld,
                                  san_dong, tran_dong, can_cu_ap_dung)
      select o_chinh_sach_id, upper(j.loai), j.nld, j.nsdld, j.san, j.tran, j.can_cu
        from json_table(p_bao_hiem, '$[*]' error on error
               columns (loai   varchar2(10)  path '$.loai' null on empty,
                        nld    number        path '$.nld' null on empty,
                        nsdld  number        path '$.nsdld' null on empty,
                        san    number        path '$.san' null on empty,
                        tran   number        path '$.tran' null on empty,
                        can_cu varchar2(500) path '$.can_cu' null on empty)) j;

      insert into bac_thue_tncn (chinh_sach_id, bac, can_duoi, can_tren, thue_suat)
      select o_chinh_sach_id, j.bac, j.can_duoi, j.can_tren, j.thue_suat
        from json_table(p_bac_thue, '$[*]' error on error
               columns (bac       number path '$.bac' null on empty,
                        can_duoi  number path '$.can_duoi' null on empty,
                        can_tren  number path '$.can_tren' null on empty,
                        thue_suat number path '$.thue_suat' null on empty)) j;
    exception
      when others then
        if sqlcode between -40999 and -40400 then
          raise_application_error(-20528, 'Dữ liệu JSON của chính sách không hợp lệ: ' || substr(sqlerrm, 1, 200));
        end if;
        raise;
    end;

    kiem_tra_bang_con(o_chinh_sach_id);
  exception
    when others then
      rollback to sp_cs;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_chinh_sach;

  procedure sp_ket_thuc_chinh_sach(
    p_chinh_sach_id in number,
    p_den_ngay      in date)
  is
    v_cu  chinh_sach_luong%rowtype;
    v_a   date;
    v_b   date;
  begin
    savepoint sp_kt_cs;
    pkg_chung.yeu_cau_vai_tro('PAYROLL');
    khoa_chinh_sach;
    begin
      select * into v_cu from chinh_sach_luong where chinh_sach_id = p_chinh_sach_id for update;
    exception
      when no_data_found then
        raise_application_error(-20530, 'Phiên bản chính sách ' || p_chinh_sach_id || ' không tồn tại.');
    end;

    -- Ky da khoa dung phien ban nay phai van nam trong khoang moi
    yeu_cau_chua_dung_o_ky_khoa(p_chinh_sach_id, p_den_ngay);
    yeu_cau_khong_chong_chinh_sach(p_chinh_sach_id, v_cu.tu_ngay, p_den_ngay);

    -- Chi phan thay doi [ngay nho hon + 1, ngay lon hon] bi anh huong
    v_a := nvl(v_cu.den_ngay, c_xa);
    v_b := nvl(trunc(p_den_ngay), c_xa);
    if v_a <> v_b then
      danh_dau_tinh_lai(least(v_a, v_b) + 1, case when greatest(v_a, v_b) = c_xa then null else greatest(v_a, v_b) end);
    end if;

    update chinh_sach_luong set den_ngay = p_den_ngay where chinh_sach_id = p_chinh_sach_id;
  exception
    when others then
      rollback to sp_kt_cs;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_ket_thuc_chinh_sach;

  -- ===========================================================================
  -- SP-22 Phu cap
  -- ===========================================================================
  procedure sp_luu_phu_cap(
    p_ma_nhan_vien in varchar2,
    p_ma_khoan     in varchar2,
    p_muc_tien     in number,
    p_tu_ngay      in date,
    p_den_ngay     in date    default null,
    p_sua          in boolean default false)
  is
    v_nv_id  number;
    v_nv     nhan_vien%rowtype;
    v_lk     loai_khoan_luong%rowtype;
    v_cu     khoan_luong_nhan_vien%rowtype;
    v_tu     date := trunc(p_tu_ngay);
    v_den    date := trunc(p_den_ngay);
    v_a      date;
    v_b      date;
    v_n      number;
    v_bo_qua date;     -- khi sua: ban ghi dang sua khong tinh la chong voi chinh no
  begin
    savepoint sp_pc;
    pkg_chung.yeu_cau_vai_tro('PAYROLL');
    v_nv_id := id_nhan_vien(p_ma_nhan_vien);

    -- Chi khoan thu nhap theo thang / theo cong; luong theo cong lay tu hop dong
    v_lk := khoan(p_ma_khoan, v_tu);
    if v_lk.nhom_khoan <> 'THU_NHAP' or v_lk.cach_tinh not in ('THEO_THANG', 'THEO_CONG')
       or v_lk.ma_khoan = 'LUONG_CONG' then
      raise_application_error(-20519, 'Khoản "' || p_ma_khoan || '" không phải phụ cấp '
        || '(cần nhóm THU_NHAP, cách tính THEO_THANG hoặc THEO_CONG).');
    end if;

    -- Hieu luc tron thang (giong BR-39) de moi ky co toi da mot muc cho moi loai
    if v_tu <> trunc(v_tu, 'MM') or (v_den is not null and v_den <> last_day(v_den)) then
      raise_application_error(-20527, 'Phụ cấp có hiệu lực từ ngày 1 và kết thúc ngày cuối tháng.');
    end if;
    if v_den < v_tu then
      raise_application_error(-20531, 'Ngày kết thúc phụ cấp trước ngày bắt đầu.');
    end if;

    -- Xac dinh khoang bi anh huong de danh dau tinh lai (muc 7.7: ca khoang cu khi sua)
    if p_sua then
      begin
        select k.* into v_cu
          from khoan_luong_nhan_vien k join loai_khoan_luong l on l.loai_khoan_id = k.loai_khoan_id
         where k.nhan_vien_id = v_nv_id and l.ma_khoan = v_lk.ma_khoan and k.tu_ngay = v_tu;
      exception
        when no_data_found then
          raise_application_error(-20529, 'Không có phụ cấp ' || v_lk.ma_khoan || ' của '
            || upper(p_ma_nhan_vien) || ' bắt đầu ' || to_char(v_tu, 'DD/MM/YYYY') || '.');
      end;
      v_a := nvl(v_cu.den_ngay, c_xa);
      v_b := nvl(v_den, c_xa);
      if v_cu.muc_tien = p_muc_tien then
        -- chi doi ngay ket thuc: anh huong phan chenh lech
        if v_a <> v_b then
          danh_dau_tinh_lai(least(v_a, v_b) + 1, case when greatest(v_a, v_b) = c_xa then null else greatest(v_a, v_b) end);
        end if;
      else
        danh_dau_tinh_lai(v_tu, case when greatest(v_a, v_b) = c_xa then null else greatest(v_a, v_b) end);
      end if;
    else
      danh_dau_tinh_lai(v_tu, v_den);
    end if;

    -- Khoa nhan vien roi moi kiem tra chong (hai phien cung them se tuan tu)
    select * into v_nv from nhan_vien where nhan_vien_id = v_nv_id for update;
    if v_tu > nvl(v_nv.ngay_nghi_viec, c_xa) or nvl(v_den, c_xa) < trunc(v_nv.ngay_vao_lam, 'MM') then
      raise_application_error(-20520, 'Khoảng phụ cấp nằm ngoài thời gian làm việc của '
        || v_nv.ma_nhan_vien || '.');
    end if;

    v_bo_qua := case when p_sua then v_tu else date '0001-01-01' end;
    select count(*) into v_n
      from khoan_luong_nhan_vien k join loai_khoan_luong l on l.loai_khoan_id = k.loai_khoan_id
     where k.nhan_vien_id = v_nv_id and l.ma_khoan = v_lk.ma_khoan
       and k.tu_ngay <> v_bo_qua
       and k.tu_ngay <= nvl(v_den, c_xa) and nvl(k.den_ngay, c_xa) >= v_tu;
    if v_n > 0 then
      raise_application_error(-20518, v_nv.ma_nhan_vien || ' đã có phụ cấp ' || v_lk.ma_khoan
        || ' chồng khoảng ' || to_char(v_tu, 'DD/MM/YYYY') || ' – '
        || nvl(to_char(v_den, 'DD/MM/YYYY'), '...') || ' (FR-PAY-03).');
    end if;

    if p_sua then
      update khoan_luong_nhan_vien
         set muc_tien = p_muc_tien, den_ngay = v_den
       where khoan_nhan_vien_id = v_cu.khoan_nhan_vien_id;
    else
      insert into khoan_luong_nhan_vien (nhan_vien_id, loai_khoan_id, muc_tien, tu_ngay, den_ngay)
      values (v_nv_id, v_lk.loai_khoan_id, p_muc_tien, v_tu, v_den);
    end if;
  exception
    when others then
      rollback to sp_pc;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_phu_cap;

  -- ===========================================================================
  -- SP-11 Phat sinh
  -- ===========================================================================
  procedure sp_luu_phat_sinh(
    p_ma_nhan_vien in  varchar2,
    p_thang        in  number,
    p_nam          in  number,
    p_ma_khoan     in  varchar2,
    p_so_tien      in  number,
    p_can_cu       in  varchar2,
    p_phieu_goc_id in  number default null,
    o_phat_sinh_id out number)
  is
    v_tu      date;
    v_ky_id   number;
    v_nv_id   number;
    v_nv      nhan_vien%rowtype;
    v_lk      loai_khoan_luong%rowtype;
    v_goc_nv  number;
    v_goc_tt  varchar2(10);
    v_goc_tu  date;
  begin
    savepoint sp_ps;
    pkg_chung.yeu_cau_vai_tro('PAYROLL');
    v_tu    := ngay_dau_thang(p_thang, p_nam);
    v_ky_id := id_ky(p_thang, p_nam);
    v_nv_id := id_nhan_vien(p_ma_nhan_vien);

    v_lk := khoan(p_ma_khoan, v_tu);
    if v_lk.cach_tinh <> 'THEO_PHAT_SINH' then
      raise_application_error(-20519, 'Khoản "' || p_ma_khoan || '" không ghi bằng phát sinh '
        || '(chỉ các khoản cách tính THEO_PHAT_SINH).');
    end if;
    if nvl(p_so_tien, 0) <= 0 or trim(p_can_cu) is null then
      raise_application_error(-20522, 'Phát sinh phải có số tiền > 0 và căn cứ (FR-PAY-04).');
    end if;

    -- Khoa ky (tu choi neu DA_KHOA: TC-34), dua ky DA_TINH ve CHOT_CONG
    danh_dau_tinh_lai(v_tu, last_day(v_tu));

    select * into v_nv from nhan_vien where nhan_vien_id = v_nv_id for update;
    if v_nv.ngay_vao_lam > last_day(v_tu) or nvl(v_nv.ngay_nghi_viec, c_xa) < v_tu then
      raise_application_error(-20520, v_nv.ma_nhan_vien || ' không làm việc trong kỳ '
        || ten_ky(p_thang, p_nam) || ', không có phiếu để ghi phát sinh.');
    end if;

    -- Dieu chinh cho ky da khoa: phieu goc cung nguoi, thuoc ky DA_KHOA truoc ky nay (BR-32)
    if p_phieu_goc_id is not null then
      begin
        select p.nhan_vien_id, k.trang_thai, to_date(k.nam || '-' || k.thang || '-01', 'YYYY-MM-DD')
          into v_goc_nv, v_goc_tt, v_goc_tu
          from phieu_luong p join ky_luong k on k.ky_luong_id = p.ky_luong_id
         where p.phieu_luong_id = p_phieu_goc_id;
      exception
        when no_data_found then
          raise_application_error(-20521, 'Phiếu gốc ' || p_phieu_goc_id || ' không tồn tại.');
      end;
      if v_goc_nv <> v_nv_id or v_goc_tt <> 'DA_KHOA' or v_goc_tu >= v_tu then
        raise_application_error(-20521, 'Phiếu gốc phải là phiếu của cùng nhân viên, thuộc kỳ đã khóa '
          || 'trước kỳ ghi nhận (BR-32).');
      end if;
    end if;

    insert into phat_sinh_luong (nhan_vien_id, ky_luong_id, loai_khoan_id, so_tien, chieu_dieu_chinh,
                                 can_cu, nguoi_tao, phieu_luong_goc_id)
    values (v_nv_id, v_ky_id, v_lk.loai_khoan_id, p_so_tien,
            case v_lk.nhom_khoan when 'THU_NHAP' then 'TANG' else 'GIAM' end,
            p_can_cu, pkg_chung.tai_khoan, p_phieu_goc_id)
    returning phat_sinh_id into o_phat_sinh_id;
  exception
    when others then
      rollback to sp_ps;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_luu_phat_sinh;

  -- ===========================================================================
  -- SP-10 Chuyen thuong
  -- ===========================================================================
  procedure sp_chuyen_thuong(
    p_so_quyet_dinh in  varchar2,
    p_thang         in  number,
    p_nam           in  number,
    o_phat_sinh_id  out number)
  is
    v_tu    date;
    v_ky_id number;
    v_kt    khen_thuong%rowtype;
    v_nv    nhan_vien%rowtype;
    v_n     number;
    v_lk_id number;
  begin
    savepoint sp_ct;
    pkg_chung.yeu_cau_vai_tro('PAYROLL');
    v_tu    := ngay_dau_thang(p_thang, p_nam);
    v_ky_id := id_ky(p_thang, p_nam);

    begin
      select khen_thuong_id into v_n from khen_thuong where so_quyet_dinh = p_so_quyet_dinh;
    exception
      when no_data_found then
        raise_application_error(-20508, 'Quyết định khen thưởng "' || p_so_quyet_dinh || '" không tồn tại.');
    end;

    -- TX-06: KY_LUONG truoc (danh dau, tu choi ky DA_KHOA), roi KHEN_THUONG
    danh_dau_tinh_lai(v_tu, last_day(v_tu));
    select * into v_kt from khen_thuong where khen_thuong_id = v_n for update;

    if v_kt.hinh_thuc <> 'TIEN' or v_kt.trang_thai_duyet <> 'DA_DUYET' then
      raise_application_error(-20508, 'Chỉ chuyển thưởng TIỀN đã duyệt (quyết định '
        || v_kt.so_quyet_dinh || ': ' || v_kt.hinh_thuc || ', ' || v_kt.trang_thai_duyet || ').');
    end if;
    if v_kt.ngay_quyet_dinh > last_day(v_tu) then
      raise_application_error(-20508, 'Kỳ ' || ten_ky(p_thang, p_nam) || ' trước ngày quyết định '
        || to_char(v_kt.ngay_quyet_dinh, 'DD/MM/YYYY') || '.');
    end if;

    -- Da chuyen? (UNIQUE(KHEN_THUONG_ID) la lop chan thu hai)
    select count(*) into v_n from phat_sinh_luong where khen_thuong_id = v_kt.khen_thuong_id;
    if v_n > 0 then
      raise_application_error(-20507, 'Quyết định ' || v_kt.so_quyet_dinh
        || ' đã chuyển sang lương, không chuyển lần hai (BR-30).');
    end if;

    select * into v_nv from nhan_vien where nhan_vien_id = v_kt.nhan_vien_id;
    if v_nv.ngay_vao_lam > last_day(v_tu) or nvl(v_nv.ngay_nghi_viec, c_xa) < v_tu then
      raise_application_error(-20520, v_nv.ma_nhan_vien || ' không làm việc trong kỳ '
        || ten_ky(p_thang, p_nam) || '.');
    end if;

    v_lk_id := khoan('THUONG', v_tu).loai_khoan_id;   -- ham private: khong goi trong SQL

    -- Da duyet o khen thuong: phat sinh mang trang thai DA_DUYET, nguoi duyet
    -- la nguoi duyet quyet dinh (CK_PS_KHONG_TU_DUYET cho phep vi co KHEN_THUONG_ID)
    insert into phat_sinh_luong (nhan_vien_id, ky_luong_id, loai_khoan_id, so_tien, chieu_dieu_chinh,
                                 can_cu, nguoi_tao, trang_thai_duyet, nguoi_duyet, khen_thuong_id)
    values (v_kt.nhan_vien_id, v_ky_id, v_lk_id, v_kt.so_tien, 'TANG',
            'Quyết định khen thưởng ' || v_kt.so_quyet_dinh, pkg_chung.tai_khoan,
            'DA_DUYET', v_kt.nguoi_duyet, v_kt.khen_thuong_id)
    returning phat_sinh_id into o_phat_sinh_id;
  exception
    when others then
      rollback to sp_ct;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_chuyen_thuong;

  -- ===========================================================================
  -- QR-23 doi chieu phieu - chi tiet
  -- ===========================================================================
  function so_phieu_lech(p_ky_luong_id in number) return number
  is
    v number;
  begin
    select count(*) into v
      from phieu_luong p
      left join (select phieu_luong_id,
                        sum(case nhom_khoan_ap_dung when 'THU_NHAP' then thanh_tien
                                                    when 'GIAM_THU_NHAP' then -thanh_tien else 0 end) as gross,
                        greatest(sum(case nhom_khoan_ap_dung when 'THU_NHAP' then phan_chiu_thue
                                                             when 'GIAM_THU_NHAP' then -phan_chiu_thue else 0 end), 0) as tnct,
                        sum(case when nhom_khoan_ap_dung = 'BAO_HIEM_NLD'   then thanh_tien else 0 end) as bh_nld,
                        sum(case when nhom_khoan_ap_dung = 'BAO_HIEM_NSDLD' then thanh_tien else 0 end) as bh_nsdld,
                        sum(case when nhom_khoan_ap_dung = 'THUE_TNCN'      then thanh_tien else 0 end) as thue,
                        sum(case when nhom_khoan_ap_dung = 'KHAU_TRU'       then thanh_tien else 0 end) as khau_tru
                   from chi_tiet_phieu_luong
                  group by phieu_luong_id) c on c.phieu_luong_id = p.phieu_luong_id
     where p.ky_luong_id = p_ky_luong_id
       and (   c.phieu_luong_id is null
            or p.tong_gross         <> c.gross
            or p.thu_nhap_chiu_thue <> c.tnct
            or p.bao_hiem_nld       <> c.bh_nld
            or p.bao_hiem_nsdld     <> c.bh_nsdld
            or p.thue_tncn          <> c.thue
            or p.khau_tru_khac      <> c.khau_tru);
    return v;
  end so_phieu_lech;

  -- So nguoi phai co phieu: thoi gian lam viec giao ky
  function so_nguoi_trong_ky(p_tu in date, p_den in date) return number
  is
    v number;
  begin
    select count(*) into v from nhan_vien
     where ngay_vao_lam <= p_den and nvl(ngay_nghi_viec, c_xa) >= p_tu;
    return v;
  end so_nguoi_trong_ky;

  -- ===========================================================================
  -- SP-08 Tinh luong ky (TX-04)
  --
  -- Hai buoc:
  --   1. TINH trong bo nho (collection) cho tung nguoi; gom loi cap nhan vien.
  --   2. Neu 0 loi: xoa ket qua cu, ghi phieu + chi tiet, doi chieu QR-23,
  --      gan PHIEN_BAN_DA_TINH := PHIEN_BAN_DAU_VAO, ky -> DA_TINH.
  -- Moi loi bat ngo o buoc 2 -> ROLLBACK TO SAVEPOINT: ket qua cu con nguyen (BR-22).
  -- Cong thuc: dac ta muc 9. Ky hieu: L luong, Hc gio chuan thang, Hh gio huong luong.
  -- ===========================================================================
  procedure sp_tinh_luong_ky(
    p_thang  in  number,
    p_nam    in  number,
    o_so_loi out number,
    o_ds_loi out clob)
  is
    -- Mot dong chi tiet trong bo nho
    type r_dong is record (
      phieu_idx          pls_integer,
      loai_khoan_id      number,
      nhom               varchar2(15),
      so_luong           number,
      don_gia            number,
      he_so              number,
      phan_chiu_thue     number,
      phat_sinh_id       number,
      khoan_nhan_vien_id number,
      tang_ca_id         number);
    type t_dong is table of r_dong index by pls_integer;

    -- Mot phieu trong bo nho (cac tong cong don tu dong da lam tron)
    type r_phieu is record (
      nhan_vien_id   number,
      hop_dong_id    number,
      phong_ban_id   number,
      chuc_vu_id     number,
      luong_co_ban   number,
      gio_huong      number,
      gross          number := 0,
      tnct           number := 0,
      giam_tru       number := 0,
      bh_nld         number := 0,
      bh_nsdld       number := 0,
      thue           number := 0,
      khau_tru       number := 0);
    type t_phieu is table of r_phieu index by pls_integer;

    v_dong   t_dong;
    v_phieu  t_phieu;
    v_ky     ky_luong%rowtype;
    v_tu     date;
    v_den    date;
    v_cs     chinh_sach_luong%rowtype;
    v_cs_id  number;
    v_hc     number;
    v_so_ngay number;
    p        pls_integer;              -- chi so phieu dang tinh

    -- --- Them mot dong vao phieu p, cong don tong theo nhom khoan ---------------
    procedure them_dong(
      p_lk      in loai_khoan_luong%rowtype,
      p_sl      in number,
      p_dg      in number,
      p_hs      in number,
      p_ps      in number default null,
      p_klnv    in number default null,
      p_tc      in number default null)
    is
      i       pls_integer := v_dong.count + 1;
      v_tien  number := round(p_sl * p_dg * p_hs, 0);   -- = cot ao THANH_TIEN
      v_chiu  number := 0;
    begin
      if p_lk.nhom_khoan in ('THU_NHAP', 'GIAM_THU_NHAP') then
        v_chiu := case p_lk.cach_xu_ly_thue
                    when 'CHIU_THUE'            then v_tien
                    when 'MIEN_TOAN_BO'         then 0
                    -- chi phan vuot muc luong gio binh thuong duoc mien (he so 1)
                    when 'MIEN_PHAN_CHENH_LECH' then least(round(p_sl * p_dg, 0), v_tien)
                  end;
      end if;

      v_dong(i).phieu_idx          := p;
      v_dong(i).loai_khoan_id      := p_lk.loai_khoan_id;
      v_dong(i).nhom               := p_lk.nhom_khoan;
      v_dong(i).so_luong           := p_sl;
      v_dong(i).don_gia            := p_dg;
      v_dong(i).he_so              := p_hs;
      v_dong(i).phan_chiu_thue     := v_chiu;
      v_dong(i).phat_sinh_id       := p_ps;
      v_dong(i).khoan_nhan_vien_id := p_klnv;
      v_dong(i).tang_ca_id         := p_tc;

      case p_lk.nhom_khoan
        when 'THU_NHAP'       then v_phieu(p).gross    := v_phieu(p).gross + v_tien;
                                   v_phieu(p).tnct     := v_phieu(p).tnct  + v_chiu;
        when 'GIAM_THU_NHAP'  then v_phieu(p).gross    := v_phieu(p).gross - v_tien;
                                   v_phieu(p).tnct     := v_phieu(p).tnct  - v_chiu;
        when 'BAO_HIEM_NLD'   then v_phieu(p).bh_nld   := v_phieu(p).bh_nld + v_tien;
        when 'BAO_HIEM_NSDLD' then v_phieu(p).bh_nsdld := v_phieu(p).bh_nsdld + v_tien;
        when 'THUE_TNCN'      then v_phieu(p).thue     := v_phieu(p).thue + v_tien;
        when 'KHAU_TRU'       then v_phieu(p).khau_tru := v_phieu(p).khau_tru + v_tien;
      end case;
    end them_dong;

    procedure them_loi(p_loai in varchar2, p_ma in varchar2, p_chi_tiet in varchar2)
    is
    begin
      o_so_loi := o_so_loi + 1;
      o_ds_loi := o_ds_loi || p_loai || ' | ' || p_ma || ' | ' || p_chi_tiet || chr(10);
    end them_loi;

    function lk_theo_id(p_id in number) return loai_khoan_luong%rowtype
    is
      v loai_khoan_luong%rowtype;
    begin
      select * into v from loai_khoan_luong where loai_khoan_id = p_id;
      return v;
    end lk_theo_id;

    -- --- Tinh phieu cho mot nhan vien; tra FALSE neu co loi (da ghi vao danh sach)
    function tinh_mot_nguoi(p_nv in nhan_vien%rowtype) return boolean
    is
      v_dau       date := greatest(v_tu, p_nv.ngay_vao_lam);                  -- khoang lam viec
      v_cuoi      date := least(v_den, nvl(p_nv.ngay_nghi_viec, c_xa));      -- trong ky
      v_l         number;    -- L
      v_cc_hd     number;    -- can cu bao hiem theo hop dong
      v_hd        number;
      v_hh        number;    -- Hh
      v_co_so_ot  number;    -- tong khoan tinh vao don gia OT (theo thang)
      v_cc_them   number := 0;
      v_dg_ot     number;
      v_cc_bh     number;
      v_npt       number;
      v_tntt      number;
      v_thue      number;
      v_net       number;
      type t_n is table of number;
      v_ds_l  t_n;  v_ds_cc t_n;  v_ds_hd t_n;
    begin
      p := v_phieu.count + 1;
      v_phieu(p).nhan_vien_id := p_nv.nhan_vien_id;

      -- (1) Muc luong hop dong hieu luc trong khoang lam viec: dung mot muc
      select m.luong_co_ban, m.can_cu_dong_bao_hiem, h.hop_dong_id
        bulk collect into v_ds_l, v_ds_cc, v_ds_hd
        from muc_luong_hop_dong m
        join hop_dong h on h.hop_dong_id = m.hop_dong_id
       where h.nhan_vien_id = p_nv.nhan_vien_id and not h.da_huy
         and m.tu_ngay <= v_cuoi and nvl(m.den_ngay, c_xa) >= v_dau;
      if v_ds_l.count <> 1 then
        them_loi(case when v_ds_l.count = 0 then 'THIEU_MUC_LUONG' else 'NHIEU_MUC_LUONG' end,
                 p_nv.ma_nhan_vien, v_ds_l.count || ' mức lương hợp đồng hiệu lực trong kỳ (BR-21)');
        v_phieu.delete(p);
        return false;
      end if;
      v_l := v_ds_l(1);  v_cc_hd := v_ds_cc(1);  v_hd := v_ds_hd(1);
      v_phieu(p).hop_dong_id  := v_hd;
      v_phieu(p).luong_co_ban := v_l;

      -- (2) Phan cong tai ngay cuoi cua khoang lam viec (snapshot tren phieu, BR-29)
      begin
        select phong_ban_id, chuc_vu_id into v_phieu(p).phong_ban_id, v_phieu(p).chuc_vu_id
          from qua_trinh_cong_tac
         where nhan_vien_id = p_nv.nhan_vien_id
           and v_cuoi between ngay_bat_dau and nvl(ngay_ket_thuc, c_xa);
      exception
        when no_data_found then
          them_loi('THIEU_PHAN_CONG', p_nv.ma_nhan_vien, 'không có phân công tại ' || to_char(v_cuoi, 'DD/MM/YYYY'));
          v_phieu.delete(p);
          return false;
      end;

      -- (3) Luong theo cong = L x Hh / Hc (muc 9.2). Don gia L/Hc giu nguyen do chinh xac.
      v_hh := fn_gio_huong_luong(p_nv.nhan_vien_id, v_ky.ky_luong_id);
      v_phieu(p).gio_huong := v_hh;
      them_dong(khoan('LUONG_CONG', v_tu), v_hh, v_l / v_hc, 1);
      v_co_so_ot := v_l;

      -- (4) Phu cap hieu luc trong khoang lam viec
      for k in (select k.khoan_nhan_vien_id, k.muc_tien, k.loai_khoan_id
                  from khoan_luong_nhan_vien k
                 where k.nhan_vien_id = p_nv.nhan_vien_id
                   and k.tu_ngay <= v_cuoi and nvl(k.den_ngay, c_xa) >= v_dau
                 order by k.loai_khoan_id, k.tu_ngay) loop
        declare
          v_lk loai_khoan_luong%rowtype := lk_theo_id(k.loai_khoan_id);
        begin
          if v_lk.cach_tinh = 'THEO_CONG' then
            them_dong(v_lk, v_hh, k.muc_tien / v_hc, 1, p_klnv => k.khoan_nhan_vien_id);
          else
            them_dong(v_lk, 1, k.muc_tien, 1, p_klnv => k.khoan_nhan_vien_id);
          end if;
          if v_lk.tinh_vao_don_gia_ot then
            v_co_so_ot := v_co_so_ot + k.muc_tien;
          end if;
          if v_lk.cach_xu_ly_bao_hiem = 'TINH_CAN_CU' then
            v_cc_them := v_cc_them + k.muc_tien;
          end if;
        end;
      end loop;

      -- (5) OT da duyet: gio x don gia x he so (FN-04). Don gia tu cac khoan
      --     TINH_VAO_DON_GIA_OT, khong lay gross chia gio (muc 9.3).
      v_dg_ot := v_co_so_ot / v_hc;
      for o in (select o.tang_ca_id, o.so_gio_duoc_duyet, l.loai_ngay
                  from dang_ky_tang_ca o join lich_lam_viec l on l.ngay = o.ngay
                 where o.nhan_vien_id = p_nv.nhan_vien_id and o.trang_thai = 'DA_DUYET'
                   and o.ngay between v_dau and v_cuoi
                 order by o.ngay, o.tang_ca_id) loop
        them_dong(khoan('OT', v_tu), o.so_gio_duoc_duyet, v_dg_ot,
                  fn_he_so_ot(o.loai_ngay, v_cs.chinh_sach_id), p_tc => o.tang_ca_id);
      end loop;

      -- (6) Phat sinh DA_DUYET cua ky: thuong, dieu chinh tang/giam, khau tru
      for s in (select phat_sinh_id, loai_khoan_id, so_tien
                  from phat_sinh_luong
                 where nhan_vien_id = p_nv.nhan_vien_id and ky_luong_id = v_ky.ky_luong_id
                   and trang_thai_duyet = 'DA_DUYET'
                 order by phat_sinh_id) loop
        them_dong(lk_theo_id(s.loai_khoan_id), 1, s.so_tien, 1, p_ps => s.phat_sinh_id);
      end loop;

      if v_phieu(p).gross < 0 then
        them_loi('GROSS_AM', p_nv.ma_nhan_vien, 'gross = ' || v_phieu(p).gross);
      end if;
      v_phieu(p).tnct := greatest(v_phieu(p).tnct, 0);

      -- (7) Bao hiem NLD va NSDLD theo tung loai, can cu sau san/tran (FN-05, muc 9.5)
      if v_hc - v_hh >= c_gio_khong_luong_toi_da then
        them_loi('BH_CHUA_MO_HINH', p_nv.ma_nhan_vien, (v_hc - v_hh)
          || ' giờ không hưởng lương (≥ 14 ngày): trường hợp bảo hiểm chưa mô hình hóa (mục 9.5)');
      end if;
      v_cc_bh := v_cc_hd + v_cc_them;
      for b in (select loai_bao_hiem, ty_le_nld, ty_le_nsdld from ty_le_bao_hiem
                 where chinh_sach_id = v_cs.chinh_sach_id order by loai_bao_hiem) loop
        if b.ty_le_nld > 0 then
          them_dong(khoan(b.loai_bao_hiem || '_NLD', v_tu), 1,
                    fn_can_cu_bao_hiem(v_cc_bh, b.loai_bao_hiem, v_cs.chinh_sach_id), b.ty_le_nld);
        end if;
        if b.ty_le_nsdld > 0 then
          them_dong(khoan(b.loai_bao_hiem || '_NSDLD', v_tu), 1,
                    fn_can_cu_bao_hiem(v_cc_bh, b.loai_bao_hiem, v_cs.chinh_sach_id), b.ty_le_nsdld);
        end if;
      end loop;

      -- (8) Giam tru: ban than + nguoi phu thuoc da xac minh con hieu luc trong thang
      select count(*) into v_npt from nguoi_phu_thuoc
       where nhan_vien_id = p_nv.nhan_vien_id and trang_thai_xac_minh = 'DA_XAC_MINH'
         and tu_ngay <= v_den and nvl(den_ngay, c_xa) >= v_tu;
      v_phieu(p).giam_tru := v_cs.giam_tru_ban_than + v_npt * v_cs.giam_tru_nguoi_phu_thuoc;

      -- (9) Thue luy tien tren TNTT (FN-01)
      v_tntt := greatest(v_phieu(p).tnct - v_phieu(p).bh_nld - v_phieu(p).giam_tru, 0);
      v_thue := fn_tinh_thue_tncn(v_tntt, v_cs.chinh_sach_id);
      if v_thue > 0 then
        them_dong(khoan('THUE_TNCN', v_tu), 1, v_thue, 1);
      end if;

      -- (10) Net = gross - BH NLD - thue - khau tru. BH NSDLD KHONG tru (BR-27).
      v_net := v_phieu(p).gross - v_phieu(p).bh_nld - v_phieu(p).thue - v_phieu(p).khau_tru;
      if v_net < 0 then
        them_loi('NET_AM', p_nv.ma_nhan_vien, 'net = ' || to_char(v_net, 'FM999G999G999G990')
          || ' (gross ' || to_char(v_phieu(p).gross, 'FM999G999G999G990')
          || ', khấu trừ ' || to_char(v_phieu(p).khau_tru, 'FM999G999G999G990') || ') (BR-26)');
      end if;
      return true;
    end tinh_mot_nguoi;

    -- --- Buoc 2: ghi ket qua -------------------------------------------------
    procedure ghi_ket_qua
    is
      v_ids  dbms_sql.number_table;   -- chi so phieu trong bo nho -> PHIEU_LUONG_ID
      i      pls_integer;
    begin
      delete from chi_tiet_phieu_luong
       where phieu_luong_id in (select phieu_luong_id from phieu_luong where ky_luong_id = v_ky.ky_luong_id);
      delete from phieu_luong where ky_luong_id = v_ky.ky_luong_id;

      i := v_phieu.first;
      while i is not null loop
        insert into phieu_luong (ky_luong_id, nhan_vien_id, hop_dong_id, phong_ban_id, chuc_vu_id,
                                 luong_co_ban_ap_dung, gio_huong_luong, thu_nhap_chiu_thue,
                                 giam_tru_ap_dung, tong_gross, bao_hiem_nld, bao_hiem_nsdld,
                                 thue_tncn, khau_tru_khac)
        values (v_ky.ky_luong_id, v_phieu(i).nhan_vien_id, v_phieu(i).hop_dong_id,
                v_phieu(i).phong_ban_id, v_phieu(i).chuc_vu_id, v_phieu(i).luong_co_ban,
                v_phieu(i).gio_huong, v_phieu(i).tnct, v_phieu(i).giam_tru, v_phieu(i).gross,
                v_phieu(i).bh_nld, v_phieu(i).bh_nsdld, v_phieu(i).thue, v_phieu(i).khau_tru)
        returning phieu_luong_id into v_ids(i);
        i := v_phieu.next(i);
      end loop;

      for d in 1 .. v_dong.count loop
        insert into chi_tiet_phieu_luong (phieu_luong_id, loai_khoan_id, so_luong, don_gia, he_so,
                                          nhom_khoan_ap_dung, phan_chiu_thue, phat_sinh_id,
                                          khoan_nhan_vien_id, tang_ca_id)
        values (v_ids(v_dong(d).phieu_idx), v_dong(d).loai_khoan_id, v_dong(d).so_luong,
                v_dong(d).don_gia, v_dong(d).he_so, v_dong(d).nhom, v_dong(d).phan_chiu_thue,
                v_dong(d).phat_sinh_id, v_dong(d).khoan_nhan_vien_id, v_dong(d).tang_ca_id);
      end loop;

      -- Doi chieu truoc khi cong nhan ket qua (BR-26, QR-23)
      if so_phieu_lech(v_ky.ky_luong_id) > 0 then
        raise_application_error(-20506, 'Tổng phiếu lệch chi tiết sau khi tính (QR-23).');
      end if;
    end ghi_ket_qua;

  begin
    savepoint sp_tinh;
    pkg_chung.yeu_cau_vai_tro('PAYROLL');
    o_so_loi := 0;
    v_tu  := ngay_dau_thang(p_thang, p_nam);
    v_den := last_day(v_tu);

    -- TX-04: khoa dong ky, cho toi da 5 giay
    begin
      select * into v_ky from ky_luong where thang = p_thang and nam = p_nam for update wait 5;
    exception
      when no_data_found then
        raise_application_error(-20526, 'Chưa có kỳ lương ' || ten_ky(p_thang, p_nam) || '.');
      when e_ky_ban or e_ky_ban_cu then
        raise_application_error(-20502, 'Kỳ ' || ten_ky(p_thang, p_nam)
          || ' đang được xử lý ở phiên khác, thử lại sau (TX-04).');
    end;

    if v_ky.trang_thai = 'DA_KHOA' then
      raise_application_error(-20501, 'Kỳ ' || ten_ky(p_thang, p_nam) || ' đã khóa, không tính lại (BR-25).');
    elsif v_ky.trang_thai = 'MO' then
      raise_application_error(-20503, 'Kỳ ' || ten_ky(p_thang, p_nam)
        || ' chưa chốt công, chưa tính lương được (BR-21).');
    end if;

    -- Dau vao cap ky (loi -> nem ngoai le)
    v_cs_id := chinh_sach_cua_thang(v_tu, v_den);     -- ham private: goi ngoai SQL
    select * into v_cs from chinh_sach_luong where chinh_sach_id = v_cs_id;
    select count(*), sum(gio_quy_doi_luong) into v_so_ngay, v_hc
      from lich_lam_viec where ngay between v_tu and v_den;
    if v_so_ngay <> v_den - v_tu + 1 or nvl(v_hc, 0) = 0 then
      raise_application_error(-20525, 'Lịch làm việc tháng ' || ten_ky(p_thang, p_nam)
        || ' chưa đủ ngày hoặc tổng giờ chuẩn Hc = 0 (mục 9.2).');
    end if;

    -- Phat sinh da duyet cua nguoi khong lam viec trong ky: khong co phieu de ghi
    for s in (select n.ma_nhan_vien, s.phat_sinh_id
                from phat_sinh_luong s join nhan_vien n on n.nhan_vien_id = s.nhan_vien_id
               where s.ky_luong_id = v_ky.ky_luong_id and s.trang_thai_duyet = 'DA_DUYET'
                 and (n.ngay_vao_lam > v_den or nvl(n.ngay_nghi_viec, c_xa) < v_tu)) loop
      them_loi('PHAT_SINH_NGOAI_THOI_GIAN', s.ma_nhan_vien, 'phát sinh ' || s.phat_sinh_id);
    end loop;

    -- Buoc 1: tinh tung nguoi
    for n in (select * from nhan_vien
               where ngay_vao_lam <= v_den and nvl(ngay_nghi_viec, c_xa) >= v_tu
               order by ma_nhan_vien) loop
      if not tinh_mot_nguoi(n) then
        null;   -- loi da ghi vao danh sach; tiep tuc de tra du danh sach
      end if;
    end loop;

    if o_so_loi > 0 then
      -- Khong ghi gi: ket qua lan truoc (neu co) giu nguyen
      rollback to sp_tinh;
      return;
    end if;

    -- Buoc 2
    ghi_ket_qua;
    update ky_luong
       set trang_thai        = 'DA_TINH',
           phien_ban_da_tinh = phien_ban_dau_vao,
           chinh_sach_id     = v_cs.chinh_sach_id
     where ky_luong_id = v_ky.ky_luong_id;
  exception
    when others then
      rollback to sp_tinh;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_tinh_luong_ky;

  -- ===========================================================================
  -- SP-09 Khoa ky (TX-05)
  -- ===========================================================================
  procedure sp_khoa_ky_luong(
    p_thang in number,
    p_nam   in number)
  is
    v_ky    ky_luong%rowtype;
    v_tu    date;
    v_phieu number;
    v_nguoi number;
    v_lech  number;
  begin
    savepoint sp_khoa;
    pkg_chung.yeu_cau_vai_tro('PAYROLL');
    v_tu := ngay_dau_thang(p_thang, p_nam);

    begin
      select * into v_ky from ky_luong where thang = p_thang and nam = p_nam for update wait 5;
    exception
      when no_data_found then
        raise_application_error(-20526, 'Chưa có kỳ lương ' || ten_ky(p_thang, p_nam) || '.');
      when e_ky_ban or e_ky_ban_cu then
        raise_application_error(-20502, 'Kỳ ' || ten_ky(p_thang, p_nam) || ' đang được xử lý ở phiên khác.');
    end;

    if v_ky.trang_thai = 'DA_KHOA' then
      raise_application_error(-20501, 'Kỳ ' || ten_ky(p_thang, p_nam) || ' đã khóa.');
    end if;
    -- Kiem tra phien ban truoc trang thai de thong bao dung nguyen nhan (BR-24)
    if v_ky.phien_ban_da_tinh is not null and v_ky.phien_ban_da_tinh <> v_ky.phien_ban_dau_vao then
      raise_application_error(-20504, 'Đầu vào kỳ ' || ten_ky(p_thang, p_nam) || ' đã thay đổi sau lần tính '
        || '(phiên bản đầu vào ' || v_ky.phien_ban_dau_vao || ' ≠ đã tính ' || v_ky.phien_ban_da_tinh
        || '): phải tính lại trước khi khóa (BR-24).');
    end if;
    if v_ky.trang_thai <> 'DA_TINH' then
      raise_application_error(-20503, 'Kỳ ' || ten_ky(p_thang, p_nam) || ' ở trạng thái '
        || v_ky.trang_thai || ', chỉ khóa kỳ DA_TINH.');
    end if;

    select count(*) into v_phieu from phieu_luong where ky_luong_id = v_ky.ky_luong_id;
    v_nguoi := so_nguoi_trong_ky(v_tu, last_day(v_tu));
    if v_phieu <> v_nguoi then
      raise_application_error(-20505, 'Kỳ có ' || v_phieu || ' phiếu nhưng ' || v_nguoi
        || ' người làm việc trong kỳ.');
    end if;

    v_lech := so_phieu_lech(v_ky.ky_luong_id);
    if v_lech > 0 then
      raise_application_error(-20506, v_lech || ' phiếu có tổng lệch chi tiết (QR-23).');
    end if;

    update ky_luong
       set trang_thai = 'DA_KHOA', nguoi_khoa = pkg_chung.tai_khoan, thoi_diem_khoa = systimestamp
     where ky_luong_id = v_ky.ky_luong_id;
  exception
    when others then
      rollback to sp_khoa;
      pkg_chung.dich_loi(sqlcode, sqlerrm);
      raise;
  end sp_khoa_ky_luong;
end pkg_payroll;
/
show errors
