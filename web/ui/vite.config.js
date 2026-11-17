import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// /api chuyển tiếp sang FastAPI (cổng 8000): trình duyệt chỉ thấy MỘT nguồn
// (localhost:5173), nên cookie phiên SameSite=Strict hoạt động, không cần CORS.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // HRM_API: kiểm thử giao diện (tests/run_web.sh) chạy API ở cổng khác để không đụng bản đang dùng
    proxy: { '/api': process.env.HRM_API || 'http://127.0.0.1:8000' },
  },
})
