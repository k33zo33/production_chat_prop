#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
source "$ROOT_DIR/tool/smoke_common.sh"

smoke_print_flutter_banner "verify" "$FLUTTER_BIN"

if [[ "${SKIP_PUB_GET:-0}" == "1" ]]; then
  echo "[verify] pub get skipped (already resolved upstream)"
else
  echo "[verify] pub get"
  "$FLUTTER_BIN" pub get
fi

smoke_run_analyze "verify" "$FLUTTER_BIN"

echo "[verify] test"
"$FLUTTER_BIN" test

echo "[verify] build web"
"$FLUTTER_BIN" build web

echo "[verify] done"
