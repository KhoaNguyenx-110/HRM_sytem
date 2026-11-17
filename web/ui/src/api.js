// Gọi Web API. Mọi lỗi trả về dạng { loi, ma } (câu tiếng Việt lấy từ CSDL);
// ở đây biến thành Error để màn hình hiện thẳng cho người dùng.

export class LoiApi extends Error {
  constructor(status, loi, ma) {
    super(loi || 'Có lỗi xảy ra.')
    this.status = status
    this.ma = ma
  }
}

// Màn hình đăng nhập đăng ký hàm này để bị gọi khi phiên hết hạn (401)
let khiHetPhien = () => {}
export const datKhiHetPhien = (fn) => { khiHetPhien = fn }

async function goi(phuongThuc, url, duLieu, { boQua401 = false } = {}) {
  const res = await fetch(`/api${url}`, {
    method: phuongThuc,
    headers: duLieu ? { 'Content-Type': 'application/json' } : {},
    body: duLieu ? JSON.stringify(duLieu) : undefined,
    credentials: 'same-origin',
  })
  if (res.status === 204) return null
  const json = await res.json().catch(() => ({}))
  if (!res.ok) {
    if (res.status === 401 && !boQua401) khiHetPhien()
    // 422: FastAPI kiểm tra kiểu dữ liệu (vd thiếu trường) trước khi tới CSDL
    const loi = res.status === 422 ? 'Dữ liệu nhập chưa đủ hoặc sai định dạng.' : json.loi
    throw new LoiApi(res.status, loi, json.ma)
  }
  return json
}

export const api = {
  get: (url, opt) => goi('GET', url, null, opt),
  post: (url, duLieu, opt) => goi('POST', url, duLieu ?? {}, opt),
  patch: (url, duLieu) => goi('PATCH', url, duLieu),
  del: (url) => goi('DELETE', url),
}

// Tạo chuỗi truy vấn, bỏ tham số rỗng
export const qs = (o) => {
  const s = new URLSearchParams(Object.entries(o).filter(([, v]) => v !== '' && v != null)).toString()
  return s ? `?${s}` : ''
}
