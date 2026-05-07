#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RELEASE_SMOKE_SCRIPT="./tool/release_smoke.sh"
COMPACT_SMOKE_SCRIPT="./tool/compact_smoke.sh"
VERIFY_SCRIPT="./tool/verify.sh"

for script_path in "$RELEASE_SMOKE_SCRIPT" "$COMPACT_SMOKE_SCRIPT" "$VERIFY_SCRIPT"; do
  if [[ ! -f "$script_path" ]]; then
    echo "[beta-handoff] missing required script: $script_path" >&2
    exit 1
  fi

done

echo "[beta-handoff] release preflight"
"$RELEASE_SMOKE_SCRIPT"

echo
echo "[beta-handoff] compact/mobile preflight"
"$COMPACT_SMOKE_SCRIPT"

echo
echo "[beta-handoff] full verification gate"
"$VERIFY_SCRIPT"

echo
echo "[beta-handoff] manual follow-up"
echo "- docs/08-web-smoke-checklist.md"
echo "- docs/09-compact-smoke-checklist.md"
echo "- docs/04-export-qa-checklist.md"
echo "[beta-handoff] done"
