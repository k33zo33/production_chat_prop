#!/usr/bin/env bash

# Shared helpers for the targeted smoke scripts.
#
# By default each smoke script remains standalone and runs its own Flutter
# version banner plus analyze pass. Aggregators like beta_handoff.sh can set
# SMOKE_SKIP_VERSION=1 and/or SMOKE_SKIP_ANALYZE=1 after handling those steps
# once upstream to keep the full gate stack faster and less repetitive.

smoke_print_flutter_banner() {
  local label="$1"
  local flutter_bin="$2"

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

  if [[ "${SMOKE_SKIP_ANALYZE:-0}" == "1" ]]; then
    echo "[$label] analyze skipped (handled upstream)"
    return
  fi

  echo "[$label] analyze"
  "$flutter_bin" analyze
}
