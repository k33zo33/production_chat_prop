#!/usr/bin/env bash

# Shared helpers for the targeted smoke scripts.
#
# By default each smoke script remains standalone and runs its own Flutter
# version banner plus analyze pass. Aggregators like beta_handoff.sh can set
# SMOKE_SKIP_VERSION=1 and/or SMOKE_SKIP_ANALYZE=1 after handling those steps
# once upstream to keep the full gate stack faster and less repetitive.

smoke_require_binary() {
  local label="$1"
  local binary_path="$2"

  if ! command -v "$binary_path" >/dev/null 2>&1; then
    echo "[$label] missing required binary: $binary_path" >&2
    exit 1
  fi
}

smoke_print_flutter_banner() {
  local label="$1"
  local flutter_bin="$2"

  smoke_require_binary "$label" "$flutter_bin"

  if [[ "${SMOKE_SKIP_VERSION:-0}" == "1" ]]; then
    echo "[$label] using flutter: $flutter_bin (version handled upstream)"
    return
  fi

  echo "[$label] using flutter: $flutter_bin"
  "$flutter_bin" --version
}

smoke_run_analyze() {
  local label="$1"
  local flutter_bin="$2"

  smoke_require_binary "$label" "$flutter_bin"

  if [[ "${SMOKE_SKIP_ANALYZE:-0}" == "1" ]]; then
    echo "[$label] analyze skipped (handled upstream)"
    return
  fi

  echo "[$label] analyze"
  "$flutter_bin" analyze
}

smoke_print_manual_beta_handoff_hint() {
  local label="$1"
  local extra_message="${2:-}"

  echo "[$label] manual follow-up"
  echo "- Then run ./tool/manual_beta_checklist.sh for the shared browser/compact/export handoff order."

  if [[ -n "$extra_message" ]]; then
    echo "- $extra_message"
  fi
}
