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
  "test/widget/focus_preview_chrome_test.dart"
  "test/widget/mobile_compact_polish_test.dart"
  "test/widget/playback_empty_state_actions_test.dart"
  "test/widget/playback_export_feedback_test.dart"
  "test/widget/portfolio_preflight_badge_test.dart"
  "test/widget/project_not_found_recovery_test.dart"
  "test/widget/scene_status_badge_test.dart"
  "test/widget/scene_route_sync_test.dart"
  "test/widget/timeline_qa_markers_test.dart"
)

WIDGET_TEST_FILE="test/widget_test.dart"
FOCUS_PREVIEW_CHROME_TEST_FILE="test/widget/focus_preview_chrome_test.dart"
MOBILE_COMPACT_POLISH_TEST_FILE="test/widget/mobile_compact_polish_test.dart"
PLAYBACK_EMPTY_STATE_TEST_FILE="test/widget/playback_empty_state_actions_test.dart"
PLAYBACK_EXPORT_FEEDBACK_TEST_FILE="test/widget/playback_export_feedback_test.dart"
PORTFOLIO_PREFLIGHT_BADGE_TEST_FILE="test/widget/portfolio_preflight_badge_test.dart"
RECOVERY_TEST_FILE="test/widget/project_not_found_recovery_test.dart"
SCENE_STATUS_BADGE_TEST_FILE="test/widget/scene_status_badge_test.dart"
SCENE_ROUTE_SYNC_TEST_FILE="test/widget/scene_route_sync_test.dart"
TIMELINE_QA_MARKERS_TEST_FILE="test/widget/timeline_qa_markers_test.dart"

for widget_test_file in "${WIDGET_TEST_FILES[@]}"; do
  if [[ ! -f "$widget_test_file" ]]; then
    echo "[release-smoke] missing expected test file: $widget_test_file" >&2
    exit 1
  fi
done

declare -a WIDGET_TEST_NAMES=(
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
  "playback preview expands on wide layouts and clarifies export scaling"
  "playback focus preview opens with transport controls and closes cleanly"
  "focus preview transport controls scrub and jump between cues"
  "focus preview swipe gestures seek in 5 second steps"
  "focus preview edge double taps jump between cues"
  "focus preview preserves playback position and preview mode when opened from the main timeline"
  "focus preview responds to keyboard play pause and restart shortcuts"
  "focus preview escape shortcut closes the overlay"
  "focus preview long press exits cleanly"
  "playback preview auto-follows deep cues in long scenes"
  "playback preview re-follows earlier cues after backward scrub"
  "playback preview surface and export target follow aspect ratio"
  "playback export buttons are disabled for empty scenes"
  "empty playback scene shows recovery guidance and disables transport controls"
  "changing aspect ratio keeps playback progress stable"
  "long chat scene keeps playback controls and export available"
  "playback stays responsive with imported 500+ messages"
)

declare -a FOCUS_PREVIEW_CHROME_TEST_NAMES=(
  "focus preview header stacks on ultra-compact larger text"
  "focus preview header stays inline on roomy widths"
  "focus preview transport stacks timeline on ultra-compact larger text"
  "focus preview transport keeps timeline inline on wider widths"
)

declare -a MOBILE_COMPACT_POLISH_TEST_NAMES=(
  "adds safe-area padding to compact dialog insets"
  "moves above the keyboard and shrinks content height"
  "treats medium dialog widths as compact at larger text scale"
  "CompactSceneSelector keeps a 48dp touch target"
)

declare -a PLAYBACK_EMPTY_STATE_TEST_NAMES=(
  "playback empty state offers editor and template recovery actions"
  "playback empty state hides template hint when no scene is available"
  "playback empty state can seed a briefing template directly"
)

