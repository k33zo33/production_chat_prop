#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_HELPER="$ROOT_DIR/tool/ai_helper.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tool"
cp "$SOURCE_HELPER" "$TMP_DIR/tool/ai_helper.sh"
chmod +x "$TMP_DIR/tool/ai_helper.sh"

cd "$TMP_DIR"

git init -q
git config user.name "AI Helper Smoke"
git config user.email "ai-helper-smoke@example.com"

assert_status() {
  local expected_status="$1"
  local actual_status="$2"
  local label="$3"

  if [[ "$expected_status" -ne "$actual_status" ]]; then
    echo "[ai-helper-smoke] unexpected status for $label: got $actual_status expected $expected_status" >&2
    exit 1
  fi
}

assert_output_contains() {
  local needle="$1"
  local haystack="$2"
  local label="$3"

  if ! grep -Fq -- "$needle" <<< "$haystack"; then
    echo "[ai-helper-smoke] missing expected output for $label: $needle" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

run_and_capture() {
  local output=""
  local status=0

  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e

  printf '%s\n' "$status"
  printf '%s' "$output"
}

echo "seed" > tracked.txt
echo "other" > ignored.txt
git add tracked.txt ignored.txt
git commit -q -m "seed"

result="$(run_and_capture "$TMP_DIR/tool/ai_helper.sh" doctor)"
doctor_status="$(printf '%s\n' "$result" | head -n1)"
doctor_output="$(printf '%s\n' "$result" | tail -n +2)"
assert_status 1 "$doctor_status" "doctor without gemini"
assert_output_contains "[ai-helper] missing: gemini" "$doctor_output" "doctor without gemini"
assert_output_contains "[ai-helper] doctor verdict: needs attention" "$doctor_output" "doctor without gemini"

echo "tracked staged change" >> tracked.txt
echo "ignored staged change" >> ignored.txt
git add tracked.txt ignored.txt
echo "fresh untracked helper review target" > untracked.txt

result="$(run_and_capture "$TMP_DIR/tool/ai_helper.sh" review -- tracked.txt)"
review_path_status="$(printf '%s\n' "$result" | head -n1)"
review_path_output="$(printf '%s\n' "$result" | tail -n +2)"
assert_status 1 "$review_path_status" "staged path-filter review"
assert_output_contains "===== GEMINI CLI REVIEW =====" "$review_path_output" "staged path-filter review"
assert_output_contains "[ai-helper] Gemini helper unavailable." "$review_path_output" "staged path-filter review"

result="$(run_and_capture "$TMP_DIR/tool/ai_helper.sh" preview-review -- tracked.txt)"
preview_status="$(printf '%s\n' "$result" | head -n1)"
preview_output="$(printf '%s\n' "$result" | tail -n +2)"
assert_status 0 "$preview_status" "preview-review path-filter"
assert_output_contains "Changed files:" "$preview_output" "preview-review path-filter"
assert_output_contains "tracked.txt" "$preview_output" "preview-review path-filter"
assert_output_contains "Diff:" "$preview_output" "preview-review path-filter"

result="$(run_and_capture "$TMP_DIR/tool/ai_helper.sh" preview-review -- untracked.txt)"
preview_untracked_status="$(printf '%s\n' "$result" | head -n1)"
preview_untracked_output="$(printf '%s\n' "$result" | tail -n +2)"
assert_status 0 "$preview_untracked_status" "preview-review untracked path-filter"
assert_output_contains "---UNTRACKED FILES---" "$preview_untracked_output" "preview-review untracked path-filter"
assert_output_contains "untracked.txt" "$preview_untracked_output" "preview-review untracked path-filter"

result="$(run_and_capture "$TMP_DIR/tool/ai_helper.sh" review -- untracked.txt)"
review_untracked_status="$(printf '%s\n' "$result" | head -n1)"
review_untracked_output="$(printf '%s\n' "$result" | tail -n +2)"
assert_status 1 "$review_untracked_status" "staged untracked path-filter review"
assert_output_contains "===== GEMINI CLI REVIEW =====" "$review_untracked_output" "staged untracked path-filter review"
assert_output_contains "[ai-helper] Gemini helper unavailable." "$review_untracked_output" "staged untracked path-filter review"

git commit -q -m "update tracked files"

result="$(run_and_capture "$TMP_DIR/tool/ai_helper.sh" review HEAD~1..HEAD -- tracked.txt)"
review_range_status="$(printf '%s\n' "$result" | head -n1)"
review_range_output="$(printf '%s\n' "$result" | tail -n +2)"
assert_status 1 "$review_range_status" "range plus path review"
assert_output_contains "===== GEMINI CLI REVIEW =====" "$review_range_output" "range plus path review"
assert_output_contains "[ai-helper] Gemini helper unavailable." "$review_range_output" "range plus path review"

result="$(run_and_capture "$TMP_DIR/tool/ai_helper.sh" review -- missing.txt)"
missing_path_status="$(printf '%s\n' "$result" | head -n1)"
missing_path_output="$(printf '%s\n' "$result" | tail -n +2)"
assert_status 2 "$missing_path_status" "missing-path review"
assert_output_contains "No diff detected for review." "$missing_path_output" "missing-path review"

echo "[ai-helper-smoke] doctor path detects missing Gemini"
echo "[ai-helper-smoke] staged path-filter review reaches the Gemini invocation path"
echo "[ai-helper-smoke] preview-review prints the local review payload without Gemini"
echo "[ai-helper-smoke] explicit untracked path filters stay reviewable even with staged changes"
echo "[ai-helper-smoke] range-plus-path review reaches the Gemini invocation path"
echo "[ai-helper-smoke] missing-path review still fails fast with a clear no-diff signal"
echo "[ai-helper-smoke] done"
