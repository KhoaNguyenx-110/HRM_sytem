// Nhân viên (VW-01): HR thấy tất cả và có thao tác; trưởng phòng thấy phòng mình, chỉ xem.
import { useState } from 'react'
import { api, qs } from '../api'
import { useAuth } from '../auth'
import { Bang, Chip, HopThoai, KhungTai, The, Trang, TruongNhap, useTai, useThaoTac } from '../ui/chung'
import { dinhDangSo } from '../ui/dinh_dang'
import { QuaTrinh, TruongHoSo } from './HoSo'

export default function NhanVien() {
  const { co } = useAuth()
  const laHR = co('HR')
  const [loc, setLoc] = useState({ q: '', phong_ban: '', con_lam: 'true' })
  const pb = useTai(() => api.get('/danh-muc/PHONG_BAN'))
  const ds = useTai(() => api.get(`/nhan-vien${qs(loc)}`), [loc.q, loc.phong_ban, loc.con_lam])
  const [chon, setChon] = useState(null)
  const [moThem, setMoThem] = useState(false)

  return (
    <Trang tieuDe="Nhân viên" moTa={laHR ? 'Toàn bộ hồ sơ nhân sự.' : 'Nhân sự phòng bạn quản lý.'}
      hanhDong={laHR && <button className="nut" onClick={() => setMoThem(true)}>+ Thêm nhân viên</button>}>
      <div className="thanh-loc">
        <input type="search" placeholder="Tìm theo tên hoặc mã…" value={loc.q}
          onChange={(e) => setLoc({ ...loc, q: e.target.value })} />
        <select value={loc.phong_ban} onChange={(e) => setLoc({ ...loc, phong_ban: e.target.value })}>
          <option value="">Mọi phòng ban</option>
          {(pb.duLieu ?? []).map((p) => <option key={p.ma_phong_ban} value={p.ma_phong_ban}>{p.ten_phong_ban}</option>)}
        </select>
        <select value={loc.con_lam} onChange={(e) => setLoc({ ...loc, con_lam: e.target.value })}>
          <option value="true">Đang làm</option><option value="false">Đã nghỉ</option><option value="">Tất cả</option>
        </select>
      </div>
      <div className={`luoi-chi-tiet ${chon ? 'co-chi-tiet' : ''}`}>
        <The>
          <KhungTai tt={ds} rong="Không có nhân viên phù hợp.">
            {(dong) => <Bang dong={dong} khoa={(d) => d.ma_nhan_vien} chon={chon} khiChon={(d) => setChon(d.ma_nhan_vien)} cot={[
              { k: 'ma_nhan_vien', t: 'Mã' }, { k: 'ho_ten', t: 'Họ tên' },
              { k: 'ten_phong_ban', t: 'Phòng ban' }, { k: 'ten_chuc_vu', t: 'Chức vụ' },
              { k: 'trang_thai_lam_viec', t: '', ve: (d) => <Chip ma={d.trang_thai_lam_viec} /> },
            ]} />}
          </KhungTai>
        </The>
        {chon && <ChiTiet key={chon} ma={chon} laHR={laHR} dong={() => setChon(null)} xong={ds.taiLai} />}
      </div>
      <ThemNhanVien mo={moThem} dong={() => setMoThem(false)} pb={pb.duLieu ?? []}
        xong={(ma) => { ds.taiLai(); setChon(ma) }} />
    </Trang>
  )
}

function ChiTiet({ ma, laHR, dong, xong }) {
  const tt = useTai(() => api.get(`/nhan-vien/${ma}`), [ma])
  const [hop, setHop] = useState(null)   // 'sua' | 'hd' | 'dc' | 'nghi'
  const capNhat = () => { tt.taiLai(); xong() }
  return (
    <The tieuDe={tt.duLieu?.ho_so.ho_ten ?? ma} phai={<button className="nut-icon" onClick={dong} aria-label="Đóng">×</button>}>
      <KhungTai tt={tt}>
        {({ ho_so: hs, qua_trinh: qt, phep }) => (
          <>
            <TruongHoSo hs={hs} />
            {phep[0] && <p className="goi-y">Phép {phep[0].nam}: còn {dinhDangSo(phep[0].so_ngay_con_lai, 1)} /
              {' '}{dinhDangSo(phep[0].so_ngay_duoc_cap + phep[0].so_ngay_dieu_chinh, 1)} ngày</p>}
            {laHR && hs.trang_thai_lam_viec === 'DANG_LAM' && (
              <div className="hang-nut trai">
                <button className="nut nut-nho" onClick={() => setHop('sua')}>Sửa liên hệ</button>
                <button className="nut nut-nho nut-nhat" onClick={() => setHop('hd')}>Hợp đồng</button>
                <button className="nut nut-nho nut-nhat" onClick={() => setHop('dc')}>Điều chuyển</button>
                <button className="nut nut-nho nut-nhat" onClick={() => setHop('nghi')}>Nghỉ việc</button>
              </div>
            )}
            <h3 className="tieu-de-nho">Quá trình công tác</h3>
            <QuaTrinh ds={qt} />
            <ThaoTacHR loai={hop} hs={hs} dong={() => setHop(null)} xong={capNhat} />
          </>
        )}
      </KhungTai>
    </The>
  )
}

