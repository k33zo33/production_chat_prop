#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
RELEASE_SMOKE_SCRIPT="./tool/release_smoke.sh"
COMPACT_SMOKE_SCRIPT="./tool/compact_smoke.sh"
VERIFY_SCRIPT="./tool/verify.sh"
WEB_SHELL_SMOKE_SCRIPT="./tool/web_shell_smoke.sh"

for script_path in "$RELEASE_SMOKE_SCRIPT" "$COMPACT_SMOKE_SCRIPT" "$VERIFY_SCRIPT" "$WEB_SHELL_SMOKE_SCRIPT"; do
  if [[ ! -f "$script_path" ]]; then
    echo "[beta-handoff] missing required script: $script_path" >&2
    exit 1
  fi

done

echo "[beta-handoff] using flutter: $FLUTTER_BIN"
"$FLUTTER_BIN" --version

echo "[beta-handoff] pub get"
"$FLUTTER_BIN" pub get

echo "[beta-handoff] web shell metadata preflight"
"$WEB_SHELL_SMOKE_SCRIPT" web

echo "[beta-handoff] release preflight"
"$RELEASE_SMOKE_SCRIPT"

echo
echo "[beta-handoff] compact/mobile preflight"
"$COMPACT_SMOKE_SCRIPT"

echo
echo "[beta-handoff] full verification gate"
SKIP_PUB_GET=1 "$VERIFY_SCRIPT"

echo
echo "[beta-handoff] built web shell metadata check"
"$WEB_SHELL_SMOKE_SCRIPT" build/web

echo
echo "[beta-handoff] manual follow-up"
echo "- docs/08-web-smoke-checklist.md"
echo "- docs/09-compact-smoke-checklist.md"
echo "- docs/04-export-qa-checklist.md"
echo "[beta-handoff] done"
