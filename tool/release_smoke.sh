#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"

echo "[release-smoke] using flutter: $FLUTTER_BIN"
"$FLUTTER_BIN" --version

echo "[release-smoke] analyze"
"$FLUTTER_BIN" analyze

WIDGET_TEST_FILE="test/widget_test.dart"

if [[ ! -f "$WIDGET_TEST_FILE" ]]; then
  echo "[release-smoke] missing expected test file: $WIDGET_TEST_FILE" >&2
  exit 1
fi

declare -a TEST_NAMES=(
  "playback preview expands on wide layouts and clarifies export scaling"
  "playback preview surface and export target follow aspect ratio"
  "playback export buttons are disabled for empty scenes"
  "empty playback scene shows recovery guidance and disables transport controls"
  "playback preview toggles affect screenshot export feedback"
  "video export button copies fallback package to clipboard when download is unavailable"
  "changing aspect ratio keeps playback progress stable"
  "long chat scene keeps playback controls and export available"
  "playback stays responsive with imported 500+ messages"
)

for test_name in "${TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$WIDGET_TEST_FILE"; then
    echo "[release-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

TEST_PATTERN="$(printf '%s\n' "${TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"

echo "[release-smoke] tests: ${#TEST_NAMES[@]} targeted export/reliability cases"
"$FLUTTER_BIN" test "$WIDGET_TEST_FILE" --name "^(${TEST_PATTERN})$"

echo

echo "[release-smoke] manual follow-up"
echo "- This is a fast preflight, not a replacement for ./tool/verify.sh."
echo "- Then do the browser pass from docs/08-web-smoke-checklist.md."
echo "- Repeat the phone-width pass from docs/09-compact-smoke-checklist.md."
echo "- Finish with docs/04-export-qa-checklist.md before a release/deploy decision."

echo "[release-smoke] done"