// Các hộp thoại thao tác HR. Mỗi form gửi đúng tham số của procedure tương ứng.
function ThaoTacHR({ loai, hs, dong, xong }) {
  const { dang, chay } = useThaoTac()
  const [f, setF] = useState({})
  const pb = useTai(() => (loai === 'dc' ? api.get('/danh-muc/PHONG_BAN') : Promise.resolve([])), [loai])
  const cv = useTai(() => (loai === 'dc' ? api.get('/danh-muc/CHUC_VU') : Promise.resolve([])), [loai])
  const lhd = useTai(() => (loai === 'hd' ? api.get('/danh-muc/LOAI_HOP_DONG') : Promise.resolve([])), [loai])
  const doi = (k) => (e) => setF({ ...f, [k]: e.target.value })
  const gui = (ham, thongBao) => (e) => {
    e.preventDefault()
    chay(ham, thongBao).then(() => { setF({}); dong(); xong() }).catch(() => {})
  }
  const ma = hs.ma_nhan_vien
  return (
    <>
      <HopThoai mo={loai === 'sua'} dong={dong} tieuDe="Sửa thông tin liên hệ">
        <form className="bieu-mau" onSubmit={gui(() => api.patch(`/nhan-vien/${ma}`, f), 'Đã cập nhật hồ sơ.')}>
          <TruongNhap nhan="Email"><input type="email" defaultValue={hs.email} onChange={doi('email')} /></TruongNhap>
          <TruongNhap nhan="Điện thoại"><input defaultValue={hs.so_dien_thoai} onChange={doi('so_dien_thoai')} /></TruongNhap>
          <TruongNhap nhan="Địa chỉ"><input defaultValue={hs.dia_chi} onChange={doi('dia_chi')} /></TruongNhap>
          <div className="hang-nut"><button className="nut" disabled={dang}>Lưu</button></div>
        </form>
      </HopThoai>
      <HopThoai mo={loai === 'hd'} dong={dong} tieuDe={`Hợp đồng mới – ${hs.ho_ten}`}>
        <form className="bieu-mau" onSubmit={gui(() => api.post(`/nhan-vien/${ma}/hop-dong`, {
          ...f, ngay_ket_thuc: f.ngay_ket_thuc || null,
          luong_co_ban: Number(f.luong_co_ban), can_cu_dong_bao_hiem: Number(f.can_cu_dong_bao_hiem || f.luong_co_ban),
        }), 'Đã lưu hợp đồng.')}>
          <div className="hang">
            <TruongNhap nhan="Số hợp đồng"><input required onChange={doi('so_hop_dong')} /></TruongNhap>
            <TruongNhap nhan="Loại"><select required defaultValue="" onChange={doi('ma_loai')}>
              <option value="" disabled>Chọn…</option>
              {(lhd.duLieu ?? []).map((l) => <option key={l.ma_loai} value={l.ma_loai}>{l.ten_loai}</option>)}
            </select></TruongNhap>
          </div>
          <div className="hang">
            <TruongNhap nhan="Bắt đầu"><input type="date" required onChange={doi('ngay_bat_dau')} /></TruongNhap>
            <TruongNhap nhan="Kết thúc" goiY="Bỏ trống nếu không xác định thời hạn">
              <input type="date" onChange={doi('ngay_ket_thuc')} /></TruongNhap>
          </div>
          <div className="hang">
            <TruongNhap nhan="Lương cơ bản (đ)"><input type="number" min="1" required onChange={doi('luong_co_ban')} /></TruongNhap>
            <TruongNhap nhan="Căn cứ đóng BH (đ)" goiY="Mặc định bằng lương cơ bản">
              <input type="number" min="1" onChange={doi('can_cu_dong_bao_hiem')} /></TruongNhap>
          </div>
          <div className="hang-nut"><button className="nut" disabled={dang}>Lưu hợp đồng</button></div>
        </form>
      </HopThoai>
      <HopThoai mo={loai === 'dc'} dong={dong} tieuDe={`Điều chuyển – ${hs.ho_ten}`}>
        <form className="bieu-mau" onSubmit={gui(() => api.post(`/nhan-vien/${ma}/dieu-chuyen`, f), 'Đã điều chuyển.')}>
          <div className="hang">
            <TruongNhap nhan="Phòng ban mới"><select required defaultValue="" onChange={doi('ma_phong_ban')}>
              <option value="" disabled>Chọn…</option>
              {(pb.duLieu ?? []).map((p) => <option key={p.ma_phong_ban} value={p.ma_phong_ban}>{p.ten_phong_ban}</option>)}
            </select></TruongNhap>
            <TruongNhap nhan="Chức vụ"><select required defaultValue="" onChange={doi('ma_chuc_vu')}>
              <option value="" disabled>Chọn…</option>
              {(cv.duLieu ?? []).map((c) => <option key={c.ma_chuc_vu} value={c.ma_chuc_vu}>{c.ten_chuc_vu}</option>)}
            </select></TruongNhap>
          </div>
          <TruongNhap nhan="Ngày hiệu lực"><input type="date" required onChange={doi('ngay_hieu_luc')} /></TruongNhap>
          <TruongNhap nhan="Căn cứ (số quyết định)"><input required onChange={doi('can_cu')} /></TruongNhap>
          <div className="hang-nut"><button className="nut" disabled={dang}>Điều chuyển</button></div>
        </form>
      </HopThoai>
      <HopThoai mo={loai === 'nghi'} dong={dong} tieuDe={`Cho nghỉ việc – ${hs.ho_ten}`} rong={420}>
        <form className="bieu-mau" onSubmit={gui(() => api.post(`/nhan-vien/${ma}/nghi-viec`, f), 'Đã ghi nhận nghỉ việc.')}>
          <TruongNhap nhan="Ngày nghỉ việc"><input type="date" required onChange={doi('ngay_nghi_viec')} /></TruongNhap>
          <div className="hang-nut"><button className="nut nut-do" disabled={dang}>Xác nhận</button></div>
        </form>
      </HopThoai>
    </>
  )
}

