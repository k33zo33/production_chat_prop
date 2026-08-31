#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_BETA_HANDOFF="$ROOT_DIR/tool/beta_handoff.sh"
SOURCE_SMOKE_COMMON="$ROOT_DIR/tool/smoke_common.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tool"
cp "$SOURCE_BETA_HANDOFF" "$TMP_DIR/tool/beta_handoff.sh"
cp "$SOURCE_SMOKE_COMMON" "$TMP_DIR/tool/smoke_common.sh"
chmod +x "$TMP_DIR/tool/beta_handoff.sh" "$TMP_DIR/tool/smoke_common.sh"

LOG_PATH="$TMP_DIR/run.log"
export LOG_PATH

make_stub() {
  local name="$1"

  cat > "$TMP_DIR/tool/$name" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
basename_name="$(basename "$0")"
printf '%s|args=%s|SMOKE_SKIP_VERSION=%s|SMOKE_SKIP_ANALYZE=%s|SKIP_PUB_GET=%s\n' \
  "$basename_name" \
  "$*" \
  "${SMOKE_SKIP_VERSION:-0}" \
  "${SMOKE_SKIP_ANALYZE:-0}" \
  "${SKIP_PUB_GET:-0}" >> "$LOG_PATH"
EOF

  chmod +x "$TMP_DIR/tool/$name"
}

for stub_name in \
  demo_smoke.sh \
  import_smoke.sh \
  release_smoke.sh \
  compact_smoke.sh \
  navigation_smoke.sh \
  brand_neutrality_smoke.sh \
  verify.sh \
  web_shell_smoke.sh \
  docs_handoff_smoke.sh \
  manual_beta_checklist.sh \
  ai_helper_smoke.sh; do
  make_stub "$stub_name"
done

cat > "$TMP_DIR/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*" >> "$LOG_PATH"
case "${1:-}" in
  --version)
    echo "Flutter stub"
    ;;
  pub)
    echo "pub get stub"
    ;;
  analyze)
    echo "analyze stub"
    ;;
esac
EOF
chmod +x "$TMP_DIR/flutter-stub.sh"

output="$(
  cd "$TMP_DIR" &&
  FLUTTER_BIN="$TMP_DIR/flutter-stub.sh" ./tool/beta_handoff.sh 2>&1
)"

assert_contains() {
  local needle="$1"
  local haystack="$2"
  local label="$3"

  if ! grep -Fq -- "$needle" <<< "$haystack"; then
    echo "[beta-handoff-smoke] missing expected output for $label: $needle" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

assert_contains "[beta-handoff] docs/release instructions preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] helper workflow preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] web shell metadata preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] brand-neutrality preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] demo flow preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] import/recovery preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] release preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] compact/mobile preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] navigation/deep-link preflight" "$output" "stdout labels"
assert_contains "[beta-handoff] full verification gate" "$output" "stdout labels"
assert_contains "[beta-handoff] built web shell metadata check" "$output" "stdout labels"
assert_contains "[beta-handoff] built web brand-neutrality check" "$output" "stdout labels"
assert_contains "[beta-handoff] manual follow-up" "$output" "stdout labels"
assert_contains "- ./tool/manual_beta_checklist.sh" "$output" "manual follow-up output"
assert_contains "- docs/11-video-fallback-workflow.md" "$output" "manual follow-up output"
assert_contains "[beta-handoff] done" "$output" "stdout labels"

python3 - "$LOG_PATH" <<'PY'
import pathlib
import sys

log_path = pathlib.Path(sys.argv[1])
lines = [line.strip() for line in log_path.read_text(encoding='utf-8').splitlines() if line.strip()]

expected_prefix = [
    'flutter|args=--version',
    'flutter|args=pub get',
    'flutter|args=analyze',
    'docs_handoff_smoke.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'ai_helper_smoke.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'web_shell_smoke.sh|args=web|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'brand_neutrality_smoke.sh|args=lib web|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'demo_smoke.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'import_smoke.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'release_smoke.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'compact_smoke.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'navigation_smoke.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'verify.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=1',
    'web_shell_smoke.sh|args=build/web|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'brand_neutrality_smoke.sh|args=build/web|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
    'manual_beta_checklist.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
]

if lines != expected_prefix:
    raise SystemExit(
        '[beta-handoff-smoke] unexpected orchestration log:\n'
        + '\n'.join(lines)
    )
PY

FAIL_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$FAIL_DIR"' EXIT

mkdir -p "$FAIL_DIR/tool"
cp "$SOURCE_BETA_HANDOFF" "$FAIL_DIR/tool/beta_handoff.sh"
cp "$SOURCE_SMOKE_COMMON" "$FAIL_DIR/tool/smoke_common.sh"
chmod +x "$FAIL_DIR/tool/beta_handoff.sh" "$FAIL_DIR/tool/smoke_common.sh"

FAIL_LOG_PATH="$FAIL_DIR/run.log"
export FAIL_LOG_PATH

make_fail_stub() {
  local name="$1"

  cat > "$FAIL_DIR/tool/$name" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
basename_name="$(basename "$0")"
printf '%s|args=%s|SMOKE_SKIP_VERSION=%s|SMOKE_SKIP_ANALYZE=%s|SKIP_PUB_GET=%s\n' \
  "$basename_name" \
  "$*" \
  "${SMOKE_SKIP_VERSION:-0}" \
  "${SMOKE_SKIP_ANALYZE:-0}" \
  "${SKIP_PUB_GET:-0}" >> "$FAIL_LOG_PATH"
EOF

  chmod +x "$FAIL_DIR/tool/$name"
}

for stub_name in \
  demo_smoke.sh \
  import_smoke.sh \
  release_smoke.sh \
  compact_smoke.sh \
  navigation_smoke.sh \
  brand_neutrality_smoke.sh \
  verify.sh \
  web_shell_smoke.sh \
  manual_beta_checklist.sh \
  ai_helper_smoke.sh; do
  make_fail_stub "$stub_name"
done

cat > "$FAIL_DIR/tool/docs_handoff_smoke.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'docs_handoff_smoke.sh|args=%s|SMOKE_SKIP_VERSION=%s|SMOKE_SKIP_ANALYZE=%s|SKIP_PUB_GET=%s\n' \
  "$*" \
  "${SMOKE_SKIP_VERSION:-0}" \
  "${SMOKE_SKIP_ANALYZE:-0}" \
  "${SKIP_PUB_GET:-0}" >> "$FAIL_LOG_PATH"
echo "[docs-handoff-smoke-stub] intentional failure" >&2
exit 7
EOF
chmod +x "$FAIL_DIR/tool/docs_handoff_smoke.sh"

cat > "$FAIL_DIR/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*" >> "$FAIL_LOG_PATH"
case "${1:-}" in
  --version)
    echo "Flutter stub"
    ;;
  pub)
    echo "pub get stub"
    ;;
  analyze)
    echo "analyze stub"
    ;;
