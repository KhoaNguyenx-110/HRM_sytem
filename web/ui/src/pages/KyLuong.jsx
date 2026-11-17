// Kỳ lương: HR chốt công; Payroll tạo kỳ, tính, khóa, lập phát sinh; xem bảng lương / công.
// Chuỗi trạng thái MO -> CHOT_CONG -> DA_TINH -> DA_KHOA do CSDL giữ; thanh tiến trình
// chỉ phản ánh trạng thái đọc về.
import { useMemo, useState } from 'react'
import { api } from '../api'
import { useAuth } from '../auth'
import { Bang, Chip, HopThoai, KhungTai, The, Trang, TruongNhap, useTai, useThaoTac } from '../ui/chung'
import { dinhDangDong, dinhDangSo, dinhDangTien, kyLuong } from '../ui/dinh_dang'
import { PhieuChiTiet } from './PhieuLuong'

const BUOC = ['MO', 'CHOT_CONG', 'DA_TINH', 'DA_KHOA']
const TEN_BUOC = ['Mở', 'Chốt công', 'Đã tính', 'Khóa']

function TienTrinh({ tt }) {
  const i = BUOC.indexOf(tt)
  return (
    <div className="tien-trinh" aria-label={`Bước ${i + 1}/4`}>
      <div className="tien-trinh-ray">
        <div className="tien-trinh-dung" style={{ width: `${(i / 3) * 100}%` }} />
      </div>
      <div className="tien-trinh-buoc">
        {TEN_BUOC.map((t, k) => <span key={t} className={k <= i ? 'xong' : ''}>{t}</span>)}
      </div>
    </div>
  )
}

