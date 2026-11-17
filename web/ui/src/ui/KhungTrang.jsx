// Khung ứng dụng: thanh bên theo vai trò + đầu trang. Mục đang chọn tô nền xanh nhạt
// và vạch trái (CSS .active của NavLink), không có hiệu ứng.
import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { useAuth } from '../auth'
import { api } from '../api'
import { HopThoai, TruongNhap, useThaoTac } from './chung'
import { nhan } from './dinh_dang'

// hien(co, toi): chỉ để gọn menu; CSDL vẫn là nơi quyết định quyền
const MENU = [
  { nhom: null, muc: [{ to: '/', t: 'Tổng quan', hien: () => true }] },
  { nhom: 'Của tôi', muc: [
    { to: '/phieu-luong', t: 'Phiếu lương', hien: (co, toi) => !!toi.nhan_vien_id },
    { to: '/nghi-phep', t: 'Nghỉ phép & OT', hien: (co, toi) => !!toi.nhan_vien_id },
    { to: '/ho-so', t: 'Hồ sơ của tôi', hien: (co, toi) => !!toi.nhan_vien_id },
  ] },
  { nhom: 'Quản lý', muc: [
    { to: '/duyet', t: 'Duyệt yêu cầu', hien: (co) => co('MANAGER', 'HR') },
    { to: '/nhan-vien', t: 'Nhân viên', hien: (co) => co('HR', 'MANAGER') },
  ] },
  { nhom: 'Tiền lương', muc: [
    { to: '/ky-luong', t: 'Kỳ lương', hien: (co) => co('HR', 'PAYROLL') },
  ] },
  { nhom: 'Hệ thống', muc: [
    { to: '/tai-khoan', t: 'Tài khoản', hien: (co) => co('ADMIN') },
    { to: '/nhat-ky', t: 'Nhật ký', hien: (co) => co('ADMIN', 'HR', 'PAYROLL') },
  ] },
]

export function KhungTrang({ children }) {
  const { toi, co, dangXuat } = useAuth()
  const [doiMk, setDoiMk] = useState(false)

  return (
    <div className="khung">
      <aside className="thanh-ben">
        <div className="logo"><span className="logo-dau">H</span> HRM</div>
        <nav>
          {MENU.map(({ nhom, muc }) => {
            const ds = muc.filter((m) => m.hien(co, toi))
            if (!ds.length) return null
            return (
              <div key={nhom ?? 'goc'} className="nhom-menu">
                {nhom && <div className="nhom-ten">{nhom}</div>}
                {ds.map((m) => (
                  <NavLink key={m.to} to={m.to} end={m.to === '/'} className="muc-menu">{m.t}</NavLink>
                ))}
              </div>
            )
          })}
        </nav>
      </aside>
      <div className="than">
        <header className="dau-trang">
          <div className="nguoi-dung">
            <div className="ten">{toi.ho_so?.ho_ten ?? toi.ten_dang_nhap}</div>
            <div className="phu">
              {toi.ho_so ? `${toi.ho_so.ma_nhan_vien} · ${toi.ho_so.ten_phong_ban ?? ''}` : 'Tài khoản kỹ thuật'}
              {' · '}{toi.vai_tro.map(nhan).join(', ')}
            </div>
          </div>
          <button className="nut nut-nhat" onClick={() => setDoiMk(true)}>Đổi mật khẩu</button>
          <button className="nut nut-nhat" onClick={dangXuat}>Đăng xuất</button>
        </header>
        <main>{children}</main>
      </div>
      <DoiMatKhau mo={doiMk} dong={() => setDoiMk(false)} />
    </div>
  )
}

function DoiMatKhau({ mo, dong }) {
  const [f, setF] = useState({ cu: '', moi: '', lai: '' })
  const { dang, chay } = useThaoTac()
  const [loi, setLoi] = useState('')
  const gui = async (e) => {
    e.preventDefault()
    if (f.moi !== f.lai) return setLoi('Hai lần nhập mật khẩu mới không khớp.')
    setLoi('')
    await chay(() => api.post('/toi/doi-mat-khau', { mat_khau_cu: f.cu, mat_khau_moi: f.moi }),
      'Đã đổi mật khẩu.').then(() => { setF({ cu: '', moi: '', lai: '' }); dong() }).catch(() => {})
  }
  return (
    <HopThoai mo={mo} dong={dong} tieuDe="Đổi mật khẩu" rong={420}>
      <form onSubmit={gui} className="bieu-mau">
        <TruongNhap nhan="Mật khẩu hiện tại">
          <input type="password" autoComplete="current-password" value={f.cu} required
            onChange={(e) => setF({ ...f, cu: e.target.value })} /></TruongNhap>
        <TruongNhap nhan="Mật khẩu mới" goiY="Ít nhất 8 ký tự">
          <input type="password" autoComplete="new-password" value={f.moi} required minLength={8}
            onChange={(e) => setF({ ...f, moi: e.target.value })} /></TruongNhap>
        <TruongNhap nhan="Nhập lại mật khẩu mới">
          <input type="password" autoComplete="new-password" value={f.lai} required
            onChange={(e) => setF({ ...f, lai: e.target.value })} /></TruongNhap>
        {loi && <p className="bao-loi">{loi}</p>}
        <div className="hang-nut"><button className="nut" disabled={dang}>Lưu</button></div>
      </form>
    </HopThoai>
  )
}
