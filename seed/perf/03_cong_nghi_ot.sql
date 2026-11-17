-- =============================================================================
-- seed/perf/03_cong_nghi_ot.sql - Don nghi, OT, cham cong 04/2023 -> 03/2026
--
-- Moi (nhan vien, thang) trong thoi gian lam viec; nhan vien demo chi sinh den
-- 12/2025 (01-03/2026 da co du lieu demo). Gia tri "ngau nhien" tinh tat dinh tu
-- (nhan_vien_id, so thu tu thang) nen chay lai cho cung ket qua.
--   Don nghi (~52% so nguoi-thang): 1 hoac 2 ngay lien tiep, ca ngay hoac buoi sang;
--     loai: 8% om, 4% khong luong, con lai phep nam; 5% tu choi, 5% da rut.
--     Lich su duyet: GUI + DUYET/TU_CHOI/RUT. Nguoi duyet: U_HR01 (U_HR02 cho NV005).
--   OT (~70% so nguoi-thang): 2-4 gio sau 18:00 ngay lam viec, 10% sang thu Bay 4 gio;
--     ~4% bi tu choi. Khong roi vao ngay co don nghi.
--   Cham cong: moi ngay LAM_VIEC, gio = chuan - gio nghi da duyet (giong seed demo).
-- Khong co don/OT CHO_DUYET de cac ky chot cong duoc.
-- =============================================================================
set define off
whenever sqlerror exit failure rollback

declare
  type t_ngay  is table of date index by pls_integer;
  type t_thang is table of t_ngay index by pls_integer;
  v_lv     t_thang;           -- ngay LAM_VIEC theo thang (0..35)
  v_t7     t_thang;           -- thu Bay theo thang
  v_dau    date;
  v_tk_hr1 number;
  v_tk_hr2 number;
  v_nv_hr1 number;
  v_lnp_pn number;
  v_lnp_kl number;
  v_lnp_om number;

  v_ds     t_ngay;            -- ngay lam viec cua nguoi trong thang
  v_cnt    pls_integer;
  h        pls_integer;
  h2       pls_integer;
  k        pls_integer;
  k2       pls_integer;
  v_len    pls_integer;
  v_don    number;
  v_loai   number;
  v_tt     varchar2(10);
  v_duyet  number;
  v_tk_chu number;
  v_g      pls_integer;
  v_ot     date;