export default function KyLuong() {
  const { co } = useAuth()
  const laPay = co('PAYROLL'), laHR = co('HR')
  const ky = useTai(() => api.get('/danh-muc/KY_LUONG'))
  const [chon, setChon] = useState(null)
  const [hop, setHop] = useState(null)
  const [ketQua, setKetQua] = useState(null)   // danh sách lỗi của lần chốt / tính
  const { dang, chay } = useThaoTac()

  const k = useMemo(() => {
    const ds = ky.duLieu ?? []
    return ds.find((x) => `${x.nam}-${x.thang}` === chon) ?? ds[0]
  }, [ky.duLieu, chon])

  const hanhDong = (duongDan, ten) => chay(() => api.post(`/ky-luong/${k.nam}/${k.thang}/${duongDan}`))
    .then((kq) => {
      if (kq?.so_loi > 0) setKetQua({ ten, ...kq })
      else ky.taiLai()
      return kq
    }).catch(() => {})

  return (
    <Trang tieuDe="Kỳ lương" hanhDong={laPay && <>
      <button className="nut nut-nhat" onClick={() => setHop('ct')}>Chuyển thưởng</button>
      <button className="nut nut-nhat" onClick={() => setHop('ps')}>Lập phát sinh</button>
      <button className="nut" onClick={() => setHop('tao')}>+ Tạo kỳ</button></>}>
      <KhungTai tt={ky} rong="Chưa có kỳ lương.">
        {(ds) => (
          <div className="luoi-2 hep-trai">
            <The tieuDe="Các kỳ">
              <ul className="ds-chon">
                {ds.map((x) => (
                  <li key={`${x.nam}-${x.thang}`}>
                    <button className={x === k ? 'dang-chon' : ''} onClick={() => setChon(`${x.nam}-${x.thang}`)}>
                      <span>Kỳ {kyLuong(x.thang, x.nam)}</span><Chip ma={x.trang_thai} />
                    </button>
                  </li>
                ))}
              </ul>
            </The>
            <div className="cot">
              <The tieuDe={`Kỳ ${kyLuong(k.thang, k.nam)}`}
                phai={k.can_tinh_lai === 1 && k.trang_thai === 'DA_TINH' && <Chip mau="vang">Dữ liệu đổi – cần tính lại</Chip>}>
                <TienTrinh tt={k.trang_thai} />
                <div className="hang-nut trai">
                  {laHR && k.trang_thai === 'MO' &&
                    <button className="nut" disabled={dang} onClick={() => hanhDong('chot-cong', 'Chốt công')}>Chốt công</button>}
                  {laPay && ['CHOT_CONG', 'DA_TINH'].includes(k.trang_thai) &&
                    <button className="nut" disabled={dang} onClick={() => hanhDong('tinh', 'Tính lương')}>
                      {k.trang_thai === 'DA_TINH' ? 'Tính lại' : 'Tính lương'}</button>}
                  {laPay && k.trang_thai === 'DA_TINH' &&
                    <button className="nut nut-nhat" disabled={dang} onClick={() => setHop('khoa')}>Khóa kỳ</button>}
                  {dang && <span className="xoay nho" aria-label="Đang xử lý" />}
                  {!laHR && k.trang_thai === 'MO' && <span className="goi-y">Chờ phòng Nhân sự chốt công.</span>}
                  {!laPay && ['CHOT_CONG', 'DA_TINH'].includes(k.trang_thai) && <span className="goi-y">Đã chốt công, chờ bộ phận Tiền lương tính và khóa kỳ.</span>}
                  {k.trang_thai === 'DA_KHOA' && <span className="goi-y">Kỳ đã khóa: phiếu lương không thay đổi được nữa.</span>}
                </div>
              </The>
              {laPay && k.trang_thai !== 'MO' && k.trang_thai !== 'CHOT_CONG'
                ? <BangLuong key={`${k.nam}-${k.thang}-${k.trang_thai}`} nam={k.nam} thang={k.thang} />
                : <CongThang key={`${k.nam}-${k.thang}`} nam={k.nam} thang={k.thang} />}
            </div>
          </div>
        )}
      </KhungTai>

      <HopThoai mo={hop === 'khoa'} dong={() => setHop(null)} tieuDe="Khóa kỳ lương" rong={440}>
        <p>Sau khi khóa, phiếu lương kỳ {k && kyLuong(k.thang, k.nam)} không sửa được nữa và nhân viên sẽ xem được phiếu của mình.</p>
        <div className="hang-nut">
          <button className="nut nut-nhat" onClick={() => setHop(null)}>Hủy</button>
          <button className="nut" onClick={() => { setHop(null); hanhDong('khoa', 'Khóa kỳ') }}>Khóa kỳ</button>
        </div>
      </HopThoai>
      <TaoKy mo={hop === 'tao'} dong={() => setHop(null)} xong={ky.taiLai} />
      <PhatSinh mo={hop === 'ps'} dong={() => setHop(null)} />
      <ChuyenThuong mo={hop === 'ct'} dong={() => setHop(null)} ky={k} xong={ky.taiLai} />
      <HopThoai mo={!!ketQua} dong={() => setKetQua(null)} tieuDe={`${ketQua?.ten}: ${ketQua?.so_loi} lỗi`}>
        <p>Thao tác chưa hoàn tất. Sửa các lỗi sau rồi thực hiện lại:</p>
        <ul className="ds-loi">{ketQua?.ds_loi.map((l, i) => <li key={i}>{l}</li>)}</ul>
      </HopThoai>
    </Trang>
  )
}

