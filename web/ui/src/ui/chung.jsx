// Thành phần dùng chung. Giao diện nghiệp vụ: gần như không có chuyển động.
// Motion chỉ còn dùng cho hộp thoại, thông báo và mục bị gỡ khỏi danh sách -
// mờ dần 0,12 s để người dùng biết thứ gì vừa xuất hiện / biến mất.
import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { TONG_MAU, nhan } from './dinh_dang'

export const NHIP = { duration: 0.12, ease: 'easeOut' }
const MO_DAN = { initial: { opacity: 0 }, animate: { opacity: 1 }, exit: { opacity: 0 }, transition: NHIP }

// ---------------------------------------------------------------------------
// Trang: tiêu đề + nút thao tác + nội dung (không hiệu ứng khi đổi trang)
export function Trang({ tieuDe, moTa, hanhDong, children }) {
  return (
    <section className="trang">
      <header className="trang-dau">
        <div>
          <h1>{tieuDe}</h1>
          {moTa && <p className="mo-ta">{moTa}</p>}
        </div>
        {hanhDong && <div className="hanh-dong">{hanhDong}</div>}
      </header>
      {children}
    </section>
  )
}

export function The({ tieuDe, phai, children, className = '' }) {
  return (
    <div className={`the ${className}`}>
      {(tieuDe || phai) && <div className="the-dau"><h2>{tieuDe}</h2>{phai}</div>}
      {children}
    </div>
  )
}

export function Chip({ ma, mau, children }) {
  return <span className={`chip chip-${mau ?? TONG_MAU[ma] ?? 'xam'}`}>{children ?? nhan(ma)}</span>
}

// ---------------------------------------------------------------------------
// Tải dữ liệu: { duLieu, dangTai, loi, taiLai }
export function useTai(ham, phuThuoc = []) {
  const [tt, setTt] = useState({ duLieu: null, dangTai: true, loi: null })
  const taiLai = useCallback(async () => {
    setTt((t) => ({ ...t, dangTai: true, loi: null }))
    try { setTt({ duLieu: await ham(), dangTai: false, loi: null }) }
    catch (e) { setTt({ duLieu: null, dangTai: false, loi: e }) }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, phuThuoc)
  useEffect(() => { taiLai() }, [taiLai])
  return { ...tt, taiLai }
}

export function KhungTai({ tt, rong = 'Chưa có dữ liệu.', children }) {
  if (tt.dangTai && !tt.duLieu) return <div className="xuong"><div /><div /><div /></div>
  if (tt.loi) return <p className="bao-loi">{tt.loi.message}</p>
  if (!tt.duLieu || (Array.isArray(tt.duLieu) && tt.duLieu.length === 0)) return <p className="trong">{rong}</p>
  return children(tt.duLieu)
}

// ---------------------------------------------------------------------------
// Bảng: cot = [{ k, t, dinhDang?, phai?, xuongDong?, ve?(dong) }]
export function Bang({ cot, dong, khoa, khiChon, chon }) {
  return (
    <div className="bang-cuon">
      <table className="bang">
        <thead><tr>{cot.map((c) => <th key={c.k} className={c.phai ? 'phai' : ''}>{c.t}</th>)}</tr></thead>
        <tbody>
            {dong.map((d, i) => {
              const id = khoa ? khoa(d) : i
              return (
                <tr key={id}
                  className={`${khiChon ? 'bam-duoc' : ''} ${chon === id ? 'dang-chon' : ''}`}
                  onClick={khiChon ? () => khiChon(d) : undefined}>
                  {cot.map((c) => (
                    <td key={c.k} className={c.phai ? 'phai so' : c.xuongDong ? 'xuong-dong' : ''}>
                      {c.ve ? c.ve(d) : c.dinhDang ? c.dinhDang(d[c.k]) : d[c.k] ?? '—'}
                    </td>
                  ))}
                </tr>
              )
            })}
        </tbody>
      </table>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Hộp thoại
export function HopThoai({ mo, dong, tieuDe, children, rong = 520 }) {
  useEffect(() => {
    if (!mo) return
    const phim = (e) => e.key === 'Escape' && dong()
    window.addEventListener('keydown', phim)
    return () => window.removeEventListener('keydown', phim)
  }, [mo, dong])
  return (
    <AnimatePresence>
      {mo && (
        <motion.div className="nen-mo" {...MO_DAN} onMouseDown={dong}>
          <motion.div className="hop-thoai" role="dialog" aria-modal="true" aria-label={tieuDe}
            style={{ maxWidth: rong }} onMouseDown={(e) => e.stopPropagation()}>
            <div className="hop-thoai-dau"><h2>{tieuDe}</h2>
              <button className="nut-icon" onClick={dong} aria-label="Đóng">×</button></div>
            {children}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

// ---------------------------------------------------------------------------
// Thông báo nổi (toast)
const ToastCtx = createContext(() => {})
export const useThongBao = () => useContext(ToastCtx)

export function ThongBaoProvider({ children }) {
  const [ds, setDs] = useState([])
  const so = useRef(0)
  const bao = useCallback((noiDung, loai = 'ok') => {
    const id = ++so.current
    setDs((d) => [...d, { id, noiDung, loai }])
    setTimeout(() => setDs((d) => d.filter((x) => x.id !== id)), loai === 'loi' ? 6000 : 3500)
  }, [])
  return (
    <ToastCtx.Provider value={bao}>
      {children}
      <div className="vung-toast" aria-live="polite">
        <AnimatePresence>
          {ds.map((t) => (
            <motion.div key={t.id} className={`toast toast-${t.loai}`} {...MO_DAN}>
              {t.noiDung}
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </ToastCtx.Provider>
  )
}

// Chạy một thao tác ghi: khóa nút trong lúc chờ, báo thành công / lỗi CSDL
export function useThaoTac() {
  const bao = useThongBao()
  const [dang, setDang] = useState(false)
  const chay = async (ham, thanhCong) => {
    setDang(true)
    try {
      const kq = await ham()
      if (thanhCong) bao(typeof thanhCong === 'function' ? thanhCong(kq) : thanhCong)
      return kq
    } catch (e) {
      bao(e.message, 'loi')
      throw e
    } finally {
      setDang(false)
    }
  }
  return { dang, chay }
}

// ---------------------------------------------------------------------------
// Số liệu: hiển thị thẳng giá trị đã định dạng (không hiệu ứng đếm)
export function SoChay({ giaTri, dinhDang }) {
  return <span>{dinhDang(giaTri)}</span>
}

export function TruongNhap({ nhan: n, children, goiY }) {
  return (
    <label className="truong">
      <span className="truong-nhan">{n}</span>
      {children}
      {goiY && <span className="goi-y">{goiY}</span>}
    </label>
  )
}
