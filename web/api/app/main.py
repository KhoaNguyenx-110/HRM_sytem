"""Backend Web API của HRM (GĐ 7). Chạy:  .venv/Scripts/uvicorn app.main:app --port 8000

Lớp này MỎNG: không chứa nghiệp vụ. Mọi kiểm tra vai trò, phạm vi dữ liệu, ràng
buộc và audit đều nằm trong CSDL (package + view lọc theo HRM_CTX).
"""
import logging
from contextlib import asynccontextmanager

import oracledb
from fastapi import FastAPI

from .cau_hinh import doc_cau_hinh
from .csdl import dong_pool, tao_pool
from .loi import LoiNghiepVu, xu_ly_loi_nghiep_vu, xu_ly_loi_oracle
from .routers import ca_nhan, danh_muc, duyet, luong, nhan_su, quan_tri, xac_thuc

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def vong_doi(app: FastAPI):
    app.state.cau_hinh = doc_cau_hinh()
    tao_pool(app.state.cau_hinh)
    yield
    await dong_pool()


app = FastAPI(title="HRM Oracle – Web API", lifespan=vong_doi)
app.add_exception_handler(oracledb.DatabaseError, xu_ly_loi_oracle)
app.add_exception_handler(LoiNghiepVu, xu_ly_loi_nghiep_vu)
for r in (xac_thuc, ca_nhan, danh_muc, duyet, nhan_su, luong, quan_tri):
    app.include_router(r.router)


@app.get("/api/suc-khoe")
async def suc_khoe():
    return {"ok": True}
