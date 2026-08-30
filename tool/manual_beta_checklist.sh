#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WEB_SMOKE_DOC="docs/08-web-smoke-checklist.md"
COMPACT_SMOKE_DOC="docs/09-compact-smoke-checklist.md"
EXPORT_QA_DOC="docs/04-export-qa-checklist.md"
VIDEO_WORKFLOW_DOC="docs/11-video-fallback-workflow.md"
FIXTURE_PATH="docs/fixtures/export-qa-project.json"

for path in \
  "$WEB_SMOKE_DOC" \
  "$COMPACT_SMOKE_DOC" \
  "$EXPORT_QA_DOC" \
  "$VIDEO_WORKFLOW_DOC" \
  "$FIXTURE_PATH"; do
  if [[ ! -f "$path" ]]; then
    echo "[manual-beta-checklist] missing required handoff file: $path" >&2
    exit 1
  fi
done

if [[ ! -s "$FIXTURE_PATH" ]]; then
  echo "[manual-beta-checklist] export QA fixture is empty: $FIXTURE_PATH" >&2
  exit 1
fi

echo "[manual-beta-checklist] automated baseline"
echo "- Start from a green ./tool/beta_handoff.sh run."
echo "- Keep $VIDEO_WORKFLOW_DOC open while validating Export Video behavior."
echo "- Use $FIXTURE_PATH as the standard import/export QA sample."
echo
echo "[manual-beta-checklist] manual pass order"
echo "1) $WEB_SMOKE_DOC"
echo "2) $COMPACT_SMOKE_DOC"
echo "3) $EXPORT_QA_DOC"
echo
echo "[manual-beta-checklist] run target"
echo "- Use a local browser session from /home/server/flutter/bin/flutter run -d web-server"
echo "- Repeat the compact pass around ~390px width and the ultra-compact checks around ~320px width"
echo "- For stale-link spot checks, manually clear ?sceneId=... in editor/playback URLs and confirm the app restores a valid scene"
echo
echo "[manual-beta-checklist] done"