begin
  select tai_khoan_id, nhan_vien_id into v_tk_hr1, v_nv_hr1 from tai_khoan where oracle_username = 'U_HR01';
  select tai_khoan_id into v_tk_hr2 from tai_khoan where oracle_username = 'U_HR02';
  select loai_nghi_id into v_lnp_pn from loai_nghi_phep where ma_loai = 'PHEP_NAM';
  select loai_nghi_id into v_lnp_kl from loai_nghi_phep where ma_loai = 'KHONG_LUONG';
  select loai_nghi_id into v_lnp_om from loai_nghi_phep where ma_loai = 'OM';

  for m in 0 .. 35 loop
    v_dau := add_months(date '2023-04-01', m);
    select ngay bulk collect into v_ds from lich_lam_viec
     where ngay between v_dau and last_day(v_dau) and loai_ngay = 'LAM_VIEC' order by ngay;
    v_lv(m) := v_ds;
    select ngay bulk collect into v_ds from lich_lam_viec
     where ngay between v_dau and last_day(v_dau) and loai_ngay = 'NGHI_TUAN'
       and to_char(ngay, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN') = 'SAT' order by ngay;
    v_t7(m) := v_ds;
  end loop;

  for n in (select nv.nhan_vien_id as id, nv.ngay_vao_lam as vao, nvl(nv.ngay_nghi_viec, date '9999-12-31') as nghi,
                   case when regexp_like(nv.ma_nhan_vien, '^NV[1-3][0-9]{2}$') then 1 else 0 end as sinh_them,
                   t.tai_khoan_id as tk
              from nhan_vien nv join tai_khoan t on t.nhan_vien_id = nv.nhan_vien_id
             order by nv.nhan_vien_id) loop
    v_tk_chu := n.tk;
    v_duyet  := case when n.id = v_nv_hr1 then v_tk_hr2 else v_tk_hr1 end;
    for m in 0 .. case when n.sinh_them = 1 then 35 else 32 end loop
      -- ngay lam viec trong thang ma nguoi nay con lam
      v_ds.delete;
      v_cnt := 0;
      for i in 1 .. v_lv(m).count loop
        if v_lv(m)(i) between n.vao and n.nghi then
          v_cnt := v_cnt + 1;
          v_ds(v_cnt) := v_lv(m)(i);
        end if;
      end loop;
      continue when v_cnt < 3;

      -- ---------------------------------------------------------------- don nghi
      h     := mod(n.id * 37 + m * 101 + trunc(n.id * m / 3), 100);
      k     := 0;
      v_len := 0;
      if h < 52 then
        k     := mod(h * 7 + n.id, v_cnt) + 1;
        v_len := case when mod(h, 3) = 0 and k < v_cnt then 2 else 1 end;
        v_loai := case when mod(h, 25) in (0, 1) then v_lnp_om when mod(h, 25) = 2 then v_lnp_kl else v_lnp_pn end;
        v_tt  := case mod(n.id + m, 20) when 0 then 'TU_CHOI' when 1 then 'DA_RUT' else 'DA_DUYET' end;

        insert into don_nghi_phep (nhan_vien_id, loai_nghi_id, ly_do, trang_thai, thoi_diem_tao,
                                   nguoi_duyet, thoi_diem_duyet)
        values (n.id, v_loai,
                case v_loai when v_lnp_om then 'Ốm, có giấy khám bệnh' when v_lnp_kl then 'Việc gia đình'
                            else 'Nghỉ phép năm' end,
                v_tt, cast(v_ds(k) - 5 + 9/24 as timestamp),
                case when v_tt in ('DA_DUYET', 'TU_CHOI') then v_duyet end,
                case when v_tt in ('DA_DUYET', 'TU_CHOI') then cast(v_ds(k) - 4 + 14/24 as timestamp) end)
        returning don_nghi_id into v_don;

        for d in k .. k + v_len - 1 loop
          insert into chi_tiet_nghi_phep (don_nghi_id, ngay, buoi, nhan_vien_id, con_hieu_luc)
          values (v_don, v_ds(d), 'SANG', n.id, case when v_tt = 'DA_DUYET' then 1 else 0 end);
          if not (v_len = 1 and mod(h, 5) = 4) then          -- buoi sang: chi mot buoi
            insert into chi_tiet_nghi_phep (don_nghi_id, ngay, buoi, nhan_vien_id, con_hieu_luc)
            values (v_don, v_ds(d), 'CHIEU', n.id, case when v_tt = 'DA_DUYET' then 1 else 0 end);
          end if;
        end loop;

        insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, thoi_diem)
        values (v_don, 'GUI', v_tk_chu, cast(v_ds(k) - 5 + 9/24 as timestamp));
        if v_tt = 'DA_DUYET' then
          insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, thoi_diem)
          values (v_don, 'DUYET', v_duyet, cast(v_ds(k) - 4 + 14/24 as timestamp));
        elsif v_tt = 'TU_CHOI' then
          insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, thoi_diem, y_kien)
          values (v_don, 'TU_CHOI', v_duyet, cast(v_ds(k) - 4 + 14/24 as timestamp), 'Trùng lịch công việc của phòng');
        else
          insert into lich_su_duyet_nghi (don_nghi_id, hanh_dong, nguoi_xu_ly, thoi_diem)
          values (v_don, 'RUT', v_tk_chu, cast(v_ds(k) - 4 + 9/24 as timestamp));
        end if;
      end if;

      -- ---------------------------------------------------------------- OT
      h2 := mod(n.id * 53 + m * 17 + 7, 100);
      if h2 < 70 then
        v_ot := null;
        if mod(h2, 10) = 9 and v_t7(m).count > 0 then
          v_ot := v_t7(m)(mod(n.id, v_t7(m).count) + 1);
          if v_ot not between n.vao and n.nghi then v_ot := null; end if;
          v_g := 4;
          if v_ot is not null then
            insert into dang_ky_tang_ca (nhan_vien_id, bat_dau, ket_thuc, so_gio_duoc_duyet, ly_do,
                                         trang_thai, nguoi_duyet, thoi_diem_duyet)
            values (n.id, cast(v_ot + 8/24 as timestamp), cast(v_ot + 12/24 as timestamp),
                    case when mod(h2, 23) = 0 then null else v_g end,
                    'Xử lý công việc tồn đọng cuối tuần',
                    case when mod(h2, 23) = 0 then 'TU_CHOI' else 'DA_DUYET' end,
                    v_duyet, cast(v_ot - 1 + 16/24 as timestamp));
          end if;
        else
          k2 := mod(h2 * 3 + n.id * 5, v_cnt) + 1;
          if k > 0 and k2 between k and k + v_len - 1 then
            k2 := mod(k + v_len + 1, v_cnt) + 1;               -- tranh ngay nghi
          end if;
          if not (k > 0 and k2 between k and k + v_len - 1) then
            v_ot := v_ds(k2);
            v_g  := 2 + mod(h2, 3);
            insert into dang_ky_tang_ca (nhan_vien_id, bat_dau, ket_thuc, so_gio_duoc_duyet, ly_do,
                                         trang_thai, nguoi_duyet, thoi_diem_duyet)
            values (n.id, cast(v_ot + 18/24 as timestamp), cast(v_ot + (18 + v_g)/24 as timestamp),
                    case when mod(h2, 23) = 0 then null else v_g end,
                    'Hoàn thành công việc gấp theo kế hoạch phòng',
                    case when mod(h2, 23) = 0 then 'TU_CHOI' else 'DA_DUYET' end,
                    v_duyet, cast(v_ot - 1 + 16/24 as timestamp));
          end if;
        end if;
      end if;
    end loop;
  end loop;
  commit;
