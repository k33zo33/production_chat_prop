#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

README_PATH="$ROOT_DIR/README.md"
WEB_DONE_PATH="$ROOT_DIR/docs/05-web-done-checklist.md"
EXPORT_QA_PATH="$ROOT_DIR/docs/04-export-qa-checklist.md"
VIDEO_WORKFLOW_PATH="$ROOT_DIR/docs/11-video-fallback-workflow.md"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/flutter_ci.yml"
BETA_HANDOFF_PATH="$ROOT_DIR/tool/beta_handoff.sh"
DEMO_SMOKE_PATH="$ROOT_DIR/tool/demo_smoke.sh"
RELEASE_SMOKE_PATH="$ROOT_DIR/tool/release_smoke.sh"
COMPACT_SMOKE_PATH="$ROOT_DIR/tool/compact_smoke.sh"
IMPORT_SMOKE_PATH="$ROOT_DIR/tool/import_smoke.sh"
WIDGET_TEST_PATH="$ROOT_DIR/test/widget_test.dart"
RECOVERY_TEST_PATH="$ROOT_DIR/test/widget/project_not_found_recovery_test.dart"
CONTROLLER_TEST_PATH="$ROOT_DIR/test/unit/features/projects/presentation/controllers/projects_controller_test.dart"
SANITIZER_TEST_PATH="$ROOT_DIR/test/unit/features/projects/data/services/project_sanitizer_test.dart"
REPOSITORY_TEST_PATH="$ROOT_DIR/test/unit/features/projects/data/repositories/local_project_repository_test.dart"
FIXTURE_TEST_PATH="$ROOT_DIR/test/unit/features/projects/domain/export_qa_fixture_test.dart"

for path in \
  "$README_PATH" \
  "$WEB_DONE_PATH" \
  "$EXPORT_QA_PATH" \
  "$VIDEO_WORKFLOW_PATH" \
  "$WORKFLOW_PATH" \
  "$BETA_HANDOFF_PATH" \
  "$DEMO_SMOKE_PATH" \
  "$RELEASE_SMOKE_PATH" \
  "$COMPACT_SMOKE_PATH" \
  "$IMPORT_SMOKE_PATH" \
  "$WIDGET_TEST_PATH" \
  "$RECOVERY_TEST_PATH" \
  "$CONTROLLER_TEST_PATH" \
  "$SANITIZER_TEST_PATH" \
  "$REPOSITORY_TEST_PATH" \
  "$FIXTURE_TEST_PATH"; do
  if [[ ! -f "$path" ]]; then
    echo "[docs-handoff-smoke] missing required file: $path" >&2
    exit 1
  fi
done

python3 - \
  "$README_PATH" \
  "$WEB_DONE_PATH" \
  "$EXPORT_QA_PATH" \
  "$VIDEO_WORKFLOW_PATH" \
  "$WORKFLOW_PATH" \
  "$BETA_HANDOFF_PATH" \
  "$DEMO_SMOKE_PATH" \
  "$RELEASE_SMOKE_PATH" \
  "$COMPACT_SMOKE_PATH" \
  "$IMPORT_SMOKE_PATH" \
  "$WIDGET_TEST_PATH" \
  "$RECOVERY_TEST_PATH" \
  "$CONTROLLER_TEST_PATH" \
  "$SANITIZER_TEST_PATH" \
  "$REPOSITORY_TEST_PATH" \
  "$FIXTURE_TEST_PATH" <<'PY'
import pathlib
import re
import sys

(
    _,
    readme_raw,
    web_done_raw,
    export_qa_raw,
    video_workflow_raw,
    workflow_raw,
    beta_handoff_raw,
    demo_smoke_raw,
    release_smoke_raw,
    compact_smoke_raw,
    import_smoke_raw,
    widget_test_raw,
    recovery_test_raw,
    controller_test_raw,
    sanitizer_test_raw,
    repository_test_raw,
    fixture_test_raw,
) = sys.argv

