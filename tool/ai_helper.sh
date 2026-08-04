#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage:
  ./tool/ai_helper.sh review [git-diff-args...]
  ./tool/ai_helper.sh ask <question>

Modes:
  review   Runs a read-only Gemini CLI review against the current git diff
           (default diff target: --cached, or HEAD if nothing is staged, or a
           custom git diff argument list you pass through). In default HEAD
           mode, untracked files are included automatically.

  ask      Sends the same read-only project question to Gemini CLI.

Examples:
  ./tool/ai_helper.sh review
  ./tool/ai_helper.sh review origin/main...HEAD
  ./tool/ai_helper.sh ask "Review the playback export architecture and name the main risks."

Notes:
- Gemini runs in read-only mode.
- Gemini uses: gemini -p '' --approval-mode plan --output-format text
- Output is written to stdout directly.
EOF
}

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required binary: $1" >&2
    return 1
  fi
}

HELPER_TIMEOUT_SECONDS="${HELPER_TIMEOUT_SECONDS:-120}"

# Keep this summary aligned with the current project phase when heartbeat
# priorities or source-of-truth docs change.
build_local_repo_context() {
  cat <<EOF
Local repo context:
- Operate only inside: $ROOT_DIR
- Source of truth docs: docs/01-product-spec-mvp.md, docs/02-technical-architecture-flutter.md, docs/03-roadmap-and-sprints.md
- Workflow: keep diffs small, stay inside current MVP/sprint scope, verify changes locally, and run the Gemini read-only review before commit/push.
- Current heartbeat: keep pushing toward beta with mobile adaptation, QA confidence, polish, and release-gate work.
- Note: some local workflow files (for example AGENTS.md and HEARTBEAT.md) may be git-ignored or unavailable to helper file tools, so rely on this inlined summary unless their contents are explicitly included in the prompt.
EOF
}

list_untracked_files() {
  git ls-files --others --exclude-standard
}

is_binary_file() {
  local file_path="$1"
  local numstat_output
  numstat_output="$(git diff --no-color --no-ext-diff --no-index --numstat -- /dev/null "$file_path" || true)"
  [[ "$numstat_output" == $'-\t-'* ]]
}

build_untracked_review_sections() {
  local files="$1"

  if [[ -z "$files" ]]; then
    return
  fi

  printf '%s\n' '---UNTRACKED FILES---'
  printf '%s\n' "$files"

  while IFS= read -r file_path; do
    [[ -z "$file_path" ]] && continue
    printf '\n%s\n' "---UNTRACKED STAT: $file_path ---"
    git diff --no-color --no-ext-diff --no-index --stat -- /dev/null "$file_path" || true

    if is_binary_file "$file_path"; then
      printf '%s\n' '---PATCH OMITTED: binary file ---'
      continue
    fi

    printf '%s\n' '---PATCH---'
    git diff --no-color --no-ext-diff --no-index -- /dev/null "$file_path" || true
  done <<< "$files"
}