declare -a PLAYBACK_EXPORT_FEEDBACK_TEST_NAMES=(
  "playback preview toggles affect screenshot export feedback"
  "export pre-flight dialog reflects current playback export state"
  "playback screenshot export shows failure feedback"
  "video export button copies fallback package to clipboard when download is unavailable"
  "video export button shows failure when clipboard fallback fails"
  "copy handoff button copies fallback package to clipboard"
  "copy handoff button shows clipboard failure feedback"
)

declare -a PORTFOLIO_PREFLIGHT_BADGE_TEST_NAMES=(
  "compact portfolio pre-flight dialog surfaces timeline QA details and action"
)

declare -a RECOVERY_TEST_NAMES=(
  "compact missing-project recovery stacks actions on phone-width screens"
  "wide missing-project recovery keeps wrap actions on roomy screens"
  "missing editor route can recover by creating a starter project"
  "missing playback route can recover by opening a demo project"
  "missing project recovery can return to the project list"
)

declare -a SCENE_STATUS_BADGE_TEST_NAMES=(
  "compact chat editor app bar keeps scene status badge visible for empty scenes"
  "scene status dialog covers needs-lines details without redundant sections"
  "scene status dialog covers ready details"
  "playback app bar shows timeline QA status badge on wide layouts"
)

declare -a SCENE_ROUTE_SYNC_TEST_NAMES=(
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
)

