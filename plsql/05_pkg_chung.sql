-- =============================================================================
-- 05_pkg_chung.sql - Tien ich dung chung cho cac package nghiep vu + FN-07
--
-- pkg_chung KHONG cap cho role hay HRM_APP; chi package cung schema goi.
--   * yeu_cau_vai_tro : lop chan nghiep vu (muc 8.2) - doc vai tro tu HRM_CTX
--   * dich_loi        : doi loi rang buoc Oracle thanh loi nghiep vu de giao dien
--                       hien thong bao de hieu, khong lo ten bang (IT-03)
--   * ghi_audit       : TR-01 goi; ghi trong cung transaction (BR-34)
--
-- Ma loi chung: -20003 chua co danh tinh phien; -20009 khong du vai tro;
--               -209xx loi du lieu chung.
-- Ma loi theo module (dac ta muc 7.1): -200xx tai khoan, -201xx to chuc,
-- -202xx ho so, -203xx cong/OT, -204xx phep, -205xx luong, -206xx quyet dinh.
-- =============================================================================

create or replace package pkg_chung
  authid definer
as
  c_ngay_xa constant date := date '9999-12-31';   -- thay NULL "chua ket thuc"

  -- Tai khoan / nhan vien cua phien; nem -20003 neu chua co danh tinh
  function tai_khoan return number;
  function nhan_vien return number;

  -- Yeu cau phien co it nhat mot vai tro trong danh sach, vd 'HR' hoac 'HR,PAYROLL'
  procedure yeu_cau_vai_tro(p_ds_vai_tro in varchar2);

  -- Khoa dong cac KY_LUONG giao khoang [p_tu, p_den] theo (nam, thang) tang dan
  -- (muc 8.5) va yeu cau tat ca con MO; nguoc lai nem -20301. Moi duong ghi cong,
  -- nghi, OT, lich goi thu tuc nay truoc tien nen sp_chot_cong (cung khoa dong ky)
  -- khong bi du lieu moi chen vao giua luc kiem tra (TX-07).
  procedure khoa_ky_mo(p_tu in date, p_den in date);

  -- Neu loi la vi pham rang buoc: nem loi nghiep vu tuong ung.
  -- Neu khong: tra ve binh thuong de noi goi RAISE lai loi goc.
  procedure dich_loi(p_sqlcode in number, p_sqlerrm in varchar2);

  -- Ghi mot dong NHAT_KY_HE_THONG (thao tac suy ra tu cu/moi)
  procedure ghi_audit(
    p_doi_tuong in varchar2,
    p_khoa      in varchar2,
    p_cu        in json_object_t,
    p_moi       in json_object_t);
end pkg_chung;
/
show errors

