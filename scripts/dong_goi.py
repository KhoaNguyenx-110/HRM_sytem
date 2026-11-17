"""Đóng gói mã nguồn nộp bài: docs/He_thong_Quan_ly_Nhan_su_va_Tinh_luong.zip

Gồm: SQL/PLSQL/RMAN, script bash, ứng dụng web (API Python + giao diện React),
README. KHÔNG gồm: .env (mật khẩu), .venv, node_modules, bản build, kết quả chạy,
bản sao lưu, file xuất lương, docs/.
Chạy: python scripts/dong_goi.py
"""
import zipfile
from pathlib import Path

GOC = Path(__file__).resolve().parents[1]
RA = GOC / "docs" / "He_thong_Quan_ly_Nhan_su_va_Tinh_luong.zip"

DUOI = {".sql", ".rman", ".sh", ".py", ".js", ".jsx", ".css", ".html", ".json", ".md", ".txt"}
BO_THU_MUC = {".git", ".venv", "node_modules", "dist", "__pycache__", ".pytest_cache", "docs", "exports",
              "backup", "ket_qua", "tmp"}
BO_FILE = {".env"}


def lay_file():
    for p in sorted(GOC.rglob("*")):
        tuong_doi = p.relative_to(GOC)
        if not p.is_file() or p.name in BO_FILE or p.suffix.lower() not in DUOI:
            continue
        # backup/ ở gốc là bản sao lưu; scripts/backup, tests/backup là mã nguồn -> giữ
        phan = tuong_doi.parts
        if any(x in BO_THU_MUC for x in phan[:-1]) and not (
                "backup" in phan[:-1] and phan[0] != "backup" and not {"ket_qua"} & set(phan)):
            continue
        yield p, tuong_doi


def main():
    RA.parent.mkdir(exist_ok=True)
    so = 0
    with zipfile.ZipFile(RA, "w", zipfile.ZIP_DEFLATED) as z:
        for p, tuong_doi in lay_file():
            z.write(p, tuong_doi.as_posix())
            so += 1
    print(f"Da dong goi {so} file -> {RA.relative_to(GOC)} ({RA.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
