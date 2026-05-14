#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"

CONTROLLER_TEST_FILE="test/unit/features/projects/presentation/controllers/projects_controller_test.dart"
SANITIZER_TEST_FILE="test/unit/features/projects/data/services/project_sanitizer_test.dart"
REPOSITORY_TEST_FILE="test/unit/features/projects/data/repositories/local_project_repository_test.dart"

echo "[import-smoke] using flutter: $FLUTTER_BIN"
"$FLUTTER_BIN" --version

echo "[import-smoke] analyze"
"$FLUTTER_BIN" analyze

for test_file in "$CONTROLLER_TEST_FILE" "$SANITIZER_TEST_FILE" "$REPOSITORY_TEST_FILE"; do
  if [[ ! -f "$test_file" ]]; then
    echo "[import-smoke] missing expected test file: $test_file" >&2
    exit 1
  fi
done

# Keep these names in sync with the Dart test descriptions so the smoke gate
# stays focused without silently dropping renamed import/recovery coverage.
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

CONTROLLER_TEST_PATTERN="$(printf '%s\n' "${CONTROLLER_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
SANITIZER_TEST_PATTERN="$(printf '%s\n' "${SANITIZER_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"
REPOSITORY_TEST_PATTERN="$(printf '%s\n' "${REPOSITORY_TEST_NAMES[@]}" | sed -e 's/[][(){}.^$*+?|\\-]/\\&/g' | paste -sd'|' -)"

echo "[import-smoke] controller tests: ${#CONTROLLER_TEST_NAMES[@]} targeted import/recovery cases"
"$FLUTTER_BIN" test "$CONTROLLER_TEST_FILE" --name "^.*(${CONTROLLER_TEST_PATTERN})$"

echo

echo "[import-smoke] sanitizer tests: ${#SANITIZER_TEST_NAMES[@]} payload normalization cases"
"$FLUTTER_BIN" test "$SANITIZER_TEST_FILE" --name "^.*(${SANITIZER_TEST_PATTERN})$"

echo

echo "[import-smoke] repository tests: ${#REPOSITORY_TEST_NAMES[@]} persistence recovery cases"
"$FLUTTER_BIN" test "$REPOSITORY_TEST_FILE" --name "^.*(${REPOSITORY_TEST_PATTERN})$"

echo

echo "[import-smoke] manual follow-up"
echo "- Run ./tool/beta_handoff.sh for the full preflight sequence when you want the release-ready gate stack."
echo "- Keep one real browser import pass in the manual demo checklist for clipboard/file-picker behavior."

echo "[import-smoke] done"
