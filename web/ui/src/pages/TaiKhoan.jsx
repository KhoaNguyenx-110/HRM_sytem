// Quản trị tài khoản (VW-09, VW-13). Admin không thấy hồ sơ/lương (TC-08).
import { useState } from 'react'
import { api } from '../api'
import { Bang, Chip, HopThoai, KhungTai, Trang, TruongNhap, useTai, useThaoTac } from '../ui/chung'
import { dinhDangNgay, nhan } from '../ui/dinh_dang'

const VAI_TRO = ['EMPLOYEE', 'MANAGER', 'HR', 'PAYROLL', 'ADMIN']

export default function TaiKhoan() {
  const tt = useTai(() => api.get('/tai-khoan'))
  const [vaiTro, setVaiTro] = useState(null)
  const [moTao, setMoTao] = useState(false)
  const [tim, setTim] = useState('')
  const { dang, chay } = useThaoTac()

  const doiTrangThai = (d) => chay(() => api.post(`/tai-khoan/${d.ten_dang_nhap}/${d.trang_thai === 'KHOA' ? 'mo' : 'khoa'}`),
    `${d.trang_thai === 'KHOA' ? 'Đã mở' : 'Đã khóa'} tài khoản ${d.ten_dang_nhap}.`).then(tt.taiLai).catch(() => {})

  return (
    <Trang tieuDe="Tài khoản" hanhDong={<button className="nut" onClick={() => setMoTao(true)}>+ Cấp tài khoản</button>}>
      <div className="thanh-loc">
        <input type="search" placeholder="Tìm tên đăng nhập, họ tên, mã nhân viên…" value={tim}
          onChange={(e) => setTim(e.target.value)} />
      </div>
      <KhungTai tt={tt}>
        {(tatCa) => {
          const t = tim.trim().toLowerCase()
          const ds = t ? tatCa.filter((d) => [d.ten_dang_nhap, d.ho_ten, d.ma_nhan_vien]
            .some((x) => (x ?? '').toLowerCase().includes(t))) : tatCa
          return <Bang dong={ds} khoa={(d) => d.tai_khoan_id} cot={[
          { k: 'ten_dang_nhap', t: 'Tên đăng nhập' },
          { k: 'ho_ten', t: 'Nhân viên', ve: (d) => d.ho_ten ? `${d.ho_ten} (${d.ma_nhan_vien})` : <em>tài khoản kỹ thuật</em> },
          { k: 'vai_tro', t: 'Vai trò', ve: (d) => (d.vai_tro ?? '').split(', ').filter(Boolean)
            .map((v) => <Chip key={v} mau="xanh">{nhan(v)}</Chip>) },
          { k: 'trang_thai', t: 'Trạng thái', ve: (d) => <Chip ma={d.trang_thai} /> },
          { k: 'so_lan_dang_nhap_sai', t: 'Sai liên tiếp', phai: true },
          { k: 'thoi_diem_tao', t: 'Ngày tạo', dinhDang: dinhDangNgay },
          { k: 'nut', t: '', ve: (d) => (
            <div className="hang-nut trai nho">
              <button className="nut nut-nho nut-nhat" onClick={() => setVaiTro(d)}>Vai trò</button>
              <button className="nut nut-nho nut-nhat" disabled={dang} onClick={() => doiTrangThai(d)}>
                {d.trang_thai === 'KHOA' ? 'Mở khóa' : 'Khóa'}</button>
            </div>) },
        ]} />
        }}
      </KhungTai>
      <SuaVaiTro tk={vaiTro} dong={() => setVaiTro(null)} xong={tt.taiLai} />
      <CapTaiKhoan mo={moTao} dong={() => setMoTao(false)} daCo={tt.duLieu ?? []} xong={tt.taiLai} />
    </Trang>
  )
}

function SuaVaiTro({ tk, dong, xong }) {
  const { dang, chay } = useThaoTac()
  const co = (tk?.vai_tro ?? '').split(', ')
  const doi = (v) => chay(() => co.includes(v)
    ? api.del(`/tai-khoan/${tk.ten_dang_nhap}/vai-tro/${v}`)
    : api.post(`/tai-khoan/${tk.ten_dang_nhap}/vai-tro/${v}`), 'Đã cập nhật vai trò.')
    .then(() => { dong(); xong() }).catch(() => {})
  return (
    <HopThoai mo={!!tk} dong={dong} tieuDe={`Vai trò – ${tk?.ten_dang_nhap}`} rong={420}>
      <p className="goi-y">Thay đổi có hiệu lực ngay ở thao tác kế tiếp của người dùng.</p>
      <div className="ds-vai-tro">
        {VAI_TRO.map((v) => (
          <button key={v} className={`chon-vai-tro ${co.includes(v) ? 'co' : ''}`} disabled={dang} onClick={() => doi(v)}>
            <span>{nhan(v)}</span><span>{co.includes(v) ? 'Thu hồi' : 'Gán'}</span>
          </button>
        ))}
      </div>
    </HopThoai>
  )
}

function CapTaiKhoan({ mo, dong, daCo, xong }) {
  const db = useTai(() => (mo ? api.get('/danh-ba') : Promise.resolve([])), [mo])
  const [f, setF] = useState({ ma_nhan_vien: '', ten_dang_nhap: '', mat_khau_tam: '' })
  const { dang, chay } = useThaoTac()
  const daCap = new Set(daCo.map((d) => d.ma_nhan_vien))
  const chua = (db.duLieu ?? []).filter((n) => !daCap.has(n.ma_nhan_vien) && n.trang_thai_lam_viec === 'DANG_LAM')
  return (
    <HopThoai mo={mo} dong={dong} tieuDe="Cấp tài khoản" rong={460}>
      <form className="bieu-mau" onSubmit={(e) => {
        e.preventDefault()
        chay(() => api.post('/tai-khoan', { ...f, ma_nhan_vien: f.ma_nhan_vien || null }),
          `Đã cấp tài khoản ${f.ten_dang_nhap}.`).then(() => { dong(); xong(); setF({ ma_nhan_vien: '', ten_dang_nhap: '', mat_khau_tam: '' }) }).catch(() => {})
      }}>
        <TruongNhap nhan="Nhân viên" goiY="Chỉ liệt kê nhân viên đang làm và chưa có tài khoản">
          <select value={f.ma_nhan_vien} onChange={(e) => setF({ ...f, ma_nhan_vien: e.target.value,
            ten_dang_nhap: f.ten_dang_nhap || e.target.value.toLowerCase() })}>
            <option value="">— Tài khoản kỹ thuật —</option>
            {chua.map((n) => <option key={n.ma_nhan_vien} value={n.ma_nhan_vien}>{n.ma_nhan_vien} – {n.ho_ten}</option>)}
          </select>
        </TruongNhap>
        <TruongNhap nhan="Tên đăng nhập"><input required minLength={3} value={f.ten_dang_nhap}
          onChange={(e) => setF({ ...f, ten_dang_nhap: e.target.value })} /></TruongNhap>
        <TruongNhap nhan="Mật khẩu tạm" goiY="Ít nhất 8 ký tự; người dùng đổi sau lần đăng nhập đầu">
          <input required minLength={8} value={f.mat_khau_tam} onChange={(e) => setF({ ...f, mat_khau_tam: e.target.value })} />
        </TruongNhap>
        <div className="hang-nut"><button className="nut" disabled={dang}>Cấp</button></div>
      </form>
    </HopThoai>
  )
}
