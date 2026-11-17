// Ngữ cảnh đăng nhập: "toi" lấy từ GET /api/toi - danh tính do CSDL nạp (HRM_CTX),
// không đọc từ token. Vai trò chỉ dùng để ẨN/HIỆN menu cho dễ dùng; quyền thật
// nằm trong CSDL (bấm được nút mà không có quyền thì CSDL vẫn từ chối).
import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { api, datKhiHetPhien } from './api'

const AuthCtx = createContext(null)

export function AuthProvider({ children }) {
  const [toi, setToi] = useState(undefined)   // undefined = đang kiểm tra, null = chưa đăng nhập

  const taiLai = useCallback(async () => {
    try { setToi(await api.get('/toi', { boQua401: true })) } catch { setToi(null) }
  }, [])

  useEffect(() => {
    taiLai()
    datKhiHetPhien(() => setToi(null))
  }, [taiLai])

  const dangNhap = async (ten, matKhau) => {
    await api.post('/dang-nhap', { ten_dang_nhap: ten, mat_khau: matKhau }, { boQua401: true })
    await taiLai()
  }
  const dangXuat = async () => {
    await api.post('/dang-xuat').catch(() => {})
    setToi(null)
  }
  const co = (...vaiTro) => !!toi && vaiTro.some((v) => toi.vai_tro.includes(v))

  return <AuthCtx.Provider value={{ toi, dangNhap, dangXuat, taiLai, co }}>{children}</AuthCtx.Provider>
}

export const useAuth = () => useContext(AuthCtx)
