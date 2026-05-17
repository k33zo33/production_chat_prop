#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
source "$ROOT_DIR/tool/smoke_common.sh"
DEMO_SMOKE_SCRIPT="./tool/demo_smoke.sh"
IMPORT_SMOKE_SCRIPT="./tool/import_smoke.sh"
RELEASE_SMOKE_SCRIPT="./tool/release_smoke.sh"
COMPACT_SMOKE_SCRIPT="./tool/compact_smoke.sh"
VERIFY_SCRIPT="./tool/verify.sh"
WEB_SHELL_SMOKE_SCRIPT="./tool/web_shell_smoke.sh"
DOCS_HANDOFF_SMOKE_SCRIPT="./tool/docs_handoff_smoke.sh"

for script_path in "$DEMO_SMOKE_SCRIPT" "$IMPORT_SMOKE_SCRIPT" "$RELEASE_SMOKE_SCRIPT" "$COMPACT_SMOKE_SCRIPT" "$VERIFY_SCRIPT" "$WEB_SHELL_SMOKE_SCRIPT" "$DOCS_HANDOFF_SMOKE_SCRIPT"; do
  if [[ ! -f "$script_path" ]]; then
    echo "[beta-handoff] missing required script: $script_path" >&2
    exit 1
  fi

done

smoke_print_flutter_banner "beta-handoff" "$FLUTTER_BIN"

echo "[beta-handoff] pub get"
"$FLUTTER_BIN" pub get

smoke_run_analyze "beta-handoff" "$FLUTTER_BIN"

export SMOKE_SKIP_VERSION=1
export SMOKE_SKIP_ANALYZE=1

echo "[beta-handoff] docs/release instructions preflight"
"$DOCS_HANDOFF_SMOKE_SCRIPT"

echo "[beta-handoff] web shell metadata preflight"
"$WEB_SHELL_SMOKE_SCRIPT" web

echo "[beta-handoff] demo flow preflight"
"$DEMO_SMOKE_SCRIPT"

echo
echo "[beta-handoff] import/recovery preflight"
"$IMPORT_SMOKE_SCRIPT"

echo
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
echo "- docs/11-video-fallback-workflow.md"
echo "[beta-handoff] done"
