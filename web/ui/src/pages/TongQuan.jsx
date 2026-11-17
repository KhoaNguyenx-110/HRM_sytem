// Trang chủ theo vai trò: mỗi ô là một con số người dùng cần biết ngay, bấm để đi tới việc.
import { Link } from 'react-router-dom'
import { api } from '../api'
import { useAuth } from '../auth'
import { Bang, Chip, KhungTai, The, Trang, useTai } from '../ui/chung'
import { dinhDangNgay, dinhDangSo, dinhDangTien, kyLuong } from '../ui/dinh_dang'

const NAM = new Date().getFullYear()
const rong = () => Promise.resolve(null)

function O({ nhan, giaTri, dinhDang = (v) => dinhDangSo(v, 1), den, phu }) {
  const noiDung = (
    <div className="o-chi-so">
      <span className="o-nhan">{nhan}</span>
      <b>{giaTri == null ? '—' : dinhDang(giaTri)}</b>
      {phu && <span className="goi-y">{phu}</span>}
    </div>
  )
  return den ? <Link to={den} className="lien-ket-o">{noiDung}</Link> : noiDung
}

export default function TongQuan() {
  const { toi, co } = useAuth()
  const laNV = !!toi.nhan_vien_id
  const phep = useTai(() => (laNV ? api.get(`/toi/phep?nam=${NAM}`) : rong()))
  const phieu = useTai(() => (laNV ? api.get('/toi/phieu-luong') : rong()))
  const yc = useTai(() => (laNV ? api.get('/toi/yeu-cau') : rong()))
  const duyet = useTai(() => (co('MANAGER', 'HR') ? api.get('/duyet') : rong()))
  const ky = useTai(() => (co('HR', 'PAYROLL') ? api.get('/danh-muc/KY_LUONG') : rong()))
  const hd = useTai(() => (co('HR') ? api.get('/hop-dong/sap-het-han') : rong()))
  const tk = useTai(() => (co('ADMIN') ? api.get('/tai-khoan') : rong()))

  const chao = toi.ho_so?.ho_ten?.split(' ').slice(-1)[0] ?? toi.ten_dang_nhap
  const kyMoi = ky.duLieu?.[0]
  return (
    <Trang tieuDe={`Xin chào, ${chao}`} moTa={new Date().toLocaleDateString('vi-VN', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}>
      <div className="luoi-o">
        {laNV && <O nhan={`Phép năm ${NAM} còn lại`} giaTri={phep.duLieu?.[0]?.so_ngay_con_lai} phu="ngày" den="/nghi-phep" />}
        {laNV && <O nhan={phieu.duLieu?.[0] ? `Thực lĩnh kỳ ${kyLuong(phieu.duLieu[0].thang, phieu.duLieu[0].nam)}` : 'Phiếu lương gần nhất'}
          giaTri={phieu.duLieu?.[0]?.tong_net} dinhDang={dinhDangTien} den="/phieu-luong" />}
        {laNV && <O nhan="Yêu cầu đang chờ duyệt" giaTri={yc.duLieu?.filter((d) => d.trang_thai === 'CHO_DUYET').length}
          dinhDang={(v) => dinhDangSo(v, 0)} den="/nghi-phep" />}
        {co('MANAGER', 'HR') && <O nhan="Chờ bạn duyệt" giaTri={duyet.duLieu?.length} dinhDang={(v) => dinhDangSo(v, 0)} den="/duyet" />}
        {kyMoi && (
          <Link to="/ky-luong" className="lien-ket-o">
            <div className="o-chi-so">
              <span className="o-nhan">Kỳ lương mới nhất</span>
              <b>{kyLuong(kyMoi.thang, kyMoi.nam)}</b><Chip ma={kyMoi.trang_thai} />
            </div>
          </Link>
        )}
        {co('ADMIN') && <O nhan="Tài khoản" giaTri={tk.duLieu?.length} dinhDang={(v) => dinhDangSo(v, 0)} den="/tai-khoan" />}
        {co('ADMIN') && <O nhan="Đang bị khóa" giaTri={tk.duLieu?.filter((d) => d.trang_thai === 'KHOA').length}
          dinhDang={(v) => dinhDangSo(v, 0)} den="/tai-khoan" />}
      </div>
      {co('HR') && (
        <The tieuDe="Hợp đồng sắp hết hạn">
          <KhungTai tt={hd} rong="Không có hợp đồng nào sắp hết hạn.">
            {(ds) => <Bang dong={ds} khoa={(d) => d.so_hop_dong} cot={[
              { k: 'so_hop_dong', t: 'Số hợp đồng' }, { k: 'ho_ten', t: 'Nhân viên' },
              { k: 'ten_phong_ban', t: 'Phòng' }, { k: 'ngay_ket_thuc', t: 'Hết hạn', dinhDang: dinhDangNgay },
            ]} />}
          </KhungTai>
        </The>
      )}
    </Trang>
  )
}