function BangLuong({ nam, thang }) {
  const tt = useTai(() => api.get(`/ky-luong/${nam}/${thang}/bang-luong`), [nam, thang])
  const [phieu, setPhieu] = useState(null)
  const xem = async (d) => setPhieu(await api.get(`/ky-luong/${nam}/${thang}/phieu/${d.ma_nhan_vien}`))
  return (
    <The tieuDe="Bảng lương">
      <KhungTai tt={tt} rong="Kỳ chưa có phiếu lương.">
        {(ds) => {
          const tong = (k) => ds.reduce((s, d) => s + (d[k] ?? 0), 0)
          return (
            <>
              <div className="o-so">
                <div><span>Nhân viên</span><b>{ds.length}</b></div>
                <div><span>Tổng thu nhập</span><b>{dinhDangTien(tong('tong_gross'))}</b></div>
                <div><span>Tổng thực lĩnh</span><b>{dinhDangTien(tong('tong_net'))}</b></div>
                <div><span>Chi phí doanh nghiệp</span><b>{dinhDangTien(tong('chi_phi_doanh_nghiep'))}</b></div>
              </div>
              <Bang dong={ds} khoa={(d) => d.ma_nhan_vien} khiChon={xem} cot={[
                { k: 'ma_nhan_vien', t: 'Mã' }, { k: 'ho_ten', t: 'Họ tên' }, { k: 'ten_phong_ban', t: 'Phòng' },
                { k: 'tong_gross', t: 'Thu nhập (đ)', phai: true, dinhDang: dinhDangDong },
                { k: 'bao_hiem_nld', t: 'Bảo hiểm (đ)', phai: true, dinhDang: dinhDangDong },
                { k: 'thue_tncn', t: 'Thuế (đ)', phai: true, dinhDang: dinhDangDong },
                { k: 'tong_net', t: 'Thực lĩnh (đ)', phai: true, dinhDang: dinhDangDong },
              ]} />
            </>
          )
        }}
      </KhungTai>
      <HopThoai mo={!!phieu} dong={() => setPhieu(null)} tieuDe={phieu ? `${phieu.ho_ten} – ${phieu.ma_nhan_vien}` : ''} rong={640}>
        {phieu && <PhieuChiTiet p={phieu} />}
      </HopThoai>
    </The>
  )
}

function CongThang({ nam, thang }) {
  const tt = useTai(() => api.get(`/cong?nam=${nam}&thang=${thang}`), [nam, thang])
  return (
    <The tieuDe="Công tháng">
      <KhungTai tt={tt} rong="Không có dữ liệu công trong phạm vi bạn được xem.">
        {(ds) => <Bang dong={ds} khoa={(d) => d.ma_nhan_vien} cot={[
          { k: 'ma_nhan_vien', t: 'Mã' }, { k: 'ho_ten', t: 'Họ tên' }, { k: 'ma_phong_ban', t: 'Phòng' },
          { k: 'so_ngay_co_cong', t: 'Ngày công', phai: true, dinhDang: (v) => dinhDangSo(v, 1) },
          { k: 'ngay_nghi_huong_luong', t: 'Nghỉ có lương', phai: true, dinhDang: (v) => dinhDangSo(v, 1) },
          { k: 'ngay_nghi_khong_luong', t: 'Nghỉ không lương', phai: true, dinhDang: (v) => dinhDangSo(v, 1) },
          { k: 'gio_huong_luong', t: 'Giờ hưởng lương', phai: true, dinhDang: (v) => dinhDangSo(v, 1) },
          { k: 'ot', t: 'OT (giờ)', phai: true, ve: (d) => dinhDangSo((d.ot_ngay_thuong ?? 0) + (d.ot_nghi_tuan ?? 0) + (d.ot_le ?? 0), 1) },
        ]} />}
      </KhungTai>
    </The>
  )
}

function TaoKy({ mo, dong, xong }) {
  const nay = new Date()
  const [f, setF] = useState({ thang: nay.getMonth() + 1, nam: nay.getFullYear() })
  const { dang, chay } = useThaoTac()
  return (
    <HopThoai mo={mo} dong={dong} tieuDe="Tạo kỳ lương" rong={380}>
      <form className="bieu-mau" onSubmit={(e) => {
        e.preventDefault()
        chay(() => api.post('/ky-luong', { thang: Number(f.thang), nam: Number(f.nam) }), 'Đã tạo kỳ.')
          .then(() => { dong(); xong() }).catch(() => {})
      }}>
        <div className="hang">
          <TruongNhap nhan="Tháng"><input type="number" min="1" max="12" required value={f.thang}
            onChange={(e) => setF({ ...f, thang: e.target.value })} /></TruongNhap>
          <TruongNhap nhan="Năm"><input type="number" min="2000" max="2100" required value={f.nam}
            onChange={(e) => setF({ ...f, nam: e.target.value })} /></TruongNhap>
        </div>
        <div className="hang-nut"><button className="nut" disabled={dang}>Tạo</button></div>
      </form>
    </HopThoai>
  )
}

