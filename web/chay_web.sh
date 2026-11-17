#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Chay ung dung web tren may phat trien:
#   1. (tuy chon --demo) dung lai CSDL demo
#   2. dat mat khau web cho tai khoan demo (chay lai khong sao)
#   3. FastAPI cong 8000 (nen) + Vite cong 5173
# Mo http://localhost:5173 ; Ctrl+C de dung ca hai.
# Can: web/api/.venv va web/ui/node_modules (xem web/README.md)
# -----------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."
PY=web/api/.venv/Scripts/python; [[ -x $PY ]] || PY=web/api/.venv/bin/python
[[ "${1:-}" == "--demo" ]] && { echo "Dung lai CSDL demo..."; scripts/rebuild.sh > /dev/null; }
$PY web/api/cong_cu/dat_mat_khau_demo.py
(cd web/api && exec ../../$PY -m uvicorn app.main:app --port 8000 --log-level warning) &
API=$!
trap 'kill $API 2>/dev/null' EXIT
cd web/ui && npx vite --port 5173 --strictPort
