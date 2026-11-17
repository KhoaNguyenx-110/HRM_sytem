// Nhật ký hệ thống (VW-10): mỗi vai trò thấy phần của mình. Mở một dòng để xem
// trường nào đổi từ giá trị nào sang giá trị nào.
import { Fragment, useState } from 'react'
import { api, qs } from '../api'
import { KhungTai, The, Trang, useTai } from '../ui/chung'
import { dinhDangGio, nhan } from '../ui/dinh_dang'

function ChenhLech({ cu, moi }) {
  const khoa = [...new Set([...Object.keys(cu ?? {}), ...Object.keys(moi ?? {})])]
  const doi = khoa.filter((k) => JSON.stringify(cu?.[k]) !== JSON.stringify(moi?.[k]))
  if (!doi.length) return <p className="goi-y">Không có trường nào đổi giá trị.</p>
  return (
    <table className="bang bang-nho">
      <thead><tr><th>Trường</th><th>Trước</th><th>Sau</th></tr></thead>
      <tbody>{doi.map((k) => <tr key={k}><td>{k}</td><td>{String(cu?.[k] ?? '—')}</td><td>{String(moi?.[k] ?? '—')}</td></tr>)}</tbody>
    </table>
  )
}

export default function NhatKy() {
  const [dt, setDt] = useState('')
  const tt = useTai(() => api.get(`/nhat-ky${qs({ doi_tuong: dt })}`), [dt])
  const [mo, setMo] = useState(null)
  const doiTuong = [...new Set((tt.duLieu ?? []).map((d) => d.doi_tuong))]
  return (
    <Trang tieuDe="Nhật ký hệ thống" moTa="Chỉ ghi thêm; không ai sửa hay xóa được (kể cả chủ sở hữu CSDL).">
      <div className="thanh-loc">
        <select value={dt} onChange={(e) => setDt(e.target.value)}>
          <option value="">Mọi đối tượng</option>
          {doiTuong.map((d) => <option key={d} value={d}>{d}</option>)}
        </select>
      </div>
      <The>
        <KhungTai tt={tt} rong="Không có dòng nhật ký trong phạm vi bạn được xem.">
          {(ds) => (
            <div className="bang-cuon">
              <table className="bang">
                <thead><tr><th>Thời điểm</th><th>Người thực hiện</th><th>Đối tượng</th><th>Khóa</th><th>Thao tác</th></tr></thead>
                <tbody>
                  {ds.map((d) => (
                    <Fragment key={d.nhat_ky_id}>
                      <tr className="bam-duoc" onClick={() => setMo(mo === d.nhat_ky_id ? null : d.nhat_ky_id)}>
                        <td>{dinhDangGio(d.thoi_diem)}</td><td>{d.ten_dang_nhap ?? d.oracle_username}</td>
                        <td>{d.doi_tuong}</td><td>{d.khoa_ban_ghi}</td><td>{nhan(d.thao_tac)}</td>
                      </tr>
                      {mo === d.nhat_ky_id && (
                        <tr><td colSpan={5} className="o-mo-rong">
                          <ChenhLech cu={d.gia_tri_cu} moi={d.gia_tri_moi} />
                        </td></tr>
                      )}
                    </Fragment>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </KhungTai>
      </The>
    </Trang>
  )
}