function PhatSinh({ mo, dong }) {
  const khoan = useTai(() => (mo ? api.get('/danh-muc/LOAI_KHOAN_LUONG') : Promise.resolve([])), [mo])
  const [f, setF] = useState({ nam: new Date().getFullYear() })
  const { dang, chay } = useThaoTac()
  const doi = (k) => (e) => setF({ ...f, [k]: e.target.value })
  // Khoản lập tay được: thu nhập thưởng/điều chỉnh và khấu trừ (không lập BH, thuế, lương công)
  const dsKhoan = (khoan.duLieu ?? []).filter((k) => ['THUONG', 'DIEU_CHINH_TANG', 'DIEU_CHINH_GIAM', 'KHAU_TRU'].includes(k.ma_khoan))
  return (
    <HopThoai mo={mo} dong={dong} tieuDe="Lập phát sinh lương">
      <form className="bieu-mau" onSubmit={(e) => {
        e.preventDefault()
        chay(() => api.post('/phat-sinh', { ...f, thang: Number(f.thang), nam: Number(f.nam), so_tien: Number(f.so_tien) }),
          'Đã lập phát sinh – chờ HR duyệt.').then(() => { dong(); setF({ nam: f.nam }) }).catch(() => {})
      }}>
        <div className="hang">
          <TruongNhap nhan="Mã nhân viên"><input required onChange={doi('ma_nhan_vien')} /></TruongNhap>
          <TruongNhap nhan="Tháng"><input type="number" min="1" max="12" required onChange={doi('thang')} /></TruongNhap>
          <TruongNhap nhan="Năm"><input type="number" required value={f.nam} onChange={doi('nam')} /></TruongNhap>
        </div>
        <div className="hang">
          <TruongNhap nhan="Khoản"><select required defaultValue="" onChange={doi('ma_khoan')}>
            <option value="" disabled>Chọn…</option>
            {dsKhoan.map((k) => <option key={k.ma_khoan} value={k.ma_khoan}>{k.ten_khoan}</option>)}
          </select></TruongNhap>
          <TruongNhap nhan="Số tiền (đ)"><input type="number" min="1" required onChange={doi('so_tien')} /></TruongNhap>
        </div>
        <TruongNhap nhan="Căn cứ"><input required onChange={doi('can_cu')} /></TruongNhap>
        <div className="hang-nut"><button className="nut" disabled={dang}>Lập phát sinh</button></div>
      </form>
    </HopThoai>
  )
}

// Quyết định khen thưởng bằng tiền ĐÃ DUYỆT -> phát sinh THUONG của kỳ (SP-10b)
function ChuyenThuong({ mo, dong, ky, xong }) {
  const [soQd, setSoQd] = useState('')
  const { dang, chay } = useThaoTac()
  if (!ky) return null
  return (
    <HopThoai mo={mo} dong={dong} tieuDe={`Chuyển thưởng vào kỳ ${kyLuong(ky.thang, ky.nam)}`} rong={440}>
      <form className="bieu-mau" onSubmit={(e) => {
        e.preventDefault()
        chay(() => api.post('/phat-sinh/chuyen-thuong', { so_quyet_dinh: soQd.trim(), thang: ky.thang, nam: ky.nam }),
          'Đã chuyển thưởng; tính lại kỳ để cập nhật phiếu.').then(() => { dong(); setSoQd(''); xong() }).catch(() => {})
      }}>
        <TruongNhap nhan="Số quyết định khen thưởng" goiY="Quyết định phải đã được HR duyệt, hình thức tiền">
          <input required value={soQd} placeholder="vd 001/2026/QĐ-KT" onChange={(e) => setSoQd(e.target.value)} />
        </TruongNhap>
        <div className="hang-nut"><button className="nut" disabled={dang}>Chuyển</button></div>
      </form>
    </HopThoai>
  )
}
