#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"

echo "[verify] using flutter: $FLUTTER_BIN"
"$FLUTTER_BIN" --version

echo "[verify] pub get"
"$FLUTTER_BIN" pub get

echo "[verify] analyze"
"$FLUTTER_BIN" analyze

echo "[verify] test"
"$FLUTTER_BIN" test

echo "[verify] build web"
"$FLUTTER_BIN" build web

echo "[verify] done"
