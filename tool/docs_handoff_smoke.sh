#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

README_PATH="$ROOT_DIR/README.md"
WEB_DONE_PATH="$ROOT_DIR/docs/05-web-done-checklist.md"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/flutter_ci.yml"
BETA_HANDOFF_PATH="$ROOT_DIR/tool/beta_handoff.sh"

for path in "$README_PATH" "$WEB_DONE_PATH" "$WORKFLOW_PATH" "$BETA_HANDOFF_PATH"; do
  if [[ ! -f "$path" ]]; then
    echo "[docs-handoff-smoke] missing required file: $path" >&2
    exit 1
  fi
done

python3 - "$README_PATH" "$WEB_DONE_PATH" "$WORKFLOW_PATH" "$BETA_HANDOFF_PATH" <<'PY'
import pathlib
import re
import sys

_, readme_raw, web_done_raw, workflow_raw, beta_handoff_raw = sys.argv
readme_path = pathlib.Path(readme_raw)
web_done_path = pathlib.Path(web_done_raw)
workflow_path = pathlib.Path(workflow_raw)
beta_handoff_path = pathlib.Path(beta_handoff_raw)

readme = readme_path.read_text(encoding='utf-8')
web_done = web_done_path.read_text(encoding='utf-8')
workflow = workflow_path.read_text(encoding='utf-8')
beta_handoff = beta_handoff_path.read_text(encoding='utf-8')

expected_sequence = (
    'web_shell_smoke -> demo_smoke -> import_smoke -> '
    'release_smoke -> compact_smoke -> verify -> built web_shell_smoke'
)

checks = [
    (expected_sequence in readme,
     'README quality gate sequence is missing import_smoke or is out of date'),
    ('./tool/import_smoke.sh' in readme,
     'README common commands should mention ./tool/import_smoke.sh'),
    (expected_sequence in web_done,
     'docs/05-web-done-checklist.md should describe the current beta handoff order'),
    ('IMPORT_SMOKE_SCRIPT="./tool/import_smoke.sh"' in beta_handoff,
     'tool/beta_handoff.sh must define the import smoke gate'),
    (re.search(r'echo "\[beta-handoff\] import/recovery preflight"\s*\n"\$IMPORT_SMOKE_SCRIPT"', beta_handoff) is not None,
     'tool/beta_handoff.sh must execute the import smoke gate after the import/recovery preflight label'),
    ('run: ./tool/beta_handoff.sh' in workflow,
     'GitHub Actions should keep invoking ./tool/beta_handoff.sh'),
]

for passed, message in checks:
    if not passed:
        raise SystemExit(f'[docs-handoff-smoke] {message}')

print('[docs-handoff-smoke] validated README/docs/workflow beta handoff alignment')
print(f'[docs-handoff-smoke] sequence: {expected_sequence}')
PY

echo "[docs-handoff-smoke] done"
