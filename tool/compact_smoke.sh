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
  "project list switches to compact app bar at larger text scale"
  "project list treats short landscape viewports as compact"
  "ultra-compact project list uses one scroll and keeps lower cards reachable"
  "compact project list search, filters, and sort controls stay usable on narrow screens"
  "compact selection overflow keeps bulk actions reachable on narrow screens"
  "compact portfolio readiness stacks summary actions on narrow screens"
  "compact portfolio readiness attention action opens editor on narrow screens"
  "compact portfolio preview ready action opens playback on narrow screens"
  "compact portfolio continue editing focuses first empty scene for attention projects"
  "compact chat editor app bar uses overflow navigation actions"
  "chat editor switches to compact controls at larger text scale"
  "compact chat editor keeps scene actions in overflow menu"
  "short landscape chat editor uses compact scene actions"
  "compact chat editor scene selector shows current scene context on narrow screens"
  "compact scene settings dialog stays usable on narrow screens"
  "compact scene settings keep manual style entry preview in sync"
  "compact scene settings keep legacy style aliases in sync"
  "ultra-compact chat editor stacks bulk actions vertically on phone-width screens"
  "ultra-compact chat editor footer actions stack on phone-width screens"
  "ultra-compact chat editor composer stays usable on phone-width screens"
  "compact character manager keeps actions usable through overflow menu"
  "compact playback app bar uses overflow navigation actions"
  "playback switches to compact controls at larger text scale"
  "short landscape playback uses compact overflow navigation actions"
  "compact playback export and transport controls remain usable"
  "compact playback scene selector switches demo scenes and resets progress"
  "compact playback scene switch resets deep preview scroll in long scenes"
  "compact playback focus preview stays usable on narrow screens"
  "ultra-compact focus preview transport keeps icon controls reachable"
  "focus preview swipe gestures seek in 5 second steps"
  "focus preview edge double taps jump between cues"
  "focus preview long press exits cleanly"
  "compact playback video fallback export reflects preview toggles and aspect ratio"
  "ultra-compact playback footer actions stack on phone-width screens"
  "ultra-compact playback footer actions expose navigation actions on phone-width screens"
  "compact demo flow stays usable across project list, editor, and playback"
)

WIDGET_TEST_FILE="test/widget_test.dart"
RECOVERY_TEST_FILE="test/widget/project_not_found_recovery_test.dart"
MOBILE_COMPACT_POLISH_TEST_FILE="test/widget/mobile_compact_polish_test.dart"
PLAYBACK_EMPTY_STATE_TEST_FILE="test/widget/playback_empty_state_actions_test.dart"
SCENE_STATUS_BADGE_TEST_FILE="test/widget/scene_status_badge_test.dart"
FOCUS_PREVIEW_CHROME_TEST_FILE="test/widget/focus_preview_chrome_test.dart"
FOCUS_PREVIEW_SHORT_HEIGHT_TEST_FILE="test/widget/focus_preview_short_height_test.dart"
SHORT_HEIGHT_ENTRY_STATES_TEST_FILE="test/widget/short_height_entry_states_test.dart"

for path in \
  "$WIDGET_TEST_FILE" \
  "$RECOVERY_TEST_FILE" \
  "$MOBILE_COMPACT_POLISH_TEST_FILE" \
  "$PLAYBACK_EMPTY_STATE_TEST_FILE" \
  "$SCENE_STATUS_BADGE_TEST_FILE" \
  "$FOCUS_PREVIEW_CHROME_TEST_FILE" \
  "$FOCUS_PREVIEW_SHORT_HEIGHT_TEST_FILE" \
  "$SHORT_HEIGHT_ENTRY_STATES_TEST_FILE"; do
  if [[ ! -f "$path" ]]; then
    echo "[compact-smoke] missing expected test file: $path" >&2
    exit 1
  fi
done

for test_name in "${TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$WIDGET_TEST_FILE"; then
    echo "[compact-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

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

declare -a SCENE_STATUS_BADGE_TEST_NAMES=(
  "compact chat editor app bar keeps scene status badge visible for empty scenes"
  "compact playback app bar keeps timeline QA status badge visible on narrow screens"
)

declare -a RECOVERY_TEST_NAMES=(
  "compact missing-project recovery stacks actions on phone-width screens"
  "wide missing-project recovery keeps wrap actions on roomy screens"
  "missing editor route can recover by creating a starter project"
  "missing playback route can recover by opening a demo project"
  "missing project recovery can return to the project list"
)

declare -a FOCUS_PREVIEW_CHROME_TEST_NAMES=(
  "focus preview header stacks on ultra-compact larger text"
  "focus preview transport stacks timeline on ultra-compact larger text"
)

declare -a FOCUS_PREVIEW_SHORT_HEIGHT_TEST_NAMES=(
  "focus preview switches to dense chrome on short landscape heights"
)

declare -a SHORT_HEIGHT_ENTRY_STATES_TEST_NAMES=(
  "empty project state stays scroll-safe on short mobile heights"
  "missing-project recovery stays scroll-safe on short mobile heights"
  "chat editor no-project placeholder uses the short-height scroll shell"
  "playback no-project placeholder uses the short-height scroll shell"
)