readme_path = pathlib.Path(readme_raw)
web_done_path = pathlib.Path(web_done_raw)
export_qa_path = pathlib.Path(export_qa_raw)
video_workflow_path = pathlib.Path(video_workflow_raw)
workflow_path = pathlib.Path(workflow_raw)
beta_handoff_path = pathlib.Path(beta_handoff_raw)
demo_smoke_path = pathlib.Path(demo_smoke_raw)
release_smoke_path = pathlib.Path(release_smoke_raw)
compact_smoke_path = pathlib.Path(compact_smoke_raw)
import_smoke_path = pathlib.Path(import_smoke_raw)
widget_test_path = pathlib.Path(widget_test_raw)
recovery_test_path = pathlib.Path(recovery_test_raw)
controller_test_path = pathlib.Path(controller_test_raw)
sanitizer_test_path = pathlib.Path(sanitizer_test_raw)
repository_test_path = pathlib.Path(repository_test_raw)
fixture_test_path = pathlib.Path(fixture_test_raw)

readme = readme_path.read_text(encoding='utf-8')
web_done = web_done_path.read_text(encoding='utf-8')
export_qa = export_qa_path.read_text(encoding='utf-8')
video_workflow = video_workflow_path.read_text(encoding='utf-8')
workflow = workflow_path.read_text(encoding='utf-8')
beta_handoff = beta_handoff_path.read_text(encoding='utf-8')
demo_smoke = demo_smoke_path.read_text(encoding='utf-8')
release_smoke = release_smoke_path.read_text(encoding='utf-8')
compact_smoke = compact_smoke_path.read_text(encoding='utf-8')
import_smoke = import_smoke_path.read_text(encoding='utf-8')
widget_test = widget_test_path.read_text(encoding='utf-8')
recovery_test = recovery_test_path.read_text(encoding='utf-8')
controller_test = controller_test_path.read_text(encoding='utf-8')
sanitizer_test = sanitizer_test_path.read_text(encoding='utf-8')
repository_test = repository_test_path.read_text(encoding='utf-8')
fixture_test = fixture_test_path.read_text(encoding='utf-8')

expected_sequence = (
    'web_shell_smoke -> demo_smoke -> import_smoke -> '
    'release_smoke -> compact_smoke -> verify -> built web_shell_smoke'
)

checks = [
    (expected_sequence in readme,
     'README quality gate sequence is missing import_smoke or is out of date'),
    ('./tool/import_smoke.sh' in readme,
     'README common commands should mention ./tool/import_smoke.sh'),
    ('desktop_smoke' in readme and './tool/desktop_smoke.sh' in readme,
     'README should mention the separate desktop_smoke gate'),
    (expected_sequence in web_done,
     'docs/05-web-done-checklist.md should describe the current beta handoff order'),
    ('./tool/desktop_smoke.sh' in web_done,
     'docs/05-web-done-checklist.md should mention the desktop smoke gate'),
    ('IMPORT_SMOKE_SCRIPT="./tool/import_smoke.sh"' in beta_handoff,
     'tool/beta_handoff.sh must define the import smoke gate'),
    (re.search(r'echo "\[beta-handoff\] import/recovery preflight"\s*\n"\$IMPORT_SMOKE_SCRIPT"', beta_handoff) is not None,
     'tool/beta_handoff.sh must execute the import smoke gate after the import/recovery preflight label'),
    ('docs/11-video-fallback-workflow.md' in beta_handoff,
     'tool/beta_handoff.sh manual follow-up should include docs/11-video-fallback-workflow.md'),
    ('run: ./tool/beta_handoff.sh' in workflow,
     'GitHub Actions should keep invoking ./tool/beta_handoff.sh'),
    ('desktop_smoke:' in workflow and 'run: ./tool/desktop_smoke.sh' in workflow,
     'GitHub Actions should keep invoking ./tool/desktop_smoke.sh in the desktop_smoke job'),
    ('docs/11-video-fallback-workflow.md' in release_smoke,
     'tool/release_smoke.sh manual follow-up should mention docs/11-video-fallback-workflow.md'),
    ('docs/11-video-fallback-workflow.md' in export_qa,
     'docs/04-export-qa-checklist.md should reference the video fallback workflow explainer'),
    ('docs/04-export-qa-checklist.md' in video_workflow and
     'docs/08-web-smoke-checklist.md' in video_workflow and
     'docs/09-compact-smoke-checklist.md' in video_workflow,
     'docs/11-video-fallback-workflow.md should point back to the export/web/compact manual passes'),
    (re.search(r'payload.*selectedScene.*renderHints.*workflow', export_qa, re.S) is not None and
     'Copy Handoff JSON' in export_qa,
     'docs/04-export-qa-checklist.md should keep the video fallback payload expectations spelled out'),
    ('selectedScene.messages' in video_workflow and 'renderHints.includeDeviceFrame' in video_workflow and 'renderHints.cleanPreview' in video_workflow,
     'docs/11-video-fallback-workflow.md should keep the downstream render contract explicit'),
    ('parses the tracked export QA project for manual beta passes' in fixture_test and
     'video fallback export keeps the selected QA scene synchronized' in fixture_test,
     'export_qa_fixture_test.dart should keep both fixture parsing and fallback synchronization coverage'),
]

