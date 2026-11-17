import { useState } from 'react'
import { useAuth } from '../auth'

export default function DangNhap() {
  const { dangNhap } = useAuth()
  const [ten, setTen] = useState('')
  const [mk, setMk] = useState('')
  const [loi, setLoi] = useState('')
  const [dang, setDang] = useState(false)

  const gui = async (e) => {
    e.preventDefault()
    setDang(true)
    setLoi('')
    try {
      await dangNhap(ten, mk)
    } catch (err) {
      setLoi(err.message)
      setMk('')
    } finally {
      setDang(false)
    }
  }

  return (
    <div className="nen-dang-nhap">
      <form className="the-dang-nhap" onSubmit={gui}>
        <div className="logo lon"><span className="logo-dau">H</span> HRM</div>
        <h1>Đăng nhập</h1>
        <p className="mo-ta">Hệ thống quản lý nhân sự và tiền lương</p>
        <label className="truong">
          <span className="truong-nhan">Tên đăng nhập</span>
          <input autoFocus autoComplete="username" value={ten} onChange={(e) => setTen(e.target.value)} required />
        </label>
        <label className="truong">
          <span className="truong-nhan">Mật khẩu</span>
          <input type="password" autoComplete="current-password" value={mk}
            onChange={(e) => setMk(e.target.value)} required />
        </label>
        {loi && <p className="bao-loi" role="alert">{loi}</p>}
        <button className="nut nut-rong" disabled={dang}>{dang ? 'Đang kiểm tra…' : 'Đăng nhập'}</button>
      </form>
    </div>
  )
}
