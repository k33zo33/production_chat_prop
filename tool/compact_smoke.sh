#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"

echo "[compact-smoke] using flutter: $FLUTTER_BIN"
"$FLUTTER_BIN" --version

echo "[compact-smoke] analyze"
"$FLUTTER_BIN" analyze

declare -a TEST_NAMES=(
  "compact project list app bar uses overflow menu actions"
  "ultra-compact project list uses one scroll and keeps lower cards reachable"
  "compact selection overflow keeps bulk actions reachable on narrow screens"
  "compact chat editor app bar uses overflow navigation actions"
  "compact chat editor keeps scene actions in overflow menu"
  "compact chat editor scene selector shows current scene context on narrow screens"
  "compact scene settings dialog stays usable on narrow screens"
  "ultra-compact chat editor composer stays usable on phone-width screens"
  "compact character manager keeps actions usable through overflow menu"
  "compact playback app bar uses overflow navigation actions"
  "compact playback export and transport controls remain usable"
  "compact playback scene selector switches demo scenes and resets progress"
  "compact playback scene switch resets deep preview scroll in long scenes"
  "compact playback video fallback export reflects preview toggles and aspect ratio"
  "ultra-compact playback footer actions expose navigation actions on phone-width screens"
  "compact demo flow stays usable across project list, editor, and playback"
)

WIDGET_TEST_FILE="test/widget_test.dart"

if [[ ! -f "$WIDGET_TEST_FILE" ]]; then
  echo "[compact-smoke] missing expected test file: $WIDGET_TEST_FILE" >&2
  exit 1
fi

for test_name in "${TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$WIDGET_TEST_FILE"; then
    echo "[compact-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

TEST_PATTERN="$(printf '%s\n' "${TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"

echo "[compact-smoke] tests: ${#TEST_NAMES[@]} targeted compact/export cases"
"$FLUTTER_BIN" test "$WIDGET_TEST_FILE" --name "^(${TEST_PATTERN})$"

echo

echo "[compact-smoke] manual follow-up"
echo "- If this targeted pass is green, run ./tool/verify.sh before release or deploy decisions."
echo "- Then do the human browser pass from docs/08-web-smoke-checklist.md, docs/09-compact-smoke-checklist.md, and docs/04-export-qa-checklist.md."

echo "[compact-smoke] done"
