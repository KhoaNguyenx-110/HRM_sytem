// Nghỉ phép & OT của tôi: phép còn lại (VW-02), đăng ký nghỉ / OT, yêu cầu của tôi (VW-11).
import { useState } from 'react'
import { api } from '../api'
import { Bang, Chip, KhungTai, The, Trang, TruongNhap, useTai, useThaoTac } from '../ui/chung'
import { dinhDangNgay, dinhDangSo, nhan } from '../ui/dinh_dang'

const NAM = new Date().getFullYear()

export default function NghiPhep() {
  const phep = useTai(() => api.get(`/toi/phep?nam=${NAM}`))
  const yc = useTai(() => api.get('/toi/yeu-cau'))
  const [tab, setTab] = useState('nghi')
  const taiLai = () => { phep.taiLai(); yc.taiLai() }

  return (
    <Trang tieuDe="Nghỉ phép & làm thêm giờ">
      <div className="luoi-2">
        <div className="cot">
          <The tieuDe={`Phép năm ${NAM}`}>
            <KhungTai tt={phep} rong="Chưa có hạn mức phép năm nay.">
              {([p]) => (
                <div className="phep">
                  <div className="phep-so"><b>{dinhDangSo(p.so_ngay_con_lai, 1)}</b><span>ngày còn lại</span></div>
                  <div className="thanh">
                    <div className="thanh-dung"
                      style={{ width: `${Math.min(100, (p.so_ngay_da_dung / (p.so_ngay_duoc_cap + p.so_ngay_dieu_chinh || 1)) * 100)}%` }} />
                  </div>
                  <div className="phep-chi-tiet">
                    <span>Được cấp {dinhDangSo(p.so_ngay_duoc_cap + p.so_ngay_dieu_chinh, 1)}</span>
                    <span>Đã dùng {dinhDangSo(p.so_ngay_da_dung, 1)}</span>
                    <span>Chờ duyệt {dinhDangSo(p.so_ngay_cho_duyet, 1)}</span>
                  </div>
                </div>
              )}
            </KhungTai>
          </The>
          <The>
            <div className="tab" role="tablist">
              {[['nghi', 'Đăng ký nghỉ'], ['ot', 'Đăng ký OT']].map(([k, t]) => (
                <button key={k} role="tab" aria-selected={tab === k} onClick={() => setTab(k)}>
{t}
                </button>
              ))}
            </div>
            {tab === 'nghi' ? <FormNghi xong={taiLai} /> : <FormOT xong={taiLai} />}
          </The>
        </div>
        <The tieuDe="Yêu cầu của tôi">
          <KhungTai tt={yc} rong="Bạn chưa gửi yêu cầu nào.">
            {(ds) => <Bang khoa={(d) => `${d.loai_yeu_cau}-${d.ma_yeu_cau}`} dong={ds} cot={[
              { k: 'loai_yeu_cau', t: 'Loại', dinhDang: nhan },
              { k: 'noi_dung', t: 'Nội dung', xuongDong: true },
              { k: 'tu_ngay', t: 'Ngày', xuongDong: true, ve: (d) => d.tu_ngay === d.den_ngay ? dinhDangNgay(d.tu_ngay)
                : `${dinhDangNgay(d.tu_ngay)} – ${dinhDangNgay(d.den_ngay)}` },
              { k: 'so_luong', t: 'Buổi / giờ', phai: true, dinhDang: (v) => dinhDangSo(v) },
              { k: 'trang_thai', t: 'Trạng thái', ve: (d) => <Chip ma={d.trang_thai} /> },
              { k: 'rut', t: '', ve: (d) => d.loai_yeu_cau === 'NGHI_PHEP' && ['CHO_DUYET', 'DA_DUYET'].includes(d.trang_thai)
                ? <NutRut id={d.ma_yeu_cau} xong={taiLai} /> : null },
            ]} />}
          </KhungTai>
        </The>
      </div>
    </Trang>
  )
}

function NutRut({ id, xong }) {
  const { dang, chay } = useThaoTac()
  return <button className="nut nut-nho nut-nhat" disabled={dang}
    onClick={() => chay(() => api.post(`/toi/nghi-phep/${id}/rut`), 'Đã rút đơn.').then(xong).catch(() => {})}>Rút</button>
}