esac
EOF
chmod +x "$FAIL_DIR/flutter-stub.sh"

set +e
failure_output="$(
  cd "$FAIL_DIR" &&
  FLUTTER_BIN="$FAIL_DIR/flutter-stub.sh" ./tool/beta_handoff.sh 2>&1
)"
failure_status=$?
set -e

if [[ "$failure_status" -eq 0 ]]; then
  echo "[beta-handoff-smoke] expected a non-zero status when docs_handoff_smoke fails" >&2
  echo "$failure_output" >&2
  exit 1
fi

assert_contains "[beta-handoff] docs/release instructions preflight" "$failure_output" "failure path output"
assert_contains "[docs-handoff-smoke-stub] intentional failure" "$failure_output" "failure path output"

if grep -Fq -- "[beta-handoff] helper workflow preflight" <<< "$failure_output"; then
  echo "[beta-handoff-smoke] helper workflow should not start after docs_handoff_smoke fails" >&2
  echo "$failure_output" >&2
  exit 1
fi

python3 - "$FAIL_LOG_PATH" <<'PY'
import pathlib
import sys

log_path = pathlib.Path(sys.argv[1])
lines = [line.strip() for line in log_path.read_text(encoding='utf-8').splitlines() if line.strip()]

expected_lines = [
    'flutter|args=--version',
    'flutter|args=pub get',
    'flutter|args=analyze',
    'docs_handoff_smoke.sh|args=|SMOKE_SKIP_VERSION=1|SMOKE_SKIP_ANALYZE=1|SKIP_PUB_GET=0',
]

if lines != expected_lines:
    raise SystemExit(
        '[beta-handoff-smoke] failure path should stop immediately after docs_handoff_smoke:\n'
        + '\n'.join(lines)
    )
PY

MISSING_SCRIPT_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$FAIL_DIR" "$MISSING_SCRIPT_DIR"' EXIT

mkdir -p "$MISSING_SCRIPT_DIR/tool"
cp "$SOURCE_BETA_HANDOFF" "$MISSING_SCRIPT_DIR/tool/beta_handoff.sh"
cp "$SOURCE_SMOKE_COMMON" "$MISSING_SCRIPT_DIR/tool/smoke_common.sh"
chmod +x "$MISSING_SCRIPT_DIR/tool/beta_handoff.sh" "$MISSING_SCRIPT_DIR/tool/smoke_common.sh"

cat > "$MISSING_SCRIPT_DIR/tool/import_smoke.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF
chmod +x "$MISSING_SCRIPT_DIR/tool/import_smoke.sh"

set +e
missing_script_output="$(
  cd "$MISSING_SCRIPT_DIR" &&
  ./tool/beta_handoff.sh 2>&1
)"
missing_script_status=$?
set -e

if [[ "$missing_script_status" -eq 0 ]]; then
  echo "[beta-handoff-smoke] expected a non-zero status when a required script is missing" >&2
  echo "$missing_script_output" >&2
  exit 1
fi

if ! grep -Fqx -- '[beta-handoff] missing required script: ./tool/demo_smoke.sh' <<<"$missing_script_output"; then
  echo "[beta-handoff-smoke] missing-script guard output drifted" >&2
  echo "$missing_script_output" >&2
  exit 1
fi

echo "[beta-handoff-smoke] stubbed beta_handoff order stays intact"
echo "[beta-handoff-smoke] all preflight stage labels stay surfaced"
echo "[beta-handoff-smoke] downstream smoke scripts inherit skip version/analyze flags"
echo "[beta-handoff-smoke] verify receives SKIP_PUB_GET=1 from beta_handoff"
echo "[beta-handoff-smoke] built web follow-up labels stay surfaced"
echo "[beta-handoff-smoke] manual follow-up keeps checklist and video workflow pointers visible"
echo "[beta-handoff-smoke] early stage failures stop later preflights and manual follow-up"
echo "[beta-handoff-smoke] missing required scripts fail before startup work begins"
echo "[beta-handoff-smoke] done"