for test_name in "${MOBILE_COMPACT_POLISH_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$MOBILE_COMPACT_POLISH_TEST_FILE"; then
    echo "[compact-smoke] missing expected mobile polish test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${PLAYBACK_EMPTY_STATE_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$PLAYBACK_EMPTY_STATE_TEST_FILE"; then
    echo "[compact-smoke] missing expected playback empty-state test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${SCENE_STATUS_BADGE_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$SCENE_STATUS_BADGE_TEST_FILE"; then
    echo "[compact-smoke] missing expected scene status badge test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${RECOVERY_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$RECOVERY_TEST_FILE"; then
    echo "[compact-smoke] missing expected recovery test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${FOCUS_PREVIEW_CHROME_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$FOCUS_PREVIEW_CHROME_TEST_FILE"; then
    echo "[compact-smoke] missing expected focus preview chrome test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${FOCUS_PREVIEW_SHORT_HEIGHT_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$FOCUS_PREVIEW_SHORT_HEIGHT_TEST_FILE"; then
    echo "[compact-smoke] missing expected focus preview short-height test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${SHORT_HEIGHT_ENTRY_STATES_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$SHORT_HEIGHT_ENTRY_STATES_TEST_FILE"; then
    echo "[compact-smoke] missing expected short-height entry-state test: $test_name" >&2
    exit 1
  fi
done

TEST_PATTERN="$(printf '%s\n' "${TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
MOBILE_COMPACT_POLISH_TEST_PATTERN="$(printf '%s\n' "${MOBILE_COMPACT_POLISH_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
PLAYBACK_EMPTY_STATE_TEST_PATTERN="$(printf '%s\n' "${PLAYBACK_EMPTY_STATE_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
SCENE_STATUS_BADGE_TEST_PATTERN="$(printf '%s\n' "${SCENE_STATUS_BADGE_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
RECOVERY_TEST_PATTERN="$(printf '%s\n' "${RECOVERY_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
FOCUS_PREVIEW_CHROME_TEST_PATTERN="$(printf '%s\n' "${FOCUS_PREVIEW_CHROME_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
FOCUS_PREVIEW_SHORT_HEIGHT_TEST_PATTERN="$(printf '%s\n' "${FOCUS_PREVIEW_SHORT_HEIGHT_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
SHORT_HEIGHT_ENTRY_STATES_TEST_PATTERN="$(printf '%s\n' "${SHORT_HEIGHT_ENTRY_STATES_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
COMBINED_TEST_PATTERN="${TEST_PATTERN}|${MOBILE_COMPACT_POLISH_TEST_PATTERN}|${PLAYBACK_EMPTY_STATE_TEST_PATTERN}|${SCENE_STATUS_BADGE_TEST_PATTERN}|${RECOVERY_TEST_PATTERN}|${FOCUS_PREVIEW_CHROME_TEST_PATTERN}|${FOCUS_PREVIEW_SHORT_HEIGHT_TEST_PATTERN}|${SHORT_HEIGHT_ENTRY_STATES_TEST_PATTERN}"

echo "[compact-smoke] tests: ${#TEST_NAMES[@]} compact/export + ${#MOBILE_COMPACT_POLISH_TEST_NAMES[@]} mobile polish + ${#PLAYBACK_EMPTY_STATE_TEST_NAMES[@]} playback empty-state + ${#SCENE_STATUS_BADGE_TEST_NAMES[@]} scene-status + ${#RECOVERY_TEST_NAMES[@]} recovery/layout + ${#FOCUS_PREVIEW_CHROME_TEST_NAMES[@]} focus-preview chrome + ${#FOCUS_PREVIEW_SHORT_HEIGHT_TEST_NAMES[@]} focus-preview short-height + ${#SHORT_HEIGHT_ENTRY_STATES_TEST_NAMES[@]} short-height entry/recovery cases (batched)"
"$FLUTTER_BIN" test \
  "$WIDGET_TEST_FILE" \
  "$RECOVERY_TEST_FILE" \
  "$MOBILE_COMPACT_POLISH_TEST_FILE" \
  "$PLAYBACK_EMPTY_STATE_TEST_FILE" \
  "$SCENE_STATUS_BADGE_TEST_FILE" \
  "$FOCUS_PREVIEW_CHROME_TEST_FILE" \
  "$FOCUS_PREVIEW_SHORT_HEIGHT_TEST_FILE" \
  "$SHORT_HEIGHT_ENTRY_STATES_TEST_FILE" \
  --name "^(${COMBINED_TEST_PATTERN})$"

echo

echo "[compact-smoke] manual follow-up"
echo "- If this targeted pass is green, run ./tool/verify.sh before release or deploy decisions."
echo "- Then do the human browser pass from docs/08-web-smoke-checklist.md, docs/09-compact-smoke-checklist.md, and docs/04-export-qa-checklist.md."
echo "- This compact pass now also covers dialog safe-area/keyboard behavior, larger-text compact breakpoints on project/editor/playback surfaces, short-landscape compact app-bar flows, ultra-compact editor/playback footer stacking, focus-preview chrome stacking at larger text, short-height focus-preview chrome, short-height empty/recovery entry shells, compact scene-selector ergonomics, empty playback recovery actions, and the compact empty-scene status badge."

echo "[compact-smoke] done"