for passed, message in checks:
    if not passed:
        raise SystemExit(f'[docs-handoff-smoke] {message}')


def extract_declared_names(script_text: str, array_name: str) -> list[str]:
    pattern = re.compile(
        rf'declare -a {re.escape(array_name)}=\((.*?)\n\s*\)',
        re.S,
    )
    match = pattern.search(script_text)
    if match is None:
        raise SystemExit(
            f'[docs-handoff-smoke] missing array {array_name!r} in smoke script'
        )
    matches = re.findall(r"'([^']+)'|\"([^\"]+)\"", match.group(1))
    return [single_quoted or double_quoted for single_quoted, double_quoted in matches]


# One-directional on purpose: smoke scripts curate targeted subsets, so this
# catches stale renamed/deleted entries without requiring every new test to be
# added to a smoke catalog.
def assert_names_exist(
    *,
    script_label: str,
    array_name: str,
    script_text: str,
    target_label: str,
    target_text: str,
) -> None:
    names = extract_declared_names(script_text, array_name)
    missing = [
        name
        for name in names
        if re.search(rf"'{re.escape(name)}'|\"{re.escape(name)}\"", target_text)
        is None
    ]
    if missing:
        missing_lines = '\n'.join(f'  - {name}' for name in missing)
        raise SystemExit(
            f'[docs-handoff-smoke] {script_label} has stale {array_name} entries '
            f'for {target_label}:\n{missing_lines}'
        )


assert_names_exist(
    script_label='tool/demo_smoke.sh',
    array_name='TEST_NAMES',
    script_text=demo_smoke,
    target_label='test/widget_test.dart',
    target_text=widget_test,
)
assert_names_exist(
    script_label='tool/release_smoke.sh',
    array_name='TEST_NAMES',
    script_text=release_smoke,
    target_label='test/widget_test.dart',
    target_text=widget_test,
)
assert_names_exist(
    script_label='tool/compact_smoke.sh',
    array_name='TEST_NAMES',
    script_text=compact_smoke,
    target_label='test/widget_test.dart',
    target_text=widget_test,
)
assert_names_exist(
    script_label='tool/compact_smoke.sh',
    array_name='RECOVERY_TEST_NAMES',
    script_text=compact_smoke,
    target_label='test/widget/project_not_found_recovery_test.dart',
    target_text=recovery_test,
)
assert_names_exist(
    script_label='tool/import_smoke.sh',
    array_name='CONTROLLER_TEST_NAMES',
    script_text=import_smoke,
    target_label='projects_controller_test.dart',
    target_text=controller_test,
)
assert_names_exist(
    script_label='tool/import_smoke.sh',
    array_name='SANITIZER_TEST_NAMES',
    script_text=import_smoke,
    target_label='project_sanitizer_test.dart',
    target_text=sanitizer_test,
)
assert_names_exist(
    script_label='tool/import_smoke.sh',
    array_name='REPOSITORY_TEST_NAMES',
    script_text=import_smoke,
    target_label='local_project_repository_test.dart',
    target_text=repository_test,
)

print('[docs-handoff-smoke] validated README/docs/workflow beta handoff alignment')
print(f'[docs-handoff-smoke] sequence: {expected_sequence}')
print('[docs-handoff-smoke] desktop smoke documentation/workflow checks are in sync')
print('[docs-handoff-smoke] video fallback handoff docs stay linked to the manual release gates')
print('[docs-handoff-smoke] smoke script test-name catalogs are in sync')
PY

echo "[docs-handoff-smoke] done"
