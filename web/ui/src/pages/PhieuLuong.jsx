// Phiếu lương của tôi (VW-05: chỉ kỳ ĐÃ KHÓA). Dùng lại PhieuChiTiet cho Payroll.
import { useState } from 'react'
import { api } from '../api'
import { KhungTai, The, Trang, useTai } from '../ui/chung'
import { dinhDangSo, dinhDangTien, kyLuong } from '../ui/dinh_dang'

// Nhóm khoản theo cách người lao động đọc phiếu
const NHOM = [
  ['THU_NHAP', 'Thu nhập'],
  ['GIAM_THU_NHAP', 'Giảm thu nhập'],
  ['BAO_HIEM_NLD', 'Bảo hiểm người lao động đóng'],
  ['THUE_TNCN', 'Thuế thu nhập cá nhân'],
  ['KHAU_TRU', 'Khấu trừ khác'],
  ['BAO_HIEM_NSDLD', 'Doanh nghiệp đóng thêm (không trừ vào lương)'],
]

// "176 × 150.000 đ", "4 × 150.000 đ × 1,5", "26.400.000 đ × 8%": bỏ các thừa số = 1
function cachTinh(k) {
  if (k.don_gia == null) return ''
  const phan = []
  if (k.so_luong != null && k.so_luong !== 1) phan.push(dinhDangSo(k.so_luong))
  phan.push(dinhDangTien(k.don_gia))
  if (k.he_so != null && k.he_so !== 1) phan.push(k.he_so < 1 ? `${dinhDangSo(k.he_so * 100, 2)}%` : dinhDangSo(k.he_so))
  return phan.length > 1 ? phan.join(' × ') : ''
}
const tru = (v) => (v ? `−${dinhDangTien(v)}` : dinhDangTien(0))

export function PhieuChiTiet({ p }) {
  return (
    <div className="phieu">
      <div className="phieu-net">
        <span>Thực lĩnh kỳ {kyLuong(p.thang, p.nam)}</span>
        <strong>{dinhDangTien(p.tong_net)}</strong>
      </div>
      <div className="phieu-tom-tat">
        <div><span>Tổng thu nhập</span><b>{dinhDangTien(p.tong_gross)}</b></div>
        <div><span>Bảo hiểm</span><b>{tru(p.bao_hiem_nld)}</b></div>
        <div><span>Thuế TNCN</span><b>{tru(p.thue_tncn)}</b></div>
        <div><span>Khấu trừ khác</span><b>{tru(p.khau_tru_khac)}</b></div>
      </div>
      {NHOM.map(([ma, ten]) => {
        const ds = p.khoan.filter((k) => k.nhom_khoan_ap_dung === ma)
        if (!ds.length) return null
        return (
          <div key={ma} className="phieu-nhom">
            <h3>{ten}</h3>
            {ds.map((k, i) => (
              <div key={i} className="phieu-dong">
                <span>{k.ten_khoan}{cachTinh(k) && <em> · {cachTinh(k)}</em>}</span>
                <span className="so">{dinhDangTien(k.thanh_tien)}</span>
              </div>
            ))}
          </div>
        )
      })}
      <p className="ghi-chu">
        Lương cơ bản áp dụng {dinhDangTien(p.luong_co_ban_ap_dung)} · giờ hưởng lương {dinhDangSo(p.gio_huong_luong)} ·
        thu nhập tính thuế {dinhDangTien(p.thu_nhap_tinh_thue)}
      </p>
    </div>
  )
}

export default function PhieuLuong() {
  const tt = useTai(() => api.get('/toi/phieu-luong'))
  const [chon, setChon] = useState(null)

  return (
    <Trang tieuDe="Phiếu lương" moTa="Phiếu hiển thị sau khi kỳ lương đã khóa.">
      <KhungTai tt={tt} rong="Chưa có kỳ lương nào được khóa.">
        {(ds) => {
          const p = ds.find((x) => x.phieu_luong_id === chon) ?? ds[0]
          return (
            <div className="luoi-2">
              <The tieuDe="Các kỳ">
                <ul className="ds-chon">
                  {ds.map((x) => (
                    <li key={x.phieu_luong_id}>
                      <button className={x === p ? 'dang-chon' : ''} onClick={() => setChon(x.phieu_luong_id)}>
                        <span>Kỳ {kyLuong(x.thang, x.nam)}</span>
                        <span className="so">{dinhDangTien(x.tong_net)}</span>
                      </button>
                    </li>
                  ))}
                </ul>
              </The>
              <The>
                <PhieuChiTiet p={p} />
              </The>
            </div>
          )
        }}
      </KhungTai>
    </Trang>
  )
}
