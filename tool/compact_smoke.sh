#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
source "$ROOT_DIR/tool/smoke_common.sh"

smoke_print_flutter_banner "compact-smoke" "$FLUTTER_BIN"
smoke_run_analyze "compact-smoke" "$FLUTTER_BIN"

declare -a TEST_NAMES=(
  "compact project delete confirmation stays usable on narrow screens"
  "compact project delete confirmation keeps long project names readable on narrow screens"
  "compact editor and playback headers clamp long project names without exceptions"
  "compact project list app bar uses overflow menu actions"
  "ultra-compact project list uses one scroll and keeps lower cards reachable"
  "compact project list search, filters, and sort controls stay usable on narrow screens"
  "compact selection overflow keeps bulk actions reachable on narrow screens"
  "compact portfolio readiness stacks summary actions on narrow screens"
  "compact portfolio readiness attention action opens editor on narrow screens"
  "compact portfolio preview ready action opens playback on narrow screens"
  "compact portfolio continue editing focuses first empty scene for attention projects"
  "compact chat editor app bar uses overflow navigation actions"
  "compact chat editor keeps scene actions in overflow menu"
  "compact chat editor scene selector shows current scene context on narrow screens"
  "compact scene settings dialog stays usable on narrow screens"
  "compact scene settings keep manual style entry preview in sync"
  "compact scene settings keep legacy style aliases in sync"
  "ultra-compact chat editor composer stays usable on phone-width screens"
  "compact character manager keeps actions usable through overflow menu"
  "compact playback app bar uses overflow navigation actions"
  "compact playback export and transport controls remain usable"
  "compact playback scene selector switches demo scenes and resets progress"
  "compact playback scene switch resets deep preview scroll in long scenes"
  "compact playback focus preview stays usable on narrow screens"
  "compact playback video fallback export reflects preview toggles and aspect ratio"
  "ultra-compact playback footer actions expose navigation actions on phone-width screens"
  "compact demo flow stays usable across project list, editor, and playback"
)

WIDGET_TEST_FILE="test/widget_test.dart"
RECOVERY_TEST_FILE="test/widget/project_not_found_recovery_test.dart"

if [[ ! -f "$WIDGET_TEST_FILE" ]]; then
  echo "[compact-smoke] missing expected test file: $WIDGET_TEST_FILE" >&2
  exit 1
fi

if [[ ! -f "$RECOVERY_TEST_FILE" ]]; then
  echo "[compact-smoke] missing expected recovery test file: $RECOVERY_TEST_FILE" >&2
  exit 1
fi

for test_name in "${TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$WIDGET_TEST_FILE"; then
    echo "[compact-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

declare -a RECOVERY_TEST_NAMES=(
  "compact missing-project recovery stacks actions on phone-width screens"
  "wide missing-project recovery keeps wrap actions on roomy screens"
  "missing editor route can recover by creating a starter project"
  "missing playback route can recover by opening a demo project"
  "missing project recovery can return to the project list"
)

for test_name in "${RECOVERY_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$RECOVERY_TEST_FILE"; then
    echo "[compact-smoke] missing expected recovery test: $test_name" >&2
    exit 1
  fi
done

TEST_PATTERN="$(printf '%s\n' "${TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
RECOVERY_TEST_PATTERN="$(printf '%s\n' "${RECOVERY_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
COMBINED_TEST_PATTERN="${TEST_PATTERN}|${RECOVERY_TEST_PATTERN}"

echo "[compact-smoke] tests: ${#TEST_NAMES[@]} compact/export + ${#RECOVERY_TEST_NAMES[@]} recovery/layout cases (batched)"
"$FLUTTER_BIN" test "$WIDGET_TEST_FILE" "$RECOVERY_TEST_FILE" --name "^(${COMBINED_TEST_PATTERN})$"

echo

echo "[compact-smoke] manual follow-up"
echo "- If this targeted pass is green, run ./tool/verify.sh before release or deploy decisions."
echo "- Then do the human browser pass from docs/08-web-smoke-checklist.md, docs/09-compact-smoke-checklist.md, and docs/04-export-qa-checklist.md."

echo "[compact-smoke] done"
