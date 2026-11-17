#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bo kiem thu kenh web (GD 7):
#   TC-56  CSDL : HRM_APP chi thay du lieu qua view loc theo HRM_CTX (SQL*Plus)
#   TC-57  API  : dang nhap, phien, khong ro ri danh tinh qua pool (pytest)
#   TC-58  API  : luong nghiep vu theo 5 vai tro, net NV_A 01/2026 = 35.635.200 (pytest)
#   TC-59  UI   : thao tac that tren trinh duyet Edge (Playwright) qua API + Vite
# Moi phan bat dau tu CSDL demo vua dung lai + mat khau web; cuoi cung tra CSDL ve demo.
#   tests/run_web.sh            chay tat ca
#   tests/run_web.sh --giu      giu trang thai sau kiem thu
#   tests/run_web.sh --bo-ui    bo qua TC-59 (may khong co Edge / Node)
# TC-59 bat API o cong 8001 va Vite o 5174 de khong dung ban dang chay (8000/5173).
# Can: web/api/.venv, web/ui/node_modules (xem web/README.md)
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."
GOC=$PWD
PY=$GOC/web/api/.venv/Scripts/python
[[ -x $PY ]] || PY=$GOC/web/api/.venv/bin/python
[[ -x $PY ]] || { echo "FAIL  chua co web/api/.venv (xem web/README.md)"; exit 1; }
CO_UI=1; GIU=0
for a in "$@"; do [[ $a == --bo-ui ]] && CO_UI=0; [[ $a == --giu ]] && GIU=1; done

dung_demo() {
  scripts/rebuild.sh > /dev/null 2>&1 || { echo "FAIL  rebuild"; exit 1; }
  "$PY" web/api/cong_cu/dat_mat_khau_demo.py | grep -E '^Da |FAIL' || { echo "FAIL  dat mat khau demo"; exit 1; }
}
# pytest -rA: moi ca mot dong "PASSED|FAILED tests/x.py::ten" -> dong PASS/FAIL chung
pytest_ra_tc() {
  awk 'function tc(s) { return s ~ /test_giao_dien/ ? "TC-59" : s ~ /test_nghiep_vu/ ? "TC-58" : "TC-57" }
       /^PASSED / { sub(/^PASSED /, ""); print "PASS  " tc($0) " " $0 }
       /^(FAILED|ERROR) / { sub(/^(FAILED|ERROR) /, ""); print "FAIL  " tc($0) " " $0 }
       /[0-9]+ (passed|failed|error)/ { print "      " $0 }'
}

echo "=== Dung lai CSDL demo + mat khau web"
dung_demo

echo "--- TC-56 (user HRM_APP)"
scripts/run.sh HRM_APP tests/web/tc56_hrm_app.sql 2>&1 | grep -E 'PASS|FAIL|ORA-|PLS-|SP2-' || true

echo "--- TC-57, TC-58 API (pytest)"
(cd web/api && "$PY" -m pytest -q -rA -p no:cacheprovider --ignore=tests/test_giao_dien.py 2>&1) | pytest_ra_tc

if [[ $CO_UI == 1 ]]; then
  echo "--- TC-59 giao dien (Edge + Playwright)"
  dung_demo
  (cd web/api && exec "$PY" -m uvicorn app.main:app --port 8001 --log-level warning) > /dev/null 2>&1 &
  P_API=$!
  (cd web/ui && HRM_API=http://127.0.0.1:8001 exec npx vite --port 5174 --strictPort) > /dev/null 2>&1 &
  P_UI=$!
  san_sang=0
  for _ in $(seq 1 60); do
    curl -sf http://localhost:5174/api/suc-khoe > /dev/null 2>&1 && { san_sang=1; break; }
    sleep 1
  done
  if [[ $san_sang == 1 ]]; then
    (cd web/api && WEB_UI_URL=http://localhost:5174 "$PY" -m pytest -q -rA -p no:cacheprovider tests/test_giao_dien.py 2>&1) | pytest_ra_tc
  else
    echo "FAIL  TC-59 khong bat duoc API/Vite o cong 8001/5174"
  fi
  # Tat ca cay tien trinh (npx -> node vite; tren Windows dung taskkill /T)
  for p in $P_UI $P_API; do
    if command -v taskkill > /dev/null; then
      taskkill //F //T //PID "$(cat /proc/$p/winpid 2>/dev/null || echo $p)" > /dev/null 2>&1
    fi
    kill $p 2>/dev/null
  done
fi

if [[ $GIU == 0 ]]; then
  echo "=== Tra CSDL ve du lieu mau"
  scripts/rebuild.sh > /dev/null 2>&1 && echo "Da dung lai CSDL" || echo "FAIL  rebuild cuoi"
fi