function FormNghi({ xong }) {
  const loai = useTai(() => api.get('/danh-muc/LOAI_NGHI_PHEP'))
  const [f, setF] = useState({ ma_loai: 'PHEP_NAM', tu_ngay: '', den_ngay: '', buoi: 'CA_NGAY', ly_do: '' })
  const { dang, chay } = useThaoTac()
  const gui = (e) => {
    e.preventDefault()
    chay(() => api.post('/toi/nghi-phep', { ...f, den_ngay: f.den_ngay || f.tu_ngay }), 'Đã gửi đơn, chờ duyệt.')
      .then(() => { setF({ ...f, tu_ngay: '', den_ngay: '', ly_do: '' }); xong() }).catch(() => {})
  }
  return (
    <form className="bieu-mau" onSubmit={gui}>
      <TruongNhap nhan="Loại nghỉ">
        <select value={f.ma_loai} onChange={(e) => setF({ ...f, ma_loai: e.target.value })}>
          {(loai.duLieu ?? []).map((l) => <option key={l.ma_loai} value={l.ma_loai}>{l.ten_loai}</option>)}
        </select>
      </TruongNhap>
      <div className="hang">
        <TruongNhap nhan="Từ ngày"><input type="date" required value={f.tu_ngay}
          onChange={(e) => setF({ ...f, tu_ngay: e.target.value })} /></TruongNhap>
        <TruongNhap nhan="Đến ngày"><input type="date" value={f.den_ngay} min={f.tu_ngay}
          onChange={(e) => setF({ ...f, den_ngay: e.target.value })} /></TruongNhap>
      </div>
      <TruongNhap nhan="Buổi" goiY="Chỉ tính các ngày làm việc trong khoảng đã chọn">
        <select value={f.buoi} onChange={(e) => setF({ ...f, buoi: e.target.value })}>
          <option value="CA_NGAY">Cả ngày</option><option value="SANG">Buổi sáng</option>
          <option value="CHIEU">Buổi chiều</option>
        </select>
      </TruongNhap>
      <TruongNhap nhan="Lý do"><input required value={f.ly_do} maxLength={500}
        onChange={(e) => setF({ ...f, ly_do: e.target.value })} /></TruongNhap>
      <div className="hang-nut"><button className="nut" disabled={dang}>Gửi đơn</button></div>
    </form>
  )
}

function FormOT({ xong }) {
  const [f, setF] = useState({ ngay: '', tu: '18:00', den: '20:00', ly_do: '' })
  const { dang, chay } = useThaoTac()
  const gui = (e) => {
    e.preventDefault()
    chay(() => api.post('/toi/ot', { bat_dau: `${f.ngay}T${f.tu}:00`, ket_thuc: `${f.ngay}T${f.den}:00`, ly_do: f.ly_do }),
      'Đã gửi đăng ký OT.').then(() => { setF({ ...f, ngay: '', ly_do: '' }); xong() }).catch(() => {})
  }
  return (
    <form className="bieu-mau" onSubmit={gui}>
      <TruongNhap nhan="Ngày"><input type="date" required value={f.ngay}
        onChange={(e) => setF({ ...f, ngay: e.target.value })} /></TruongNhap>
      <div className="hang">
        <TruongNhap nhan="Từ"><input type="time" required value={f.tu}
          onChange={(e) => setF({ ...f, tu: e.target.value })} /></TruongNhap>
        <TruongNhap nhan="Đến"><input type="time" required value={f.den}
          onChange={(e) => setF({ ...f, den: e.target.value })} /></TruongNhap>
      </div>
      <TruongNhap nhan="Lý do"><input required value={f.ly_do} maxLength={500}
        onChange={(e) => setF({ ...f, ly_do: e.target.value })} /></TruongNhap>
      <p className="goi-y">Hạn mức OT ngày, tháng, năm được kiểm tra khi gửi.</p>
      <div className="hang-nut"><button className="nut" disabled={dang}>Gửi đăng ký</button></div>
    </form>
  )
}
