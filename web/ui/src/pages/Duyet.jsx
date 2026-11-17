// Hàng chờ duyệt (VW-08). Duyệt xong, thẻ mờ đi rồi biến mất: người dùng thấy
// thao tác đã có tác dụng. Ai được duyệt gì do CSDL quyết định (quy tắc 2.4).
import { useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { api } from '../api'
import { Chip, HopThoai, KhungTai, NHIP, Trang, TruongNhap, useTai, useThaoTac } from '../ui/chung'
import { dinhDangNgay, dinhDangSo, dinhDangTien, nhan } from '../ui/dinh_dang'

const DON_VI = { NGHI_PHEP: 'buổi', OT: 'giờ' }

export default function Duyet() {
  const tt = useTai(() => api.get('/duyet'))
  const [tuChoi, setTuChoi] = useState(null)
  const [yKien, setYKien] = useState('')
  const { dang, chay } = useThaoTac()

  const xuLy = (d, dongY, yk) =>
    chay(() => api.post(`/duyet/${d.loai_yeu_cau}/${d.ma_yeu_cau}`, { dong_y: dongY, y_kien: yk || null }),
      dongY ? `Đã duyệt yêu cầu của ${d.ho_ten}.` : `Đã từ chối yêu cầu của ${d.ho_ten}.`)
      .then(tt.taiLai).catch(() => {})

  return (
    <Trang tieuDe="Duyệt yêu cầu" moTa="Những yêu cầu bạn là người duyệt hợp lệ.">
      <KhungTai tt={tt} rong="Không còn yêu cầu nào chờ bạn duyệt.">
        {(ds) => (
          <ul className="ds-the">
            <AnimatePresence initial={false}>
              {ds.map((d) => (
                <motion.li key={`${d.loai_yeu_cau}-${d.ma_yeu_cau}`} className="the the-yc"
                  exit={{ opacity: 0 }} transition={NHIP}>
                  <div className="yc-trai">
                    <Chip mau="xam">{nhan(d.loai_yeu_cau)}</Chip>
                    <div className="yc-ten">{d.ho_ten} <span className="goi-y">{d.ma_nhan_vien}</span></div>
                    <div>{d.noi_dung}</div>
                    <div className="goi-y">
                      {d.tu_ngay === d.den_ngay ? dinhDangNgay(d.tu_ngay) : `${dinhDangNgay(d.tu_ngay)} – ${dinhDangNgay(d.den_ngay)}`}
                      {' · '}{DON_VI[d.loai_yeu_cau] ? `${dinhDangSo(d.so_luong)} ${DON_VI[d.loai_yeu_cau]}` : dinhDangTien(d.so_luong)}
                    </div>
                    {d.ly_do && <div className="ly-do">“{d.ly_do}”</div>}
                  </div>
                  <div className="yc-nut">
                    <button className="nut" disabled={dang} onClick={() => xuLy(d, true)}>Đồng ý</button>
                    <button className="nut nut-nhat" disabled={dang} onClick={() => { setYKien(''); setTuChoi(d) }}>Từ chối</button>
                  </div>
                </motion.li>
              ))}
            </AnimatePresence>
          </ul>
        )}
      </KhungTai>
      <HopThoai mo={!!tuChoi} dong={() => setTuChoi(null)} tieuDe="Từ chối yêu cầu" rong={460}>
        <form className="bieu-mau" onSubmit={(e) => { e.preventDefault(); xuLy(tuChoi, false, yKien); setTuChoi(null) }}>
          <p>{tuChoi?.ho_ten} – {tuChoi?.noi_dung}</p>
          <TruongNhap nhan="Lý do từ chối" goiY="Người gửi sẽ thấy lý do này">
            <textarea required rows={3} value={yKien} onChange={(e) => setYKien(e.target.value)} />
          </TruongNhap>
          <div className="hang-nut"><button className="nut nut-do">Từ chối</button></div>
        </form>
      </HopThoai>
    </Trang>
  )
}
