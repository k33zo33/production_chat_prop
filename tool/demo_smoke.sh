#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
source "$ROOT_DIR/tool/smoke_common.sh"

smoke_print_flutter_banner "demo-smoke" "$FLUTTER_BIN"
smoke_run_analyze "demo-smoke" "$FLUTTER_BIN"

WIDGET_TEST_FILE="test/widget_test.dart"

if [[ ! -f "$WIDGET_TEST_FILE" ]]; then
  echo "[demo-smoke] missing expected test file: $WIDGET_TEST_FILE" >&2
  exit 1
fi

declare -a TEST_NAMES=(
  "add demo project action seeds prefilled project"
  "create project and navigate to chat editor from project card"
  "create project and navigate to playback from project card"
  "export all projects action shows empty portfolio feedback"
  "bulk project selection exports selected projects payload"
  "bulk project selection deletes multiple projects"
  "bulk project selection sets type for selected projects"
  "bulk project selection duplicates selected projects"
  "project popup copy json writes clipboard and shows feedback"
  "project popup download json copies fallback payload on unsupported platform"
  "import project json dialog adds new project card"
  "import project json dialog supports batch payload"
  "import json file button shows fallback when no file is selected"
  "import json file button imports project from picker payload"
  "portfolio preview ready CTA opens playback from summary card"
  "portfolio continue editing focuses first empty scene for attention projects"
  "portfolio review attention CTA opens editor for attention project"
  "compact playback scene selector switches demo scenes and resets progress"
  "compact demo flow stays usable across project list, editor, and playback"
  "playback stays responsive with imported 500+ messages"
  "video export button copies fallback package to clipboard when download is unavailable"
)

for test_name in "${TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$WIDGET_TEST_FILE"; then
    echo "[demo-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

TEST_PATTERN="$(printf '%s\n' "${TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"

echo "[demo-smoke] tests: ${#TEST_NAMES[@]} targeted demo/import/export cases"
"$FLUTTER_BIN" test "$WIDGET_TEST_FILE" --name "^(${TEST_PATTERN})$"

echo
echo "[demo-smoke] manual demo checklist"
echo "1) Run app: $FLUTTER_BIN run -d web-server"
echo "2) Create or load demo project from empty state"
echo "3) Open Chat Editor, tweak one message, return to Projects"
echo "4) Try Export All Projects JSON from top bar"
echo "5) Toggle Select Projects mode, bulk-select cards, then test Duplicate + Set Type + Export Selected + Delete Selected"
echo "6) Import payload with Import Project JSON (paste or file picker), batch payload + preview confirmation are supported"
echo "7) Repeat one pass at a narrow phone-ish width (~390px) and confirm compact overflow actions still work"
echo "8) Optionally stress-test with 500+ messages and verify playback stays responsive"
echo "9) Open Playback, verify controls + export feedback"
echo "10) Optional: follow docs/04-export-qa-checklist.md"

echo "[demo-smoke] done"
