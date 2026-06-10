#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
source "$ROOT_DIR/tool/smoke_common.sh"

smoke_print_flutter_banner "release-smoke" "$FLUTTER_BIN"
smoke_run_analyze "release-smoke" "$FLUTTER_BIN"

declare -a WIDGET_TEST_FILES=(
  "test/widget_test.dart"
  "test/widget/playback_export_feedback_test.dart"
  "test/widget/project_not_found_recovery_test.dart"
  "test/widget/scene_route_sync_test.dart"
)

for widget_test_file in "${WIDGET_TEST_FILES[@]}"; do
  if [[ ! -f "$widget_test_file" ]]; then
    echo "[release-smoke] missing expected test file: $widget_test_file" >&2
    exit 1
  fi
done

declare -a TEST_NAMES=(
  "compact project list app bar uses overflow menu actions"
  "compact chat editor app bar uses overflow navigation actions"
  "compact chat editor keeps scene actions in overflow menu"
  "compact chat editor scene selector shows current scene context on narrow screens"
  "ultra-compact chat editor composer stays usable on phone-width screens"
  "compact playback app bar uses overflow navigation actions"
  "compact playback export and transport controls remain usable"
  "ultra-compact playback actions stay usable on phone-width screens"
  "compact playback scene selector switches demo scenes and resets progress"
  "compact playback scene switch resets deep preview scroll in long scenes"
  "compact playback focus preview stays usable on narrow screens"
  "compact demo flow stays usable across project list, editor, and playback"
  "compact missing-project recovery stacks actions on phone-width screens"
  "chat editor keeps selected scene in the route query"
  "chat editor normalizes stale scene query ids after load"
  "chat editor follows external scene query changes after load"
  "chat editor restores selected scene query when external route clears it"
  "chat editor rewrites the route query when the selected trailing scene is deleted"
  "chat editor rewrites the route query when the selected leading scene is deleted"
  "playback keeps selected scene in the route query"
  "playback normalizes stale scene query ids after load"
  "playback follows external scene query changes after load"
  "playback restores selected scene query when external route clears it"
  "playback rewrites the route query when the selected trailing scene is deleted"
  "playback rewrites the route query when the selected leading scene is deleted"
  "playback preview expands on wide layouts and clarifies export scaling"
  "playback focus preview opens with transport controls and closes cleanly"
  "focus preview transport controls scrub and jump between cues"
  "focus preview responds to keyboard play pause and restart shortcuts"
  "playback preview auto-follows deep cues in long scenes"
  "playback preview surface and export target follow aspect ratio"
  "playback export buttons are disabled for empty scenes"
  "empty playback scene shows recovery guidance and disables transport controls"
  "playback preview toggles affect screenshot export feedback"
  "video export button copies fallback package to clipboard when download is unavailable"
  "changing aspect ratio keeps playback progress stable"
  "long chat scene keeps playback controls and export available"
  "playback stays responsive with imported 500+ messages"
)

declare -a UNIT_TEST_FILES=(
  "test/unit/core/utils/export_file_name_test.dart"
  "test/unit/features/playback/data/services/screenshot_export_service_test.dart"
  "test/unit/features/playback/data/services/video_export_fallback_service_test.dart"
  "test/unit/features/playback/domain/playback_timeline_test.dart"
  "test/unit/features/projects/data/services/project_package_export_service_test.dart"
  "test/unit/features/projects/data/services/project_portfolio_export_service_test.dart"
  "test/unit/features/projects/domain/export_qa_fixture_test.dart"
)

for test_name in "${TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "${WIDGET_TEST_FILES[@]}"; then
    echo "[release-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

for unit_test_file in "${UNIT_TEST_FILES[@]}"; do
  if [[ ! -f "$unit_test_file" ]]; then
    echo "[release-smoke] missing expected unit test file: $unit_test_file" >&2
    exit 1
  fi
done

TEST_PATTERN="$(printf '%s\n' "${TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"

echo "[release-smoke] widget tests: ${#TEST_NAMES[@]} targeted compact/export/reliability cases"
"$FLUTTER_BIN" test "${WIDGET_TEST_FILES[@]}" --name "^(${TEST_PATTERN})$"

echo

echo "[release-smoke] unit tests: ${#UNIT_TEST_FILES[@]} export payload and filename cases (batched)"
"$FLUTTER_BIN" test "${UNIT_TEST_FILES[@]}"

echo

echo "[release-smoke] manual follow-up"
echo "- This is a fast preflight, not a replacement for ./tool/verify.sh."
echo "- It now covers key compact-width, scene deep-link sync/stale-link recovery, export, and focus-preview regressions automatically."
echo "- Then do the browser pass from docs/08-web-smoke-checklist.md for real browser history/back-forward behavior and visual confirmation."
echo "- Repeat the phone-width pass from docs/09-compact-smoke-checklist.md for compact visual/layout confirmation."
echo "- Spot-check the wide-layout Focus Preview transport overlay in a browser so cue/seek/scrub behavior still matches the main preview."
echo "- Import docs/fixtures/export-qa-project.json for the standard portrait/landscape/empty/long-scene export pass."
echo "- Keep docs/11-video-fallback-workflow.md with the handoff so downstream render users know Export Video emits a documented .json package."
echo "- Finish with docs/04-export-qa-checklist.md before a release/deploy decision."

echo "[release-smoke] done"