function ThemNhanVien({ mo, dong, pb, xong }) {
  const cv = useTai(() => api.get('/danh-muc/CHUC_VU'))
  const [f, setF] = useState({})
  const { dang, chay } = useThaoTac()
  const doi = (k) => (e) => setF({ ...f, [k]: e.target.value })
  const gui = (e) => {
    e.preventDefault()
    chay(() => api.post('/nhan-vien', f), `Đã thêm ${f.ho_ten}.`)
      .then(() => { dong(); xong(f.ma_nhan_vien.toUpperCase()); setF({}) }).catch(() => {})
  }
  return (
    <HopThoai mo={mo} dong={dong} tieuDe="Thêm nhân viên" rong={620}>
      <form className="bieu-mau" onSubmit={gui}>
        <div className="hang">
          <TruongNhap nhan="Mã nhân viên"><input required onChange={doi('ma_nhan_vien')} /></TruongNhap>
          <TruongNhap nhan="Họ tên"><input required onChange={doi('ho_ten')} /></TruongNhap>
        </div>
        <div className="hang">
          <TruongNhap nhan="Ngày sinh"><input type="date" required onChange={doi('ngay_sinh')} /></TruongNhap>
          <TruongNhap nhan="Số định danh (CCCD)"><input required onChange={doi('so_dinh_danh')} /></TruongNhap>
        </div>
        <div className="hang">
          <TruongNhap nhan="Email"><input type="email" required onChange={doi('email')} /></TruongNhap>
          <TruongNhap nhan="Điện thoại"><input onChange={doi('so_dien_thoai')} /></TruongNhap>
        </div>
        <div className="hang">
          <TruongNhap nhan="Mã số thuế"><input onChange={doi('ma_so_thue')} /></TruongNhap>
          <TruongNhap nhan="Địa chỉ"><input onChange={doi('dia_chi')} /></TruongNhap>
        </div>
        <div className="hang">
          <TruongNhap nhan="Ngày vào làm"><input type="date" required onChange={doi('ngay_vao_lam')} /></TruongNhap>
          <TruongNhap nhan="Phòng ban"><select required defaultValue="" onChange={doi('ma_phong_ban')}>
            <option value="" disabled>Chọn…</option>
            {pb.map((p) => <option key={p.ma_phong_ban} value={p.ma_phong_ban}>{p.ten_phong_ban}</option>)}
          </select></TruongNhap>
          <TruongNhap nhan="Chức vụ"><select required defaultValue="" onChange={doi('ma_chuc_vu')}>
            <option value="" disabled>Chọn…</option>
            {(cv.duLieu ?? []).map((c) => <option key={c.ma_chuc_vu} value={c.ma_chuc_vu}>{c.ten_chuc_vu}</option>)}
          </select></TruongNhap>
        </div>
        <p className="goi-y">Sau khi thêm, tạo hợp đồng ở phần chi tiết; tài khoản đăng nhập do Quản trị cấp.</p>
        <div className="hang-nut"><button className="nut" disabled={dang}>Thêm</button></div>
      </form>
    </HopThoai>
  )
}