declare -a TIMELINE_QA_MARKERS_TEST_NAMES=(
  "chat editor shows inline timeline QA markers for stacked cue messages"
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

for test_name in "${WIDGET_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$WIDGET_TEST_FILE"; then
    echo "[release-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${FOCUS_PREVIEW_CHROME_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$FOCUS_PREVIEW_CHROME_TEST_FILE"; then
    echo "[release-smoke] missing expected focus preview chrome test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${MOBILE_COMPACT_POLISH_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$MOBILE_COMPACT_POLISH_TEST_FILE"; then
    echo "[release-smoke] missing expected mobile polish test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${PLAYBACK_EMPTY_STATE_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$PLAYBACK_EMPTY_STATE_TEST_FILE"; then
    echo "[release-smoke] missing expected playback empty-state test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${PLAYBACK_EXPORT_FEEDBACK_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$PLAYBACK_EXPORT_FEEDBACK_TEST_FILE"; then
    echo "[release-smoke] missing expected export feedback test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${PORTFOLIO_PREFLIGHT_BADGE_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$PORTFOLIO_PREFLIGHT_BADGE_TEST_FILE"; then
    echo "[release-smoke] missing expected portfolio pre-flight test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${RECOVERY_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$RECOVERY_TEST_FILE"; then
    echo "[release-smoke] missing expected recovery test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${SCENE_STATUS_BADGE_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$SCENE_STATUS_BADGE_TEST_FILE"; then
    echo "[release-smoke] missing expected scene status badge test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${SCENE_ROUTE_SYNC_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$SCENE_ROUTE_SYNC_TEST_FILE"; then
    echo "[release-smoke] missing expected route-sync test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${TIMELINE_QA_MARKERS_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$TIMELINE_QA_MARKERS_TEST_FILE"; then
    echo "[release-smoke] missing expected timeline QA marker test: $test_name" >&2
    exit 1
  fi
done

for unit_test_file in "${UNIT_TEST_FILES[@]}"; do
  if [[ ! -f "$unit_test_file" ]]; then
    echo "[release-smoke] missing expected unit test file: $unit_test_file" >&2
    exit 1
  fi
done

WIDGET_TEST_PATTERN="$(printf '%s\n' "${WIDGET_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
FOCUS_PREVIEW_CHROME_TEST_PATTERN="$(printf '%s\n' "${FOCUS_PREVIEW_CHROME_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
MOBILE_COMPACT_POLISH_TEST_PATTERN="$(printf '%s\n' "${MOBILE_COMPACT_POLISH_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
PLAYBACK_EMPTY_STATE_TEST_PATTERN="$(printf '%s\n' "${PLAYBACK_EMPTY_STATE_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
PLAYBACK_EXPORT_FEEDBACK_TEST_PATTERN="$(printf '%s\n' "${PLAYBACK_EXPORT_FEEDBACK_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
PORTFOLIO_PREFLIGHT_BADGE_TEST_PATTERN="$(printf '%s\n' "${PORTFOLIO_PREFLIGHT_BADGE_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
RECOVERY_TEST_PATTERN="$(printf '%s\n' "${RECOVERY_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
SCENE_STATUS_BADGE_TEST_PATTERN="$(printf '%s\n' "${SCENE_STATUS_BADGE_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
SCENE_ROUTE_SYNC_TEST_PATTERN="$(printf '%s\n' "${SCENE_ROUTE_SYNC_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
TIMELINE_QA_MARKERS_TEST_PATTERN="$(printf '%s\n' "${TIMELINE_QA_MARKERS_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
TEST_PATTERN="${WIDGET_TEST_PATTERN}|${FOCUS_PREVIEW_CHROME_TEST_PATTERN}|${MOBILE_COMPACT_POLISH_TEST_PATTERN}|${PLAYBACK_EMPTY_STATE_TEST_PATTERN}|${PLAYBACK_EXPORT_FEEDBACK_TEST_PATTERN}|${PORTFOLIO_PREFLIGHT_BADGE_TEST_PATTERN}|${RECOVERY_TEST_PATTERN}|${SCENE_STATUS_BADGE_TEST_PATTERN}|${SCENE_ROUTE_SYNC_TEST_PATTERN}|${TIMELINE_QA_MARKERS_TEST_PATTERN}"

echo "[release-smoke] widget tests: ${#WIDGET_TEST_NAMES[@]} widget + ${#FOCUS_PREVIEW_CHROME_TEST_NAMES[@]} focus-preview chrome + ${#MOBILE_COMPACT_POLISH_TEST_NAMES[@]} mobile polish + ${#PLAYBACK_EMPTY_STATE_TEST_NAMES[@]} playback empty-state + ${#PLAYBACK_EXPORT_FEEDBACK_TEST_NAMES[@]} export feedback + ${#PORTFOLIO_PREFLIGHT_BADGE_TEST_NAMES[@]} portfolio pre-flight + ${#RECOVERY_TEST_NAMES[@]} recovery + ${#SCENE_STATUS_BADGE_TEST_NAMES[@]} scene-status badge + ${#SCENE_ROUTE_SYNC_TEST_NAMES[@]} route-sync + ${#TIMELINE_QA_MARKERS_TEST_NAMES[@]} timeline-QA marker cases"
"$FLUTTER_BIN" test "${WIDGET_TEST_FILES[@]}" --name "^(${TEST_PATTERN})$"

echo

echo "[release-smoke] unit tests: ${#UNIT_TEST_FILES[@]} export payload and filename cases (batched)"
"$FLUTTER_BIN" test "${UNIT_TEST_FILES[@]}"

echo

echo "[release-smoke] manual follow-up"
echo "- This is a fast preflight, not a replacement for ./tool/verify.sh."
echo "- It now covers key compact-width, dialog ergonomics, empty-state recovery, scene deep-link sync/stale-link recovery, export, portfolio pre-flight, and focus-preview regressions automatically."
echo "- Then do the browser pass from docs/08-web-smoke-checklist.md for real browser history/back-forward behavior and visual confirmation."
echo "- Repeat the phone-width pass from docs/09-compact-smoke-checklist.md for compact visual/layout confirmation."
echo "- Spot-check the wide-layout Focus Preview transport overlay in a browser so cue/seek/scrub behavior still matches the main preview."
echo "- Import docs/fixtures/export-qa-project.json for the standard portrait/landscape/empty/long-scene export pass."
echo "- Keep docs/11-video-fallback-workflow.md with the handoff so downstream render users know Export Video emits a documented .json package."
echo "- Finish with docs/04-export-qa-checklist.md before a release/deploy decision."

echo "[release-smoke] done"
