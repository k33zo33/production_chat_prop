#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
SMOKE_COMMON_SCRIPT="$ROOT_DIR/tool/smoke_common.sh"

if [[ ! -f "$SMOKE_COMMON_SCRIPT" ]]; then
  echo "[verify] missing required script: $SMOKE_COMMON_SCRIPT" >&2
  exit 1
fi

source "$SMOKE_COMMON_SCRIPT"

WEB_SHELL_SMOKE_SCRIPT="$ROOT_DIR/tool/web_shell_smoke.sh"
BRAND_NEUTRALITY_SMOKE_SCRIPT="$ROOT_DIR/tool/brand_neutrality_smoke.sh"

for script_path in "$WEB_SHELL_SMOKE_SCRIPT" "$BRAND_NEUTRALITY_SMOKE_SCRIPT"; do
  if [[ ! -f "$script_path" ]]; then
    echo "[verify] missing required script: $script_path" >&2
    exit 1
  fi
done

smoke_print_flutter_banner "verify" "$FLUTTER_BIN"

if [[ "${SKIP_PUB_GET:-0}" == "1" ]]; then
  echo "[verify] pub get skipped (already resolved upstream)"
else
  echo "[verify] pub get"
  "$FLUTTER_BIN" pub get
fi

smoke_run_analyze "verify" "$FLUTTER_BIN"

echo "[verify] source web shell metadata"
"$WEB_SHELL_SMOKE_SCRIPT" web

echo "[verify] source brand-neutrality"
"$BRAND_NEUTRALITY_SMOKE_SCRIPT" lib web

echo "[verify] test"
"$FLUTTER_BIN" test

echo "[verify] build web"
"$FLUTTER_BIN" build web

echo "[verify] built web shell metadata"
"$WEB_SHELL_SMOKE_SCRIPT" build/web

echo "[verify] built web brand-neutrality"
"$BRAND_NEUTRALITY_SMOKE_SCRIPT" build/web

echo "[verify] done"
