#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"
source "$ROOT_DIR/tool/smoke_common.sh"

WIDGET_TEST_FILE="test/widget_test.dart"
CONTROLLER_TEST_FILE="test/unit/features/projects/presentation/controllers/projects_controller_test.dart"
SANITIZER_TEST_FILE="test/unit/features/projects/data/services/project_sanitizer_test.dart"
REPOSITORY_TEST_FILE="test/unit/features/projects/data/repositories/local_project_repository_test.dart"
FIXTURE_TEST_FILE="test/unit/features/projects/domain/export_qa_fixture_test.dart"

smoke_print_flutter_banner "import-smoke" "$FLUTTER_BIN"
smoke_run_analyze "import-smoke" "$FLUTTER_BIN"

for test_file in "$WIDGET_TEST_FILE" "$CONTROLLER_TEST_FILE" "$SANITIZER_TEST_FILE" "$REPOSITORY_TEST_FILE" "$FIXTURE_TEST_FILE"; do
  if [[ ! -f "$test_file" ]]; then
    echo "[import-smoke] missing expected test file: $test_file" >&2
    exit 1
  fi
done

# Keep these names in sync with the Dart test descriptions so the smoke gate
# stays focused without silently dropping renamed import/recovery coverage.
declare -a WIDGET_TEST_NAMES=(
  "import project json preview lists projected projects and skipped invalid entries"
  "import project json preview cancel keeps projects unchanged"
  "import json file button imports project from picker payload"
  "compact import project dialog stays usable on narrow screens"
)

declare -a CONTROLLER_TEST_NAMES=(
  "previewProjectImportFromJson returns projected names for batch payload"
  "importProjectFromJson appends imported project with unique name"
  "importProjectFromJson adds fallback scene when payload has none"
  "importProjectFromJson accepts wrapped project payload from package export"
  "importProjectFromJson sanitizes blank scene data and orphaned messages"
  "importProjectFromJson sanitizes duplicate scene ids across imported scenes"
  "importProjectFromJson supports multi-project payload and reports skipped entries"
)

declare -a SANITIZER_TEST_NAMES=(
  "adds fallback scene and project name when source is blank"
  "normalizes duplicate ids and orphaned messages inside a scene"
  "assigns unique scene ids across imported scenes"
  "normalizes imported character bubble colors to safe hex values"
  "maps legacy style ids to the current preset id"
)

declare -a REPOSITORY_TEST_NAMES=(
  "returns empty list when nothing is stored"
  "skips malformed project entries and keeps valid ones"
  "persists and loads project with 500+ messages"
  "normalizes legacy scene style ids when loading persisted projects"
)

declare -a FIXTURE_TEST_NAMES=(
  "parses the tracked export QA project for manual beta passes"
  "project package export keeps all QA scenes in the handoff payload"
  "video fallback export keeps the selected QA scene synchronized"
)

for test_name in "${WIDGET_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$WIDGET_TEST_FILE"; then
    echo "[import-smoke] missing expected widget test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${CONTROLLER_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$CONTROLLER_TEST_FILE"; then
    echo "[import-smoke] missing expected controller test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${SANITIZER_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$SANITIZER_TEST_FILE"; then
    echo "[import-smoke] missing expected sanitizer test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${REPOSITORY_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$REPOSITORY_TEST_FILE"; then
    echo "[import-smoke] missing expected repository test: $test_name" >&2
    exit 1
  fi
done

for test_name in "${FIXTURE_TEST_NAMES[@]}"; do
  if ! grep -Fq "$test_name" "$FIXTURE_TEST_FILE"; then
    echo "[import-smoke] missing expected fixture test: $test_name" >&2
    exit 1
  fi
done

fixture_test_count=$(grep -Ec '^[[:space:]]*test[[:space:]]*\(' "$FIXTURE_TEST_FILE")
if [[ "$fixture_test_count" -ne ${#FIXTURE_TEST_NAMES[@]} ]]; then
  echo "[import-smoke] export QA fixture coverage drifted: expected ${#FIXTURE_TEST_NAMES[@]} registered tests, found $fixture_test_count in $FIXTURE_TEST_FILE" >&2
  exit 1
fi

WIDGET_TEST_PATTERN="$(printf '%s\n' "${WIDGET_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
CONTROLLER_TEST_PATTERN="$(printf '%s\n' "${CONTROLLER_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
SANITIZER_TEST_PATTERN="$(printf '%s\n' "${SANITIZER_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
REPOSITORY_TEST_PATTERN="$(printf '%s\n' "${REPOSITORY_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
FIXTURE_TEST_PATTERN="$(printf '%s\n' "${FIXTURE_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
COMBINED_TEST_PATTERN="${WIDGET_TEST_PATTERN}|${CONTROLLER_TEST_PATTERN}|${SANITIZER_TEST_PATTERN}|${REPOSITORY_TEST_PATTERN}|${FIXTURE_TEST_PATTERN}"
TOTAL_TARGETED_TESTS=$((
  ${#WIDGET_TEST_NAMES[@]} +
  ${#CONTROLLER_TEST_NAMES[@]} +
  ${#SANITIZER_TEST_NAMES[@]} +
  ${#REPOSITORY_TEST_NAMES[@]} +
  ${#FIXTURE_TEST_NAMES[@]}
))

echo "[import-smoke] tests: $TOTAL_TARGETED_TESTS targeted import/widget/sanitizer/repository/fixture cases (batched)"
"$FLUTTER_BIN" test \
  "$WIDGET_TEST_FILE" \
  "$CONTROLLER_TEST_FILE" \
  "$SANITIZER_TEST_FILE" \
  "$REPOSITORY_TEST_FILE" \
  "$FIXTURE_TEST_FILE" \
  --name "^.*(${COMBINED_TEST_PATTERN})$"

echo

echo "[import-smoke] manual follow-up"
echo "- Run ./tool/beta_handoff.sh for the full preflight sequence when you want the release-ready gate stack."
echo "- Keep one real browser import pass in the manual demo checklist for clipboard/file-picker behavior."
echo "- Use docs/fixtures/export-qa-project.json as the standard manual import sample before export QA."

echo "[import-smoke] done"
