#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Dung du lieu luong demo tren CSDL vua rebuild (cho bao cao QR-17..24, demo DBeaver):
#   ky 01, 02/2026 DA_KHOA; ky 03/2026 DA_TINH (tam tinh)
# Dung: scripts/rebuild.sh && scripts/demo_luong.sh
# -----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."
scripts/run.sh U_HR01  scripts/demo/01_chot_cong_hr01.sql 2>&1 | grep -E '^Da |FAIL|ORA-' || true
scripts/run.sh U_PAY01 scripts/demo/02_tinh_luong_pay01.sql 2>&1 | grep -E '^Da |FAIL|ORA-' || true