create or replace package body pkg_chung
as
  function tai_khoan return number
  is
    v number := fn_tai_khoan_hien_tai;
  begin
    if v is null then
      raise_application_error(-20003, 'Chưa có danh tính phiên hoặc tài khoản đã bị khóa.');
    end if;
    return v;
  end tai_khoan;

  function nhan_vien return number
  is
    v number;
  begin
    v := tai_khoan;   -- bao dam co phien truoc
    v := fn_nhan_vien_hien_tai;
    if v is null then
      raise_application_error(-20003, 'Tài khoản phiên hiện tại không gắn với nhân viên.');
    end if;
    return v;
  end nhan_vien;

  procedure yeu_cau_vai_tro(p_ds_vai_tro in varchar2)
  is
    v_tk number := tai_khoan;
  begin
    for i in 1 .. regexp_count(p_ds_vai_tro, ',') + 1 loop
      if fn_co_vai_tro(trim(regexp_substr(p_ds_vai_tro, '[^,]+', 1, i))) then
        return;
      end if;
    end loop;
    raise_application_error(-20009, 'Tài khoản không có quyền thực hiện chức năng này (cần vai trò '
                                    || p_ds_vai_tro || ').');
  end yeu_cau_vai_tro;

  procedure khoa_ky_mo(p_tu in date, p_den in date)
  is
  begin
    for k in (select ky_luong_id, thang, nam, trang_thai
                from ky_luong
               where to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD') <= trunc(nvl(p_den, p_tu))
                 and last_day(to_date(nam || '-' || thang || '-01', 'YYYY-MM-DD')) >= trunc(p_tu)
               order by nam, thang
                 for update)
    loop
      if k.trang_thai <> 'MO' then
        raise_application_error(-20301, 'Tháng ' || lpad(k.thang, 2, '0') || '/' || k.nam
          || ' đã chốt công (' || k.trang_thai || '): không thay đổi công, nghỉ, OT, lịch.');
      end if;
    end loop;
  end khoa_ky_mo;

  procedure dich_loi(p_sqlcode in number, p_sqlerrm in varchar2)
  is
    v_ten varchar2(128);
    v_ma  number;
    v_tb  varchar2(400);
  begin
    if p_sqlcode not in (-1, -1400, -2290, -2291, -2292, -11534, -12899) then
      return;
    end if;

    -- Ten rang buoc nam trong ngoac: (HRM_OWNER.TEN) ; ORA-01400/12899 la ten cot
    v_ten := regexp_substr(p_sqlerrm, '\("?HRM_OWNER"?\."?([A-Z0-9_$#]+)"?', 1, 1, null, 1);

    case
      -- Tai khoan
      when v_ten = 'IX02_TAI_KHOAN_TEN'        then v_ma := -20010; v_tb := 'Tên đăng nhập đã tồn tại (không phân biệt hoa/thường).';
      when v_ten = 'UK_TAI_KHOAN_NV'           then v_ma := -20011; v_tb := 'Nhân viên đã có tài khoản.';
      when v_ten = 'PK_TAI_KHOAN_VAI_TRO'      then v_ma := -20012; v_tb := 'Tài khoản đã có vai trò này.';
      when v_ten = 'UK_TAI_KHOAN_ORACLE_USER'  then v_ma := -20016; v_tb := 'User Oracle đã được ánh xạ cho tài khoản khác.';
      when v_ten = 'CK_TAI_KHOAN_TEN'          then v_ma := -20017; v_tb := 'Tên đăng nhập gồm 3–50 ký tự chữ, số, dấu chấm, gạch dưới.';
      when v_ten = 'CK_TAI_KHOAN_MAT_KHAU'     then v_ma := -20006; v_tb := 'Mật khẩu phải là chuỗi băm bcrypt hoặc Argon2.';
      -- To chuc
      when v_ten = 'UK_PHONG_BAN_MA'           then v_ma := -20101; v_tb := 'Mã phòng ban đã tồn tại.';
      when v_ten = 'UK_CHUC_VU_MA'             then v_ma := -20102; v_tb := 'Mã chức vụ đã tồn tại.';
      when v_ten = 'CK_D_MA'                   then v_ma := -20107; v_tb := 'Mã chỉ gồm chữ in hoa A–Z, số 0–9 và dấu gạch dưới (tối đa 20 ký tự).';
      when v_ten = 'UK_QTCT_NV_NGAY'           then v_ma := -20215; v_tb := 'Nhân viên đã có phân công bắt đầu cùng ngày.';
      -- Ho so, hop dong
      when v_ten = 'UK_NHAN_VIEN_MA'           then v_ma := -20201; v_tb := 'Mã nhân viên đã tồn tại.';
      when v_ten = 'UK_NHAN_VIEN_DINH_DANH'    then v_ma := -20202; v_tb := 'Số định danh đã thuộc về nhân viên khác.';
      when v_ten = 'UK_NHAN_VIEN_MST'          then v_ma := -20203; v_tb := 'Mã số thuế đã thuộc về nhân viên khác.';
      when v_ten like 'CK_NHAN_VIEN%'          then v_ma := -20204; v_tb := 'Thông tin hồ sơ không hợp lệ (' || v_ten || ').';
      when v_ten = 'CK_HOP_DONG_NGAY'          then v_ma := -20206; v_tb := 'Ngày kết thúc hợp đồng phải sau ngày bắt đầu.';
      when v_ten = 'CK_MLHD_NGAY_1'            then v_ma := -20207; v_tb := 'Mức lương mới phải có hiệu lực từ ngày 1 của tháng (BR-39).';
      when v_ten = 'CK_NPT_NGAY'               then v_ma := -20209; v_tb := 'Khoảng giảm trừ không hợp lệ: ngày kết thúc trước ngày bắt đầu.';
      when v_ten = 'UK_HOP_DONG_SO'            then v_ma := -20211; v_tb := 'Số hợp đồng đã tồn tại.';
      when v_ten = 'CK_MLHD_LUONG'             then v_ma := -20212; v_tb := 'Lương cơ bản phải lớn hơn 0.';
      when v_ten = 'UK_MLHD_HD_TU_NGAY'        then v_ma := -20213; v_tb := 'Hợp đồng đã có mức lương bắt đầu cùng ngày.';
      when v_ten like 'CK_NPT%'                then v_ma := -20214; v_tb := 'Thông tin người phụ thuộc không hợp lệ (' || v_ten || ').';
      -- Cong, OT, lich
      when v_ten = 'PK_LICH_LAM_VIEC'          then v_ma := -20302; v_tb := 'Ngày này đã có lịch làm việc.';
      when v_ten like 'CK_LICH%'               then v_ma := -20317; v_tb := 'Lịch làm việc không hợp lệ (' || v_ten || ').';
      when v_ten = 'UK_CHAM_CONG_NV_NGAY'      then v_ma := -20304; v_tb := 'Nhân viên đã có bản ghi công ngày này.';
      when v_ten = 'CK_CC_GIO'                 then v_ma := -20306; v_tb := 'Số giờ công không hợp lệ.';
      when v_ten = 'CK_OT_KHOANG'              then v_ma := -20308; v_tb := 'Giờ kết thúc OT phải sau giờ bắt đầu.';
      when v_ten = 'CK_OT_BAN_NGAY'            then v_ma := -20309; v_tb := 'OT phải trong cùng ngày, từ 06:00 đến 22:00 (BR-13).';
      when v_ten = 'CK_OT_GIO_DUYET'           then v_ma := -20316; v_tb := 'Giờ duyệt vượt độ dài khoảng đăng ký (BR-14).';
      when v_ten in ('FK_CC_NGAY', 'FK_OT_NGAY', 'FK_CTNP_NGAY')
                                               then v_ma := -20318; v_tb := 'Ngày chưa có trong lịch làm việc.';
      -- Phep
      when v_ten = 'PK_HAN_MUC_PHEP_NAM'       then v_ma := -20401; v_tb := 'Nhân viên đã có hạn mức phép của năm này.';
      when v_ten like 'CK_HMPN%'               then v_ma := -20412; v_tb := 'Hạn mức phép không hợp lệ (' || v_ten || ').';
      when v_ten = 'IX14_CTNP_BUOI_HIEU_LUC'   then v_ma := -20404; v_tb := 'Trùng buổi với đơn nghỉ đang chờ hoặc đã duyệt (BR-16).';
      when v_ten = 'CK_LSDN_LY_DO'             then v_ma := -20408; v_tb := 'Từ chối đơn phải ghi lý do.';
      -- Luong
      when v_ten = 'UK_KY_LUONG_NAM_THANG'     then v_ma := -20510; v_tb := 'Kỳ lương của tháng/năm này đã tồn tại (BR-19).';
      when v_ten in ('CK_KL_THANG', 'CK_KL_NAM') then v_ma := -20511; v_tb := 'Kỳ không hợp lệ: tháng 1–12, năm 2000–2100.';
      when v_ten = 'CK_KL_NGAY_TRA'            then v_ma := -20512; v_tb := 'Ngày chi trả dự kiến phải thuộc tháng của kỳ.';
      when v_ten = 'UK_PS_KHEN_THUONG'         then v_ma := -20507; v_tb := 'Quyết định khen thưởng đã chuyển sang lương (BR-30).';
      when v_ten = 'CK_PS_SO_TIEN'             then v_ma := -20522; v_tb := 'Số tiền phát sinh phải lớn hơn 0.';
      when v_ten = 'CK_PS_KHONG_TU_DUYET'      then v_ma := -20524; v_tb := 'Không duyệt phát sinh do chính mình lập (BR-15).';
      when v_ten = 'UK_PHIEU_KY_NV'            then v_ma := -20502; v_tb := 'Phiếu của nhân viên trong kỳ đã tồn tại: kỳ đang được tính ở phiên khác.';
      when v_ten = 'CK_PHIEU_NET'              then v_ma := -20533; v_tb := 'Net âm: kiểm tra khấu trừ của nhân viên (BR-26).';
      when v_ten in ('PK_HE_SO_OT', 'CK_HSOT_LOAI_NGAY', 'CK_HSOT_HE_SO')
                                               then v_ma := -20517; v_tb := 'Hệ số OT không hợp lệ hoặc trùng loại ngày (' || v_ten || ').';
      when v_ten in ('PK_TY_LE_BAO_HIEM', 'CK_TLBH_LOAI', 'CK_TLBH_SAN_TRAN')
                                               then v_ma := -20516; v_tb := 'Tỷ lệ bảo hiểm không hợp lệ hoặc trùng loại (' || v_ten || ').';
      when v_ten in ('PK_BAC_THUE_TNCN', 'UK_BTT_CAN_DUOI', 'CK_BTT_BAC', 'CK_BTT_CAN')
                                               then v_ma := -20515; v_tb := 'Biểu thuế không hợp lệ: trùng bậc/cận hoặc cận trên ≤ cận dưới (' || v_ten || ').';
      when v_ten like 'CK_CSL%'                then v_ma := -20531; v_tb := 'Chính sách không hợp lệ: hiệu lực từ ngày 1 đến cuối tháng, hạn mức OT ngày ≤ tháng ≤ năm (' || v_ten || ').';
      when v_ten like 'CK_KLNV%'               then v_ma := -20531; v_tb := 'Phụ cấp không hợp lệ: mức tiền > 0, ngày kết thúc sau ngày bắt đầu (' || v_ten || ').';
      -- Quyet dinh
      when v_ten = 'UK_KT_SO_QUYET_DINH'       then v_ma := -20601; v_tb := 'Số quyết định khen thưởng đã tồn tại.';
      when v_ten = 'CK_KT_SO_TIEN'             then v_ma := -20602; v_tb := 'Thưởng tiền phải lớn hơn 0; hình thức khác không ghi số tiền.';
      when v_ten = 'CK_KT_KHONG_TU_DUYET'      then v_ma := -20604; v_tb := 'Không được duyệt quyết định do chính mình tạo (BR-15).';
      when v_ten = 'UK_KL_SO_QUYET_DINH'       then v_ma := -20606; v_tb := 'Số quyết định kỷ luật đã tồn tại.';
      when v_ten = 'CK_KL_KHONG_TU_DUYET'      then v_ma := -20607; v_tb := 'Người phê duyệt kỷ luật phải khác người lập.';
      -- Chung
      else
        case p_sqlcode
          when -1400  then v_ma := -20901; v_tb := 'Thiếu thông tin bắt buộc (' || v_ten || ').';
          when -12899 then v_ma := -20902; v_tb := 'Giá trị vượt độ dài cho phép.';
          when -2291  then v_ma := -20903; v_tb := 'Dữ liệu tham chiếu không tồn tại (' || v_ten || ').';
          when -2292  then v_ma := -20904; v_tb := 'Không xóa được vì dữ liệu đang được tham chiếu (BR-33).';
          else             v_ma := -20900; v_tb := 'Dữ liệu vi phạm ràng buộc ' || nvl(v_ten, '') || '.';
        end case;
    end case;

    raise_application_error(v_ma, v_tb);
  end dich_loi;

  procedure ghi_audit(
    p_doi_tuong in varchar2,
    p_khoa      in varchar2,
    p_cu        in json_object_t,
    p_moi       in json_object_t)
  is
    v_cu       clob;
    v_moi      clob;
    v_thao_tac varchar2(6);
  begin
    -- JSON_OBJECT_T la kieu PL/SQL: chuyen sang CLOB truoc, khong dua vao cau SQL (ORA-40573)
    if p_cu  is not null then v_cu  := p_cu.to_clob;  end if;
    if p_moi is not null then v_moi := p_moi.to_clob; end if;
    v_thao_tac := case when p_cu is null then 'INSERT' when p_moi is null then 'DELETE' else 'UPDATE' end;

    insert into nhat_ky_he_thong (tai_khoan_id, doi_tuong, khoa_ban_ghi, thao_tac, gia_tri_cu, gia_tri_moi)
    values (fn_tai_khoan_hien_tai, p_doi_tuong, p_khoa, v_thao_tac, json(v_cu), json(v_moi));
  end ghi_audit;
end pkg_chung;
/
show errors

-- -----------------------------------------------------------------------------
-- FN-07: truong phong cua mot phong tai mot ngay = nguoi giu chuc vu LA_QUAN_LY
-- trong phong o ngay do (nguon su that duy nhat, khong co cot TRUONG_PHONG_ID).
-- -----------------------------------------------------------------------------
create or replace function fn_truong_phong_tai_ngay(
  p_phong_ban_id in number,
  p_ngay         in date)
  return number
  authid definer
is
  v_nv number;
begin
  select q.nhan_vien_id into v_nv
    from qua_trinh_cong_tac q
    join chuc_vu c on c.chuc_vu_id = q.chuc_vu_id
   where q.phong_ban_id = p_phong_ban_id
     and c.la_quan_ly
     and trunc(p_ngay) between q.ngay_bat_dau and nvl(q.ngay_ket_thuc, date '9999-12-31')
   fetch first 1 row only;
  return v_nv;
exception
  when no_data_found then
    return null;
end;
/
show errors