build_review_payload() {
  local diff_args=("$@")
  local diff_cmd=()
  local include_untracked=false

  if [[ ${#diff_args[@]} -gt 0 ]]; then
    diff_cmd=(git diff --no-color --no-ext-diff "${diff_args[@]}")
  elif ! git diff --cached --quiet; then
    diff_cmd=(git diff --no-color --no-ext-diff --cached)
  else
    include_untracked=true
    # Brand-new repos may not have HEAD yet; in that case we can still review
    # untracked files without forcing a failing git diff invocation.
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
      diff_cmd=(git diff --no-color --no-ext-diff HEAD)
    fi
  fi

  local tracked_changed_files=''
  if [[ ${#diff_cmd[@]} -gt 0 ]]; then
    tracked_changed_files="$("${diff_cmd[@]}" --name-only)"
  fi

  local untracked_files=''
  if [[ "$include_untracked" == true ]]; then
    untracked_files="$(list_untracked_files)"
  fi

  local changed_files
  changed_files="$(printf '%s\n%s\n' "$tracked_changed_files" "$untracked_files" | sed '/^$/d' | sort -u)"

  if [[ -z "$changed_files" ]]; then
    echo "No diff detected for review." >&2
    exit 2
  fi

  local diff_text=''
  if [[ -n "$tracked_changed_files" ]]; then
    diff_text="$("${diff_cmd[@]}" --stat && printf '\n---PATCH---\n' && "${diff_cmd[@]}" --)"
  fi

  if [[ -n "$untracked_files" ]]; then
    if [[ -n "$diff_text" ]]; then
      diff_text+=$'\n\n'
    fi
    diff_text+="$(build_untracked_review_sections "$untracked_files")"
  fi

  cat <<EOF
You are reviewing a code change in the repository at: $ROOT_DIR

Role:
- Senior read-only reviewer.
- Do not propose writing code directly.
- Do not ask follow-up questions unless absolutely required.

Review goals:
1. Find correctness bugs, regressions, edge cases, or risky assumptions.
2. Call out test coverage gaps that matter for this diff.
3. Flag architecture or maintainability issues only if they materially matter.
4. If the diff looks good, say so briefly.

Output format:
- Verdict: <approve|approve with notes|needs changes>
- Findings:
  - <bullet>
- Suggested next step:
  - <bullet>

Project context:
- Flutter web-first MVP.
- Stay within documented MVP/sprint scope.
- Prefer practical, high-signal review comments.

$(build_local_repo_context)

Changed files:
$changed_files

Diff:
$diff_text
EOF
}

run_gemini() {
  local prompt="$1"
  if ! require_bin gemini; then
    echo "Gemini CLI unavailable; skipping Gemini helper pass." >&2
    return 2
  fi

  local gemini_output
  local gemini_status=0

  # Gemini requires a prompt argument for -p; an empty string keeps the actual
  # payload on stdin, which avoids shell ARG_MAX limits for large diffs.
  set +e
  gemini_output="$(printf '%s' "$prompt" | timeout "$HELPER_TIMEOUT_SECONDS" gemini -p '' \
    --approval-mode plan \
    --output-format text 2>&1)"
  gemini_status=$?
  set -e

  if [[ $gemini_status -eq 0 ]]; then
    printf '%s\n' "$gemini_output"
    return 0
  fi

  if grep -Fq 'UNSUPPORTED_CLIENT' <<< "$gemini_output" || \
    grep -Fq 'This client is no longer supported for Gemini Code Assist for individuals' <<< "$gemini_output"; then
    printf '%s\n' "$gemini_output" >&2
    echo "Gemini helper is configured with an unsupported client/auth tier. Re-auth with a supported Gemini/Antigravity setup or temporarily skip helper review until the local CLI is fixed." >&2
    return 3
  fi

  if [[ $gemini_status -eq 124 ]]; then
    printf '%s\n' "$gemini_output" >&2
    echo "Gemini helper timed out after ${HELPER_TIMEOUT_SECONDS}s; continuing without Gemini output." >&2
    return 1
  fi

  printf '%s\n' "$gemini_output" >&2
  echo "Gemini helper failed; continuing without Gemini output." >&2
  return 1
}

mode="${1:-}"
if [[ -z "$mode" || "$mode" == "-h" || "$mode" == "--help" ]]; then
  usage
  exit 0
fi
shift || true

case "$mode" in
  review)
    prompt="$(build_review_payload "$@")"
    printf '===== GEMINI CLI REVIEW =====\n'
    gemini_status=0
    run_gemini "$prompt" || gemini_status=$?
    if [[ "$gemini_status" -ne 0 ]]; then
      if [[ "$gemini_status" -eq 2 ]]; then
        echo '[ai-helper] Gemini helper unavailable.' >&2
      elif [[ "$gemini_status" -eq 3 ]]; then
        echo '[ai-helper] Gemini helper unsupported on the current local auth/client setup.' >&2
      else
        echo '[ai-helper] Gemini helper failed.' >&2
      fi
      exit 1
    fi
    ;;
  ask)
    if [[ $# -eq 0 ]]; then
      echo "ask mode requires a question" >&2
      exit 1
    fi
    question="$*"
    prompt=$'You are helping with a software project in read-only mode.\n\nRepository root:\n'
    prompt+="$ROOT_DIR"
    prompt+=$'\n\n'
    prompt+="$(build_local_repo_context)"
    prompt+=$'\n\nTask:\n'
    prompt+="$question"
    prompt+=$'\n\nRules:\n- Read-only analysis only.\n- Be concise and practical.\n- Prefer concrete recommendations over theory.\n- If something looks uncertain, say so plainly.\n- If the task mentions ignored local workflow files such as AGENTS.md or HEARTBEAT.md, use the inlined repo context above instead of trying to read those files from disk unless the prompt explicitly includes their contents.'
    printf '===== GEMINI CLI ANALYSIS =====\n'
    gemini_status=0
    run_gemini "$prompt" || gemini_status=$?
    if [[ "$gemini_status" -ne 0 ]]; then
      if [[ "$gemini_status" -eq 2 ]]; then
        echo '[ai-helper] Gemini helper unavailable.' >&2
      elif [[ "$gemini_status" -eq 3 ]]; then
        echo '[ai-helper] Gemini helper unsupported on the current local auth/client setup.' >&2
      else
        echo '[ai-helper] Gemini helper failed.' >&2
      fi
      exit 1
    fi
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    usage
    exit 1
    ;;
esac
