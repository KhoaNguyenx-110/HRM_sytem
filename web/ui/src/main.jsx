import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { MotionConfig } from 'motion/react'
import '@fontsource/inter/400.css'
import '@fontsource/inter/500.css'
import '@fontsource/inter/600.css'
import './styles.css'
import { AuthProvider, useAuth } from './auth'
import { ThongBaoProvider } from './ui/chung'
import { KhungTrang } from './ui/KhungTrang'
import DangNhap from './pages/DangNhap'
import TongQuan from './pages/TongQuan'
import PhieuLuong from './pages/PhieuLuong'
import NghiPhep from './pages/NghiPhep'
import HoSo from './pages/HoSo'
import Duyet from './pages/Duyet'
import NhanVien from './pages/NhanVien'
import KyLuong from './pages/KyLuong'
import TaiKhoan from './pages/TaiKhoan'
import NhatKy from './pages/NhatKy'

function UngDung() {
  const { toi } = useAuth()
  const location = useLocation()
  if (toi === undefined) return <div className="nen-dang-nhap"><div className="xoay" aria-label="Đang tải" /></div>
  if (toi === null) return <DangNhap />
  return (
    <KhungTrang>
      <Routes location={location}>
          <Route path="/" element={<TongQuan />} />
          <Route path="/phieu-luong" element={<PhieuLuong />} />
          <Route path="/nghi-phep" element={<NghiPhep />} />
          <Route path="/ho-so" element={<HoSo />} />
          <Route path="/duyet" element={<Duyet />} />
          <Route path="/nhan-vien/*" element={<NhanVien />} />
          <Route path="/ky-luong/*" element={<KyLuong />} />
          <Route path="/tai-khoan" element={<TaiKhoan />} />
          <Route path="/nhat-ky" element={<NhatKy />} />
          <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </KhungTrang>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    {/* reducedMotion="user": tôn trọng cài đặt "giảm chuyển động" của hệ điều hành */}
    <MotionConfig reducedMotion="user">
      <BrowserRouter>
        <AuthProvider>
          <ThongBaoProvider>
            <UngDung />
          </ThongBaoProvider>
        </AuthProvider>
      </BrowserRouter>
    </MotionConfig>
  </React.StrictMode>,
)
