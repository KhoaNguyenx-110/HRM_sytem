// Định dạng hiển thị kiểu Việt Nam
const tien = new Intl.NumberFormat('vi-VN')

export const dinhDangTien = (v) => (v == null ? '—' : `${tien.format(Math.round(v))} đ`)
// Trong bảng: đơn vị (đ) ghi ở tiêu đề cột, ô chỉ có số
export const dinhDangDong = (v) => (v == null ? '—' : tien.format(Math.round(v)))
export const dinhDangSo = (v, chuSo = 2) =>
  v == null ? '—' : new Intl.NumberFormat('vi-VN', { maximumFractionDigits: chuSo }).format(v)

// API trả "2026-01-31T00:00:00" -> "31/01/2026"
export const dinhDangNgay = (v) => {
  if (!v) return '—'
  const [y, m, d] = String(v).slice(0, 10).split('-')
  return `${d}/${m}/${y}`
}
export const dinhDangGio = (v) => (v ? String(v).replace('T', ' ').slice(0, 16) : '—')
export const kyLuong = (thang, nam) => `${String(thang).padStart(2, '0')}/${nam}`

// Nhãn tiếng Việt cho mã trạng thái trong CSDL
export const NHAN = {
  MO: 'Đang mở', CHOT_CONG: 'Đã chốt công', DA_TINH: 'Đã tính', DA_KHOA: 'Đã khóa',
  CHO_DUYET: 'Chờ duyệt', DA_DUYET: 'Đã duyệt', TU_CHOI: 'Từ chối', DA_RUT: 'Đã rút',
  HOAT_DONG: 'Hoạt động', KHOA: 'Bị khóa', DANG_LAM: 'Đang làm', DA_NGHI: 'Đã nghỉ',
  NGHI_PHEP: 'Nghỉ phép', OT: 'Làm thêm giờ', KHEN_THUONG: 'Khen thưởng', PHAT_SINH_LUONG: 'Phát sinh lương',
  EMPLOYEE: 'Nhân viên', HR: 'Nhân sự', PAYROLL: 'Tiền lương', MANAGER: 'Trưởng phòng', ADMIN: 'Quản trị',
  INSERT: 'Thêm', UPDATE: 'Sửa', DELETE: 'Xóa',
}
export const nhan = (ma) => NHAN[ma] ?? ma

// Màu chip theo nhóm trạng thái
export const TONG_MAU = {
  MO: 'xanh', CHOT_CONG: 'vang', DA_TINH: 'vang', DA_KHOA: 'xam',
  CHO_DUYET: 'vang', DA_DUYET: 'luc', TU_CHOI: 'do', DA_RUT: 'xam',
  HOAT_DONG: 'luc', KHOA: 'do', DANG_LAM: 'luc', DA_NGHI: 'xam',
}
