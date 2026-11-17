// Hồ sơ của tôi (VW-01) và quá trình công tác (VW-12)
import { api } from '../api'
import { Chip, KhungTai, The, Trang, useTai } from '../ui/chung'
import { dinhDangNgay } from '../ui/dinh_dang'

export function TruongHoSo({ hs }) {
  const truong = [
    ['Mã nhân viên', hs.ma_nhan_vien], ['Ngày sinh', dinhDangNgay(hs.ngay_sinh)],
    ['Số định danh', hs.so_dinh_danh], ['Mã số thuế', hs.ma_so_thue], ['Email', hs.email],
    ['Điện thoại', hs.so_dien_thoai], ['Địa chỉ', hs.dia_chi], ['Ngày vào làm', dinhDangNgay(hs.ngay_vao_lam)],
    ['Phòng ban', hs.ten_phong_ban], ['Chức vụ', hs.ten_chuc_vu],
  ]
  return <dl className="luoi-truong">{truong.map(([k, v]) => <div key={k}><dt>{k}</dt><dd>{v ?? '—'}</dd></div>)}</dl>
}

export function QuaTrinh({ ds }) {
  return (
    <ol className="dong-thoi-gian">
      {ds.map((q, i) => (
        <li key={i}>
          <div className="moc">{dinhDangNgay(q.ngay_bat_dau)}{q.ngay_ket_thuc ? ` – ${dinhDangNgay(q.ngay_ket_thuc)}` : ' – nay'}</div>
          <div><b>{q.ten_chuc_vu}</b> · {q.ten_phong_ban}</div>
          {q.can_cu_dieu_chuyen && <div className="goi-y">{q.can_cu_dieu_chuyen}</div>}
        </li>
      ))}
    </ol>
  )
}

export default function HoSo() {
  const tt = useTai(() => api.get('/toi/ho-so'))
  return (
    <Trang tieuDe="Hồ sơ của tôi" moTa="Cần sửa thông tin, liên hệ phòng Nhân sự.">
      <KhungTai tt={tt}>
        {({ ho_so: hs, qua_trinh: qt }) => (
          <div className="luoi-2">
            <The tieuDe={hs.ho_ten} phai={<Chip ma={hs.trang_thai_lam_viec} />}><TruongHoSo hs={hs} /></The>
            <The tieuDe="Quá trình công tác"><QuaTrinh ds={qt} /></The>
          </div>
        )}
      </KhungTai>
    </Trang>
  )
}