end;
/

-- Cham cong: moi ngay LAM_VIEC trong thoi gian lam viec, tru gio nghi da duyet
insert into cham_cong (nhan_vien_id, ngay, so_gio_lam_thuc_te, trang_thai_xac_nhan, nguoi_xac_nhan)
select n.nhan_vien_id, l.ngay,
       l.so_gio_chuan - nvl(np.gio_nghi, 0)
         - case when np.gio_nghi is null and mod(n.nhan_vien_id, 10) = 7
                 and to_char(l.ngay, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN') = 'MON' then 0.5 else 0 end,
       'DA_XAC_NHAN', (select tai_khoan_id from tai_khoan where oracle_username = 'U_HR01')
  from nhan_vien n
  join lich_lam_viec l
    on l.loai_ngay = 'LAM_VIEC'
   and l.ngay between date '2023-04-01' and date '2026-03-31'
   and l.ngay >= n.ngay_vao_lam
   and (n.ngay_nghi_viec is null or l.ngay <= n.ngay_nghi_viec)
  left join (
    select c.nhan_vien_id, c.ngay,
           sum(case c.buoi when 'SANG' then l2.gio_ket_thuc_sang - l2.gio_bat_dau_sang
                           else l2.gio_ket_thuc_chieu - l2.gio_bat_dau_chieu end) as gio_nghi
      from chi_tiet_nghi_phep c
      join don_nghi_phep d on d.don_nghi_id = c.don_nghi_id and d.trang_thai = 'DA_DUYET'
      join lich_lam_viec l2 on l2.ngay = c.ngay
     group by c.nhan_vien_id, c.ngay) np
    on np.nhan_vien_id = n.nhan_vien_id and np.ngay = l.ngay
 where not exists (select 1 from cham_cong c where c.nhan_vien_id = n.nhan_vien_id and c.ngay = l.ngay);

commit;
