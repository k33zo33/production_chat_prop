#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
source "$ROOT_DIR/tool/smoke_common.sh"

smoke_print_flutter_banner "navigation-smoke" "$FLUTTER_BIN"
smoke_run_analyze "navigation-smoke" "$FLUTTER_BIN"

WIDGET_TEST_FILE="test/widget_test.dart"
SCENE_ROUTE_SYNC_TEST_FILE="test/widget/scene_route_sync_test.dart"
RECOVERY_TEST_FILE="test/widget/project_not_found_recovery_test.dart"

for path in "$WIDGET_TEST_FILE" "$SCENE_ROUTE_SYNC_TEST_FILE" "$RECOVERY_TEST_FILE"; do
  if [[ ! -f "$path" ]]; then
    echo "[navigation-smoke] missing expected test file: $path" >&2
    exit 1
  fi
done

declare -a WIDGET_TEST_NAMES=(
  "chat editor open playback action keeps the currently selected scene"
  "chat editor app bar playback action normalizes stale deep-link scene ids"
  "compact editor overflow playback action normalizes stale deep-link scene ids"
  "playback app bar navigation keeps the currently selected scene"
  "playback open editor defaults to the first scene before manual selection"
  "compact playback overflow open editor keeps the currently selected scene"
  "playback footer open editor keeps the currently selected scene"
  "portfolio preview ready CTA resets stale scene selection to the primary ready scene"
  "project card open playback prefers the first ready scene over a stale empty selection"
)

declare -a SCENE_ROUTE_SYNC_TEST_NAMES=(
  "chat editor keeps selected scene in the route query"
  "chat editor normalizes stale scene query ids after load"
  "chat editor follows external scene query changes after load"
  "playback keeps selected scene in the route query"
  "playback normalizes stale scene query ids after load"
  "playback follows external scene query changes after load"
)

declare -a RECOVERY_TEST_NAMES=(
  "missing editor route can recover by creating a starter project"
  "missing playback route can recover by opening a demo project"
  "missing project recovery can return to the project list"
)

for test_name in "${WIDGET_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$WIDGET_TEST_FILE"; then
    echo "[navigation-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${SCENE_ROUTE_SYNC_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$SCENE_ROUTE_SYNC_TEST_FILE"; then
    echo "[navigation-smoke] missing expected route-sync test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${RECOVERY_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$RECOVERY_TEST_FILE"; then
    echo "[navigation-smoke] missing expected recovery test: $test_name" >&2
    exit 1
  fi
done

WIDGET_TEST_PATTERN="$(printf '%s\n' "${WIDGET_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
SCENE_ROUTE_SYNC_TEST_PATTERN="$(printf '%s\n' "${SCENE_ROUTE_SYNC_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
RECOVERY_TEST_PATTERN="$(printf '%s\n' "${RECOVERY_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
COMBINED_TEST_PATTERN="${WIDGET_TEST_PATTERN}|${SCENE_ROUTE_SYNC_TEST_PATTERN}|${RECOVERY_TEST_PATTERN}"

echo "[navigation-smoke] tests: ${#WIDGET_TEST_NAMES[@]} navigation widget + ${#SCENE_ROUTE_SYNC_TEST_NAMES[@]} route-sync + ${#RECOVERY_TEST_NAMES[@]} recovery cases (batched)"
"$FLUTTER_BIN" test "$WIDGET_TEST_FILE" "$SCENE_ROUTE_SYNC_TEST_FILE" "$RECOVERY_TEST_FILE" --name "^(${COMBINED_TEST_PATTERN})$"

echo

echo "[navigation-smoke] manual follow-up"
echo "- If this targeted pass is green, keep browser back/forward and deep-link spot-checks in docs/08-web-smoke-checklist.md and docs/09-compact-smoke-checklist.md."
echo "- Then run ./tool/verify.sh before release or deploy decisions."

echo "[navigation-smoke] done"
