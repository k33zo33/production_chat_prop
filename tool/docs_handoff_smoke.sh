#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

README_PATH="$ROOT_DIR/README.md"
DOCS_README_PATH="$ROOT_DIR/docs/README.md"
AI_HELPER_WORKFLOW_PATH="$ROOT_DIR/docs/10-ai-helper-workflow.md"
WEB_DONE_PATH="$ROOT_DIR/docs/05-web-done-checklist.md"
EXPORT_QA_PATH="$ROOT_DIR/docs/04-export-qa-checklist.md"
WEB_SMOKE_PATH="$ROOT_DIR/docs/08-web-smoke-checklist.md"
COMPACT_SMOKE_DOC_PATH="$ROOT_DIR/docs/09-compact-smoke-checklist.md"
VIDEO_WORKFLOW_PATH="$ROOT_DIR/docs/11-video-fallback-workflow.md"
EXPORT_QA_FIXTURE_PATH="$ROOT_DIR/docs/fixtures/export-qa-project.json"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/flutter_ci.yml"
BETA_HANDOFF_PATH="$ROOT_DIR/tool/beta_handoff.sh"
MANUAL_BETA_CHECKLIST_PATH="$ROOT_DIR/tool/manual_beta_checklist.sh"
SMOKE_COMMON_PATH="$ROOT_DIR/tool/smoke_common.sh"
BRAND_SMOKE_PATH="$ROOT_DIR/tool/brand_neutrality_smoke.sh"
DEMO_SMOKE_PATH="$ROOT_DIR/tool/demo_smoke.sh"
RELEASE_SMOKE_PATH="$ROOT_DIR/tool/release_smoke.sh"
COMPACT_SMOKE_PATH="$ROOT_DIR/tool/compact_smoke.sh"
NAVIGATION_SMOKE_PATH="$ROOT_DIR/tool/navigation_smoke.sh"
IMPORT_SMOKE_PATH="$ROOT_DIR/tool/import_smoke.sh"
VERIFY_PATH="$ROOT_DIR/tool/verify.sh"
AI_HELPER_PATH="$ROOT_DIR/tool/ai_helper.sh"
AI_HELPER_SMOKE_PATH="$ROOT_DIR/tool/ai_helper_smoke.sh"
BETA_HANDOFF_SMOKE_PATH="$ROOT_DIR/tool/beta_handoff_smoke.sh"
WIDGET_TEST_PATH="$ROOT_DIR/test/widget_test.dart"
PLAYBACK_EXPORT_FEEDBACK_TEST_PATH="$ROOT_DIR/test/widget/playback_export_feedback_test.dart"
SCENE_ROUTE_SYNC_TEST_PATH="$ROOT_DIR/test/widget/scene_route_sync_test.dart"
RECOVERY_TEST_PATH="$ROOT_DIR/test/widget/project_not_found_recovery_test.dart"
CONTROLLER_TEST_PATH="$ROOT_DIR/test/unit/features/projects/presentation/controllers/projects_controller_test.dart"
SANITIZER_TEST_PATH="$ROOT_DIR/test/unit/features/projects/data/services/project_sanitizer_test.dart"
REPOSITORY_TEST_PATH="$ROOT_DIR/test/unit/features/projects/data/repositories/local_project_repository_test.dart"
FIXTURE_TEST_PATH="$ROOT_DIR/test/unit/features/projects/domain/export_qa_fixture_test.dart"

for path in \
  "$README_PATH" \
  "$DOCS_README_PATH" \
  "$AI_HELPER_WORKFLOW_PATH" \
  "$WEB_DONE_PATH" \
  "$EXPORT_QA_PATH" \
  "$WEB_SMOKE_PATH" \
  "$COMPACT_SMOKE_DOC_PATH" \
  "$VIDEO_WORKFLOW_PATH" \
  "$EXPORT_QA_FIXTURE_PATH" \
  "$WORKFLOW_PATH" \
  "$BETA_HANDOFF_PATH" \
  "$MANUAL_BETA_CHECKLIST_PATH" \
  "$SMOKE_COMMON_PATH" \
  "$BRAND_SMOKE_PATH" \
  "$DEMO_SMOKE_PATH" \
  "$RELEASE_SMOKE_PATH" \
  "$COMPACT_SMOKE_PATH" \
  "$NAVIGATION_SMOKE_PATH" \
  "$IMPORT_SMOKE_PATH" \
  "$VERIFY_PATH" \
  "$AI_HELPER_PATH" \
  "$AI_HELPER_SMOKE_PATH" \
  "$BETA_HANDOFF_SMOKE_PATH" \
  "$WIDGET_TEST_PATH" \
  "$PLAYBACK_EXPORT_FEEDBACK_TEST_PATH" \
  "$SCENE_ROUTE_SYNC_TEST_PATH" \
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
  "$DOCS_README_PATH" \
  "$AI_HELPER_WORKFLOW_PATH" \
  "$WEB_DONE_PATH" \
  "$EXPORT_QA_PATH" \
  "$WEB_SMOKE_PATH" \
  "$COMPACT_SMOKE_DOC_PATH" \
  "$VIDEO_WORKFLOW_PATH" \
  "$EXPORT_QA_FIXTURE_PATH" \
  "$WORKFLOW_PATH" \
  "$BETA_HANDOFF_PATH" \
  "$MANUAL_BETA_CHECKLIST_PATH" \
  "$SMOKE_COMMON_PATH" \
  "$BRAND_SMOKE_PATH" \
  "$DEMO_SMOKE_PATH" \
  "$RELEASE_SMOKE_PATH" \
  "$COMPACT_SMOKE_PATH" \
  "$NAVIGATION_SMOKE_PATH" \
  "$IMPORT_SMOKE_PATH" \
  "$VERIFY_PATH" \
  "$AI_HELPER_PATH" \
  "$AI_HELPER_SMOKE_PATH" \
  "$BETA_HANDOFF_SMOKE_PATH" \
  "$WIDGET_TEST_PATH" \
  "$PLAYBACK_EXPORT_FEEDBACK_TEST_PATH" \
  "$SCENE_ROUTE_SYNC_TEST_PATH" \
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
    docs_readme_raw,
    ai_helper_workflow_raw,
    web_done_raw,
    export_qa_raw,
    web_smoke_raw,
    compact_smoke_doc_raw,
    video_workflow_raw,
    export_qa_fixture_raw,
    workflow_raw,
    beta_handoff_raw,
    manual_beta_checklist_raw,
    smoke_common_raw,
    brand_smoke_raw,
    demo_smoke_raw,
    release_smoke_raw,
    compact_smoke_raw,
    navigation_smoke_raw,
    import_smoke_raw,
    verify_raw,
    ai_helper_raw,
    ai_helper_smoke_raw,
    beta_handoff_smoke_raw,
    widget_test_raw,
    playback_export_feedback_test_raw,
    scene_route_sync_test_raw,
    recovery_test_raw,
    controller_test_raw,
    sanitizer_test_raw,
    repository_test_raw,
    fixture_test_raw,
) = sys.argv

readme_path = pathlib.Path(readme_raw)
docs_readme_path = pathlib.Path(docs_readme_raw)
ai_helper_workflow_path = pathlib.Path(ai_helper_workflow_raw)
web_done_path = pathlib.Path(web_done_raw)
export_qa_path = pathlib.Path(export_qa_raw)
web_smoke_path = pathlib.Path(web_smoke_raw)
compact_smoke_doc_path = pathlib.Path(compact_smoke_doc_raw)
video_workflow_path = pathlib.Path(video_workflow_raw)
export_qa_fixture_path = pathlib.Path(export_qa_fixture_raw)
workflow_path = pathlib.Path(workflow_raw)
beta_handoff_path = pathlib.Path(beta_handoff_raw)
manual_beta_checklist_path = pathlib.Path(manual_beta_checklist_raw)
smoke_common_path = pathlib.Path(smoke_common_raw)
brand_smoke_path = pathlib.Path(brand_smoke_raw)
demo_smoke_path = pathlib.Path(demo_smoke_raw)
release_smoke_path = pathlib.Path(release_smoke_raw)
compact_smoke_path = pathlib.Path(compact_smoke_raw)
navigation_smoke_path = pathlib.Path(navigation_smoke_raw)
import_smoke_path = pathlib.Path(import_smoke_raw)
verify_path = pathlib.Path(verify_raw)
ai_helper_path = pathlib.Path(ai_helper_raw)
ai_helper_smoke_path = pathlib.Path(ai_helper_smoke_raw)
beta_handoff_smoke_path = pathlib.Path(beta_handoff_smoke_raw)
widget_test_path = pathlib.Path(widget_test_raw)
playback_export_feedback_test_path = pathlib.Path(playback_export_feedback_test_raw)
scene_route_sync_test_path = pathlib.Path(scene_route_sync_test_raw)
recovery_test_path = pathlib.Path(recovery_test_raw)
controller_test_path = pathlib.Path(controller_test_raw)
sanitizer_test_path = pathlib.Path(sanitizer_test_raw)
repository_test_path = pathlib.Path(repository_test_raw)
fixture_test_path = pathlib.Path(fixture_test_raw)

readme = readme_path.read_text(encoding='utf-8')
docs_readme = docs_readme_path.read_text(encoding='utf-8')
ai_helper_workflow = ai_helper_workflow_path.read_text(encoding='utf-8')
web_done = web_done_path.read_text(encoding='utf-8')
export_qa = export_qa_path.read_text(encoding='utf-8')
web_smoke = web_smoke_path.read_text(encoding='utf-8')
compact_smoke_doc = compact_smoke_doc_path.read_text(encoding='utf-8')
video_workflow = video_workflow_path.read_text(encoding='utf-8')
export_qa_fixture = export_qa_fixture_path.read_text(encoding='utf-8')
workflow = workflow_path.read_text(encoding='utf-8')
beta_handoff = beta_handoff_path.read_text(encoding='utf-8')
manual_beta_checklist = manual_beta_checklist_path.read_text(encoding='utf-8')
smoke_common = smoke_common_path.read_text(encoding='utf-8')
brand_smoke = brand_smoke_path.read_text(encoding='utf-8')
demo_smoke = demo_smoke_path.read_text(encoding='utf-8')
release_smoke = release_smoke_path.read_text(encoding='utf-8')
compact_smoke = compact_smoke_path.read_text(encoding='utf-8')
navigation_smoke = navigation_smoke_path.read_text(encoding='utf-8')
import_smoke = import_smoke_path.read_text(encoding='utf-8')
verify = verify_path.read_text(encoding='utf-8')
ai_helper = ai_helper_path.read_text(encoding='utf-8')
ai_helper_smoke = ai_helper_smoke_path.read_text(encoding='utf-8')
beta_handoff_smoke = beta_handoff_smoke_path.read_text(encoding='utf-8')
widget_test = widget_test_path.read_text(encoding='utf-8')
playback_export_feedback_test = playback_export_feedback_test_path.read_text(encoding='utf-8')
scene_route_sync_test = scene_route_sync_test_path.read_text(encoding='utf-8')
recovery_test = recovery_test_path.read_text(encoding='utf-8')
controller_test = controller_test_path.read_text(encoding='utf-8')
sanitizer_test = sanitizer_test_path.read_text(encoding='utf-8')
repository_test = repository_test_path.read_text(encoding='utf-8')
fixture_test = fixture_test_path.read_text(encoding='utf-8')

expected_sequence = (
    'docs_handoff_smoke -> ai_helper_smoke -> web_shell_smoke -> brand_neutrality_smoke -> demo_smoke -> '
    'import_smoke -> release_smoke -> compact_smoke -> navigation_smoke -> verify -> '
    'built web_shell_smoke -> built brand_neutrality_smoke'
)

tool_dir = beta_handoff_path.parent
public_tool_scripts = sorted(
    path.name for path in tool_dir.glob('*.sh') if path.name != 'smoke_common.sh'
)

docs_readme_tool_markers = {
    'ai_helper.sh': './tool/ai_helper.sh',
    'ai_helper_smoke.sh': './tool/ai_helper_smoke.sh',
    'beta_handoff.sh': './tool/beta_handoff.sh',
    'beta_handoff_smoke.sh': './tool/beta_handoff_smoke.sh',
    'brand_neutrality_smoke.sh': './tool/brand_neutrality_smoke.sh',
    'compact_smoke.sh': './tool/compact_smoke.sh',
    'demo_smoke.sh': './tool/demo_smoke.sh',
    'desktop_docker.sh': './tool/desktop_docker.sh',
    'desktop_smoke.sh': './tool/desktop_smoke.sh',
    'docs_handoff_smoke.sh': './tool/docs_handoff_smoke.sh',
    'import_smoke.sh': './tool/import_smoke.sh',
    'manual_beta_checklist.sh': './tool/manual_beta_checklist.sh',
    'navigation_smoke.sh': './tool/navigation_smoke.sh',
    'release_smoke.sh': './tool/release_smoke.sh',
    'verify.sh': './tool/verify.sh',
    'web_shell_smoke.sh': './tool/web_shell_smoke.sh',
}

docs_workflow_section_markers = {
    'ai_helper.sh': 'tool/ai_helper.sh',
    'ai_helper_smoke.sh': 'tool/ai_helper_smoke.sh',
    'beta_handoff.sh': 'tool/beta_handoff.sh',
    'beta_handoff_smoke.sh': 'tool/beta_handoff_smoke.sh',
    'brand_neutrality_smoke.sh': 'tool/brand_neutrality_smoke.sh',
    'compact_smoke.sh': 'tool/compact_smoke.sh',
    'demo_smoke.sh': 'tool/demo_smoke.sh',
    'desktop_docker.sh': 'tool/desktop_docker.sh',
    'desktop_smoke.sh': 'tool/desktop_smoke.sh',
    'docs_handoff_smoke.sh': 'tool/docs_handoff_smoke.sh',
    'import_smoke.sh': 'tool/import_smoke.sh',
    'manual_beta_checklist.sh': 'tool/manual_beta_checklist.sh',
    'navigation_smoke.sh': 'tool/navigation_smoke.sh',
    'release_smoke.sh': 'tool/release_smoke.sh',
    'verify.sh': 'tool/verify.sh',
    'web_shell_smoke.sh': 'tool/web_shell_smoke.sh',
}

readme_command_markers = {
    'ai_helper.sh': './tool/ai_helper.sh doctor',
    'ai_helper_smoke.sh': './tool/ai_helper_smoke.sh',
    'beta_handoff.sh': './tool/beta_handoff.sh',
    'beta_handoff_smoke.sh': './tool/beta_handoff_smoke.sh',
    'brand_neutrality_smoke.sh': './tool/brand_neutrality_smoke.sh',
    'compact_smoke.sh': './tool/compact_smoke.sh',
    'demo_smoke.sh': './tool/demo_smoke.sh',
    'desktop_docker.sh': './tool/desktop_docker.sh',
    'desktop_smoke.sh': './tool/desktop_smoke.sh',
    'docs_handoff_smoke.sh': './tool/docs_handoff_smoke.sh',
    'import_smoke.sh': './tool/import_smoke.sh',
    'manual_beta_checklist.sh': './tool/manual_beta_checklist.sh',
    'navigation_smoke.sh': './tool/navigation_smoke.sh',
    'release_smoke.sh': './tool/release_smoke.sh',
    'verify.sh': './tool/verify.sh',
    'web_shell_smoke.sh': './tool/web_shell_smoke.sh web',
}

missing_docs_readme_markers = sorted(
    script_name
    for script_name in public_tool_scripts
    if docs_readme_tool_markers.get(script_name) not in docs_readme
)

missing_readme_command_markers = sorted(
    script_name
    for script_name in public_tool_scripts
    if readme_command_markers.get(script_name) not in readme
)

readme_command_block_match = re.search(
    r'Najčešće komande:\s*```bash\n(?P<body>.*?)\n```',
    readme,
    re.S,
)
if readme_command_block_match is None:
    raise SystemExit('[docs-handoff-smoke] README is missing the "Najčešće komande" bash block')
readme_command_block = readme_command_block_match.group('body')

docs_workflow_section_match = re.search(
    r'## Developer workflow docs\n(?P<body>.*?)\n## Recommended reading order',
    docs_readme,
    re.S,
)
if docs_workflow_section_match is None:
    raise SystemExit('[docs-handoff-smoke] docs/README.md is missing the "Developer workflow docs" section shape')
docs_workflow_section = docs_workflow_section_match.group('body')

missing_readme_block_markers = sorted(
    script_name
    for script_name in public_tool_scripts
    if readme_command_markers[script_name] not in readme_command_block
)

missing_docs_workflow_markers = sorted(
    script_name
    for script_name in public_tool_scripts
    if docs_workflow_section_markers[script_name] not in docs_workflow_section
)

duplicate_readme_block_markers = sorted(
    script_name
    for script_name in public_tool_scripts
    if readme_command_block.count(readme_command_markers[script_name]) != 1
)

duplicate_docs_workflow_markers = sorted(
    script_name
    for script_name in public_tool_scripts
    if docs_workflow_section.count(docs_workflow_section_markers[script_name]) != 1
)

expected_readme_command_block_lines = [
    readme_command_markers[script_name]
    for script_name in (
        'demo_smoke.sh',
        'brand_neutrality_smoke.sh',
        'import_smoke.sh',
        'release_smoke.sh',
        'compact_smoke.sh',
        'navigation_smoke.sh',
        'desktop_docker.sh',
        'desktop_smoke.sh',
        'web_shell_smoke.sh',
        'verify.sh',
        'docs_handoff_smoke.sh',
        'beta_handoff.sh',
        'beta_handoff_smoke.sh',
        'manual_beta_checklist.sh',
        'ai_helper.sh',
        'ai_helper_smoke.sh',
    )
]

actual_readme_command_block_lines = [
    line.strip()
    for line in readme_command_block.splitlines()
    if line.strip() in expected_readme_command_block_lines
]

expected_docs_workflow_lines = [
    docs_workflow_section_markers[script_name]
    for script_name in (
        'ai_helper.sh',
        'verify.sh',
        'beta_handoff.sh',
        'demo_smoke.sh',
        'release_smoke.sh',
        'compact_smoke.sh',
        'import_smoke.sh',
        'brand_neutrality_smoke.sh',
        'navigation_smoke.sh',
        'desktop_docker.sh',
        'manual_beta_checklist.sh',
        'desktop_smoke.sh',
        'web_shell_smoke.sh',
        'docs_handoff_smoke.sh',
        'ai_helper_smoke.sh',
        'beta_handoff_smoke.sh',
    )
]

actual_docs_workflow_lines = [
    line.strip().split('`')[1]
    for line in docs_workflow_section.splitlines()
    if line.strip().startswith('- `tool/')
]

checks = [
    (video_workflow_path.is_file(),
     'docs/11-video-fallback-workflow.md must exist because the manual beta handoff points users there'),
    (export_qa_fixture_path.is_file(),
     'docs/fixtures/export-qa-project.json must exist because the manual beta handoff uses it as the standard QA sample'),
    (len(export_qa_fixture.strip()) > 0,
     'docs/fixtures/export-qa-project.json must stay non-empty so the standard QA sample remains usable'),
    (expected_sequence in readme,
     'README quality gate sequence is missing ai_helper_smoke/docs_handoff_smoke/navigation_smoke or is out of date'),
    (set(public_tool_scripts) == set(docs_readme_tool_markers),
     'tool/docs_handoff_smoke.sh docs_readme_tool_markers must cover every public tool/*.sh script except smoke_common.sh'),
    (set(public_tool_scripts) == set(docs_workflow_section_markers),
     'tool/docs_handoff_smoke.sh docs_workflow_section_markers must cover every public tool/*.sh script except smoke_common.sh'),
    (set(public_tool_scripts) == set(readme_command_markers),
     'tool/docs_handoff_smoke.sh readme_command_markers must cover every public tool/*.sh script except smoke_common.sh'),
    (not missing_docs_readme_markers,
     'docs/README.md is missing first-class tool entries for: ' + ', '.join(missing_docs_readme_markers)),
    (not missing_readme_command_markers,
     'README common commands are missing entries for: ' + ', '.join(missing_readme_command_markers)),
    (not missing_readme_block_markers,
     'README "Najčešće komande" block is missing entries for: ' + ', '.join(missing_readme_block_markers)),
    (not missing_docs_workflow_markers,
     'docs/README.md "Developer workflow docs" section is missing entries for: ' + ', '.join(missing_docs_workflow_markers)),
    (not duplicate_readme_block_markers,
     'README "Najčešće komande" block should list each public tool exactly once: ' + ', '.join(duplicate_readme_block_markers)),
    (not duplicate_docs_workflow_markers,
     'docs/README.md "Developer workflow docs" section should list each public tool exactly once: ' + ', '.join(duplicate_docs_workflow_markers)),
    (actual_readme_command_block_lines == expected_readme_command_block_lines,
     'README "Najčešće komande" block should keep the curated public tool order'),
    (actual_docs_workflow_lines == expected_docs_workflow_lines,
     'docs/README.md "Developer workflow docs" section should keep the curated public tool order'),
    (len(re.findall(r'^- Za helper/review rad:', docs_readme, re.M)) == 1,
     'docs/README.md should keep exactly one canonical helper/review practical-usage bullet'),
    ('./tool/import_smoke.sh' in readme,
     'README common commands should mention ./tool/import_smoke.sh'),
    ('./tool/brand_neutrality_smoke.sh' in readme,
     'README common commands should mention ./tool/brand_neutrality_smoke.sh'),
    ('./tool/navigation_smoke.sh' in readme,
     'README common commands should mention ./tool/navigation_smoke.sh'),
    ('./tool/desktop_docker.sh' in readme,
     'README common commands should mention ./tool/desktop_docker.sh'),
    ('./tool/web_shell_smoke.sh web' in readme,
     'README common commands should mention ./tool/web_shell_smoke.sh web'),
    ('./tool/manual_beta_checklist.sh' in readme,
     'README common commands should mention ./tool/manual_beta_checklist.sh'),
    ('./tool/ai_helper.sh doctor' in readme,
     'README common commands should mention ./tool/ai_helper.sh doctor'),
    ('./tool/ai_helper.sh preview-ask "Summarize the main playback export risks."' in readme,
     'README common commands should mention the preview-ask helper example'),
    ('./tool/ai_helper.sh preview-review -- tool/ai_helper.sh' in readme,
     'README common commands should mention the preview-review helper example'),
    ('./tool/ai_helper_smoke.sh' in readme,
     'README common commands should mention ./tool/ai_helper_smoke.sh'),
    ('./tool/docs_handoff_smoke.sh' in readme,
     'README common commands should mention ./tool/docs_handoff_smoke.sh'),
    ('./tool/beta_handoff_smoke.sh' in readme,
     'README common commands should mention ./tool/beta_handoff_smoke.sh'),
    ('desktop_smoke' in readme and './tool/desktop_smoke.sh' in readme,
     'README should mention the separate desktop_smoke gate'),
    ('./tool/ai_helper.sh' in docs_readme and './tool/ai_helper.sh doctor' in docs_readme and './tool/ai_helper.sh review' in docs_readme and './tool/ai_helper.sh ask "' in docs_readme and './tool/ai_helper_smoke.sh' in docs_readme and './tool/ai_helper.sh preview-ask' in docs_readme and './tool/ai_helper.sh preview-review' in docs_readme and '10-ai-helper-workflow.md' in docs_readme,
     'docs/README.md should point helper users to ai_helper.sh plus doctor/review/ask/preview modes, ai_helper_smoke, and 10-ai-helper-workflow.md'),
    ('./tool/beta_handoff_smoke.sh' in docs_readme,
     'docs/README.md should point release-gate users to ./tool/beta_handoff_smoke.sh'),
    ('./tool/docs_handoff_smoke.sh' in docs_readme,
     'docs/README.md should point release-gate users to ./tool/docs_handoff_smoke.sh'),
    ('./tool/verify.sh' in docs_readme,
     'docs/README.md should point release-gate users to ./tool/verify.sh'),
    ('./tool/beta_handoff.sh' in docs_readme,
     'docs/README.md should point release-gate users to ./tool/beta_handoff.sh'),
    ('./tool/manual_beta_checklist.sh' in docs_readme,
     'docs/README.md should point release-gate users to ./tool/manual_beta_checklist.sh'),
    ('./tool/demo_smoke.sh' in docs_readme,
     'docs/README.md should point demo-flow users to ./tool/demo_smoke.sh'),
    ('./tool/release_smoke.sh' in docs_readme,
     'docs/README.md should point export/reliability users to ./tool/release_smoke.sh'),
    ('./tool/compact_smoke.sh' in docs_readme,
     'docs/README.md should point compact/mobile users to ./tool/compact_smoke.sh'),
    ('./tool/import_smoke.sh' in docs_readme,
     'docs/README.md should point import/recovery users to ./tool/import_smoke.sh'),
    ('./tool/brand_neutrality_smoke.sh' in docs_readme,
     'docs/README.md should point copy/branding users to ./tool/brand_neutrality_smoke.sh'),
    ('./tool/navigation_smoke.sh' in docs_readme,
     'docs/README.md should point navigation users to ./tool/navigation_smoke.sh'),
    ('./tool/desktop_docker.sh' in docs_readme,
     'docs/README.md should point desktop launcher users to ./tool/desktop_docker.sh'),
    ('./tool/desktop_smoke.sh' in docs_readme,
     'docs/README.md should point desktop fallback users to ./tool/desktop_smoke.sh'),
    ('./tool/web_shell_smoke.sh' in docs_readme,
     'docs/README.md should point web shell users to ./tool/web_shell_smoke.sh'),
    ('./tool/ai_helper.sh doctor' in ai_helper_workflow,
     'docs/10-ai-helper-workflow.md should document ./tool/ai_helper.sh doctor'),
    ('./tool/ai_helper.sh preview-ask "Pregledaj helper fallback rizike."' in ai_helper_workflow,
     'docs/10-ai-helper-workflow.md should document the preview-ask helper example'),
    ('./tool/ai_helper.sh preview-review -- tool/ai_helper.sh' in ai_helper_workflow,
     'docs/10-ai-helper-workflow.md should document the preview-review helper example'),
    ('./tool/ai_helper_smoke.sh' in ai_helper_workflow,
     'docs/10-ai-helper-workflow.md should document ./tool/ai_helper_smoke.sh'),
    ('./tool/ai_helper.sh review -- tool/ai_helper.sh docs/10-ai-helper-workflow.md' in ai_helper_workflow,
     'docs/10-ai-helper-workflow.md should show the path-filter review example'),
    ('./tool/ai_helper.sh review HEAD~1..HEAD -- tool/ai_helper.sh' in ai_helper_workflow,
     'docs/10-ai-helper-workflow.md should show the combined diff-range plus path-filter review example'),
    ('HELPER_TIMEOUT_SECONDS' in ai_helper_workflow,
     'docs/10-ai-helper-workflow.md should mention HELPER_TIMEOUT_SECONDS in the doctor preflight section'),
    (expected_sequence in web_done,
     'docs/05-web-done-checklist.md should describe the current beta handoff order including docs_handoff_smoke'),
    ('./tool/desktop_smoke.sh' in web_done,
     'docs/05-web-done-checklist.md should mention the desktop smoke gate'),
    ('./tool/ai_helper_smoke.sh' in web_done,
     'docs/05-web-done-checklist.md should mention the AI helper smoke gate'),
    ('./tool/beta_handoff_smoke.sh' in web_done,
     'docs/05-web-done-checklist.md should mention the beta handoff shell smoke gate'),
    ('./tool/brand_neutrality_smoke.sh' in web_done,
     'docs/05-web-done-checklist.md should mention the brand-neutrality smoke gate'),
    ('navigation_smoke' in web_done and './tool/navigation_smoke.sh' in web_done,
     'docs/05-web-done-checklist.md should mention the navigation smoke gate'),
    ('./tool/manual_beta_checklist.sh' in web_done,
     'docs/05-web-done-checklist.md should mention the manual beta checklist helper'),
    ('manual_beta_checklist.sh' in web_done and '11-video-fallback-workflow.md' in web_done,
     'docs/05-web-done-checklist.md should keep the manual checklist helper tied to the video fallback handoff doc'),
    ('coverage drift' in readme and './tool/release_smoke.sh' in readme and './tool/compact_smoke.sh' in readme,
     'README should mention that release_smoke and compact_smoke fail on dedicated test-file coverage drift'),
    ('coverage-count drift' in web_done and 'release_smoke' in web_done and 'compact_smoke' in web_done,
     'docs/05-web-done-checklist.md should mention the focused coverage-drift guard behavior for release_smoke and compact_smoke'),
    ('SMOKE_SKIP_VERSION=1' in beta_handoff and 'SMOKE_SKIP_ANALYZE=1' in beta_handoff and 'SKIP_PUB_GET=1 "$VERIFY_SCRIPT"' in beta_handoff,
     'tool/beta_handoff.sh should keep the upstream skip flags that prevent duplicate Flutter banner/analyze/pub-get work'),
    ('pub get skipped (already resolved upstream)' in verify,
     'tool/verify.sh should keep the explicit upstream pub-get skip path used by beta_handoff'),
    ('SMOKE_SKIP_VERSION=1' in smoke_common and 'SMOKE_SKIP_ANALYZE=1' in smoke_common,
     'tool/smoke_common.sh comments should keep documenting the upstream skip-flag optimization'),
    ('stubbed beta_handoff order stays intact' in beta_handoff_smoke and
     'downstream smoke scripts inherit skip version/analyze flags' in beta_handoff_smoke and
     'verify receives SKIP_PUB_GET=1 from beta_handoff' in beta_handoff_smoke and
     'early stage failures stop later preflights and manual follow-up' in beta_handoff_smoke and
     'missing required scripts fail before startup work begins' in beta_handoff_smoke,
     'tool/beta_handoff_smoke.sh should keep validating beta_handoff order, startup/failure stops, and skip-flag wiring'),
    ('skip ponovljenog flutter bannera' in readme and 'skip dodatnog analyze' in readme and 'skip ponovnog `pub get`' in readme,
     'README should mention that beta_handoff reuses the upstream Flutter banner/analyze/pub-get steps to stay faster'),
    ('skip ponovljenog flutter bannera' in web_done and 'skip dodatnog analyze' in web_done and 'skip ponovnog `pub get`' in web_done,
     'docs/05-web-done-checklist.md should mention the beta_handoff upstream skip optimization'),
    ('DOCS_HANDOFF_SMOKE_SCRIPT="./tool/docs_handoff_smoke.sh"' in beta_handoff,
     'tool/beta_handoff.sh must define the docs handoff smoke gate'),
    ('AI_HELPER_SMOKE_SCRIPT="./tool/ai_helper_smoke.sh"' in beta_handoff,
     'tool/beta_handoff.sh must define the AI helper smoke gate'),
    ('BRAND_NEUTRALITY_SMOKE_SCRIPT="./tool/brand_neutrality_smoke.sh"' in beta_handoff,
     'tool/beta_handoff.sh must define the brand-neutrality smoke gate'),
    ('IMPORT_SMOKE_SCRIPT="./tool/import_smoke.sh"' in beta_handoff,
     'tool/beta_handoff.sh must define the import smoke gate'),
    ('NAVIGATION_SMOKE_SCRIPT="./tool/navigation_smoke.sh"' in beta_handoff,
     'tool/beta_handoff.sh must define the navigation smoke gate'),
    (re.search(r'echo "\[beta-handoff\] helper workflow preflight"\s*\n"\$AI_HELPER_SMOKE_SCRIPT"', beta_handoff) is not None,
     'tool/beta_handoff.sh must execute the AI helper smoke gate after the helper-workflow preflight label'),
    (re.search(r'echo "\[beta-handoff\] brand-neutrality preflight"\s*\n"\$BRAND_NEUTRALITY_SMOKE_SCRIPT" lib web', beta_handoff) is not None,
     'tool/beta_handoff.sh must execute the brand-neutrality smoke gate after the brand-neutrality preflight label'),
    (re.search(r'echo "\[beta-handoff\] import/recovery preflight"\s*\n"\$IMPORT_SMOKE_SCRIPT"', beta_handoff) is not None,
     'tool/beta_handoff.sh must execute the import smoke gate after the import/recovery preflight label'),
    (re.search(r'echo "\[beta-handoff\] navigation/deep-link preflight"\s*\n"\$NAVIGATION_SMOKE_SCRIPT"', beta_handoff) is not None,
     'tool/beta_handoff.sh must execute the navigation smoke gate after the navigation/deep-link preflight label'),
    (re.search(r'echo "\[beta-handoff\] built web brand-neutrality check"\s*\n"\$BRAND_NEUTRALITY_SMOKE_SCRIPT" build/web', beta_handoff) is not None,
     'tool/beta_handoff.sh must execute the built web brand-neutrality smoke gate after the built-web label'),
    ('MANUAL_BETA_CHECKLIST_SCRIPT="./tool/manual_beta_checklist.sh"' in beta_handoff,
     'tool/beta_handoff.sh must define the manual beta checklist helper'),
    (re.search(r'echo "- \./tool/manual_beta_checklist\.sh"\s*\n.*"\$MANUAL_BETA_CHECKLIST_SCRIPT"', beta_handoff, re.S) is not None,
     'tool/beta_handoff.sh manual follow-up should announce and execute the manual beta checklist helper'),
    ('docs/11-video-fallback-workflow.md' in beta_handoff,
     'tool/beta_handoff.sh manual follow-up should include docs/11-video-fallback-workflow.md'),
    ('docs/08-web-smoke-checklist.md' in manual_beta_checklist and
     'docs/09-compact-smoke-checklist.md' in manual_beta_checklist and
     'docs/04-export-qa-checklist.md' in manual_beta_checklist,
     'tool/manual_beta_checklist.sh should keep the standard manual pass order explicit'),
    ('docs/11-video-fallback-workflow.md' in manual_beta_checklist and
     'docs/fixtures/export-qa-project.json' in manual_beta_checklist,
     'tool/manual_beta_checklist.sh should keep the video workflow doc and export QA fixture in the handoff'),
    ('?sceneId=...' in manual_beta_checklist and 'flutter run -d web-server' in manual_beta_checklist,
     'tool/manual_beta_checklist.sh should keep the browser run target and stale-link spot-check guidance explicit'),
    ('smoke_print_manual_beta_handoff_hint' in smoke_common and
     './tool/manual_beta_checklist.sh' in smoke_common,
     'tool/smoke_common.sh should define the shared manual beta handoff helper'),
    ('smoke_print_manual_beta_handoff_hint' in import_smoke,
     'tool/import_smoke.sh should use the shared manual beta handoff helper'),
    ('smoke_print_manual_beta_handoff_hint' in release_smoke,
     'tool/release_smoke.sh should use the shared manual beta handoff helper'),
    ('smoke_print_manual_beta_handoff_hint' in compact_smoke,
     'tool/compact_smoke.sh should use the shared manual beta handoff helper'),
    ('smoke_print_manual_beta_handoff_hint' in navigation_smoke,
     'tool/navigation_smoke.sh should use the shared manual beta handoff helper'),
    ('./tool/manual_beta_checklist.sh' in demo_smoke,
     'tool/demo_smoke.sh should mention the shared manual beta checklist helper explicitly'),
    ('[desktop-smoke] compose config' in pathlib.Path(tool_dir / 'desktop_smoke.sh').read_text(encoding='utf-8') and
     '[desktop-smoke] build + boot' in pathlib.Path(tool_dir / 'desktop_smoke.sh').read_text(encoding='utf-8') and
     '[desktop-smoke] wait for noVNC:' in pathlib.Path(tool_dir / 'desktop_smoke.sh').read_text(encoding='utf-8') and
     '[desktop-smoke] noVNC responded on attempt' in pathlib.Path(tool_dir / 'desktop_smoke.sh').read_text(encoding='utf-8') and
     '[desktop-smoke] noVNC did not become ready in time' in pathlib.Path(tool_dir / 'desktop_smoke.sh').read_text(encoding='utf-8') and
     'logs --tail=80 "$SERVICE_NAME"' in pathlib.Path(tool_dir / 'desktop_smoke.sh').read_text(encoding='utf-8'),
     'tool/desktop_smoke.sh should keep its compose/noVNC progress labels and failure diagnostics'),
    ('docker compose -f docker-compose.desktop.yml up --build' in pathlib.Path(tool_dir / 'desktop_docker.sh').read_text(encoding='utf-8'),
     'tool/desktop_docker.sh should stay pinned to docker-compose.desktop.yml up --build'),
    ('./tool/ai_helper.sh doctor' in ai_helper and 'run_helper_doctor' in ai_helper,
     'tool/ai_helper.sh should keep the doctor mode wired and documented'),
    ('./tool/ai_helper.sh review -- tool/ai_helper.sh docs/10-ai-helper-workflow.md' in ai_helper,
     'tool/ai_helper.sh usage should keep the path-filter review example documented'),
    ('./tool/ai_helper.sh review HEAD~1..HEAD -- tool/ai_helper.sh' in ai_helper,
     'tool/ai_helper.sh usage should keep the combined diff-range plus path-filter example documented'),
    ('./tool/ai_helper.sh preview-ask "Summarize the main playback export risks."' in ai_helper and
     'preview-ask stays fully local and never invokes Gemini.' in ai_helper and
     './tool/ai_helper.sh preview-review -- tool/ai_helper.sh' in ai_helper and
     'preview-review stays fully local and never invokes Gemini.' in ai_helper,
     'tool/ai_helper.sh should keep the preview-ask and preview-review modes documented'),
    ('staged path-filter review reaches the Gemini invocation path' in ai_helper_smoke and
     'preview-ask prints the local analysis payload without Gemini' in ai_helper_smoke and
     'ask with a real question reaches the Gemini invocation path' in ai_helper_smoke and
     'preview-ask and ask reject missing questions clearly' in ai_helper_smoke and
     'preview-review prints the local review payload without Gemini' in ai_helper_smoke and
     'explicit untracked path filters stay reviewable even with staged changes' in ai_helper_smoke and
     'range-plus-path review reaches the Gemini invocation path' in ai_helper_smoke,
     'tool/ai_helper_smoke.sh should keep covering ask/preview-ask, missing-question validation, preview-review, staged path-filter, untracked path-filter, and range-plus-path review behavior'),
    (re.search(r'case "\$mode" in\s+doctor\)', ai_helper, re.S) is not None and
     re.search(r'case "\$mode" in.*preview-ask\)', ai_helper, re.S) is not None and
     re.search(r'case "\$mode" in.*preview-review\)', ai_helper, re.S) is not None,
     'tool/ai_helper.sh should dispatch the doctor, preview-ask, and preview-review modes explicitly'),
    ('run: ./tool/beta_handoff.sh' in workflow,
     'GitHub Actions should keep invoking ./tool/beta_handoff.sh'),
    ('docs_handoff_smoke:' in workflow and 'run: ./tool/docs_handoff_smoke.sh' in workflow,
     'GitHub Actions should keep invoking ./tool/docs_handoff_smoke.sh in the docs_handoff_smoke job'),
    ('helper_smoke:' in workflow and 'run: ./tool/ai_helper_smoke.sh' in workflow,
     'GitHub Actions should keep invoking ./tool/ai_helper_smoke.sh in the helper_smoke job'),
    ('beta_handoff_smoke:' in workflow and 'run: ./tool/beta_handoff_smoke.sh' in workflow,
     'GitHub Actions should keep invoking ./tool/beta_handoff_smoke.sh in the beta_handoff_smoke job'),
    (re.search(r'beta_handoff:\s*\n(?:.*\n)*?\s+needs:\s*\n\s+- docs_handoff_smoke\n\s+- helper_smoke\n\s+- beta_handoff_smoke', workflow) is not None,
     'GitHub Actions beta_handoff job should explicitly depend on docs_handoff_smoke, helper_smoke, and beta_handoff_smoke so CI ordering matches the documented handoff flow'),
    ('desktop_smoke:' in workflow and 'run: ./tool/desktop_smoke.sh' in workflow,
     'GitHub Actions should keep invoking ./tool/desktop_smoke.sh in the desktop_smoke job'),
    ('docs/11-video-fallback-workflow.md' in release_smoke,
     'tool/release_smoke.sh manual follow-up should mention docs/11-video-fallback-workflow.md'),
    ('export QA avatar preview coverage drifted' in release_smoke and
     'focus preview auto-follow coverage drifted' in release_smoke and
     'focus preview chrome coverage drifted' in release_smoke and
     'focus preview short-height coverage drifted' in release_smoke and
     'mobile compact polish coverage drifted' in release_smoke and
     'playback empty-state coverage drifted' in release_smoke and
     'playback export feedback coverage drifted' in release_smoke and
     'portfolio pre-flight coverage drifted' in release_smoke and
     'recovery coverage drifted' in release_smoke and
     'scene status badge coverage drifted' in release_smoke and
     'scene route sync coverage drifted' in release_smoke and
     'short-height entry-state coverage drifted' in release_smoke and
     'timeline QA marker coverage drifted' in release_smoke,
     'tool/release_smoke.sh should keep the focused coverage-drift guards for dedicated test files'),
    ('test/unit/core/utils/export_file_name_test.dart' in release_smoke and
     'test/unit/features/playback/data/services/screenshot_export_service_test.dart' in release_smoke and
     'test/unit/features/playback/data/services/video_export_fallback_service_test.dart' in release_smoke and
     'test/unit/features/playback/domain/playback_timeline_test.dart' in release_smoke and
     'test/unit/features/projects/data/services/project_package_export_service_test.dart' in release_smoke and
     'test/unit/features/projects/data/services/project_portfolio_export_service_test.dart' in release_smoke and
     'test/unit/features/projects/domain/export_qa_fixture_test.dart' in release_smoke and
     'export filename coverage drifted' in release_smoke and
     'screenshot export service coverage drifted' in release_smoke and
     'video export fallback coverage drifted' in release_smoke and
     'playback timeline coverage drifted' in release_smoke and
     'project package export coverage drifted' in release_smoke and
     'project portfolio export coverage drifted' in release_smoke and
     'export QA fixture coverage drifted' in release_smoke and
     '[release-smoke] unit tests:' in release_smoke and
     '"$FLUTTER_BIN" test "${UNIT_TEST_FILES[@]}"' in release_smoke,
     'tool/release_smoke.sh should keep the dedicated export-payload and filename unit-test batch wired with explicit coverage-drift guards'),
    ('mobile compact polish coverage drifted' in compact_smoke and
     'playback empty-state coverage drifted' in compact_smoke and
     'recovery coverage drifted' in compact_smoke and
     'focus preview auto-follow coverage drifted' in compact_smoke and
     'focus preview short-height coverage drifted' in compact_smoke and
     '"$SCENE_STATUS_BADGE_TEST_FILE"' in compact_smoke and
     '"$FOCUS_PREVIEW_CHROME_TEST_FILE"' in compact_smoke and
     '${SCENE_STATUS_BADGE_TEST_PATTERN}' in compact_smoke and
     '${FOCUS_PREVIEW_CHROME_TEST_PATTERN}' in compact_smoke and
     'short-height entry-state coverage drifted' in compact_smoke,
     'tool/compact_smoke.sh should keep the focused coverage-drift guards for dedicated test files and keep scene-status/focus-preview-chrome support files wired into the batched compact run'),
    ('?sceneId=' in web_smoke and 'Ručno makni `?sceneId=...` iz URL-a dok si u editoru' in web_smoke and 'Ručno makni `?sceneId=...` iz playback URL-a' in web_smoke,
     'docs/08-web-smoke-checklist.md should spell out cleared scene-query spot-checks for editor and playback'),
    ('?sceneId=' in compact_smoke_doc and 'ručno makni query' in compact_smoke_doc and 'compact playback vrati aktivnu scenu' in compact_smoke_doc,
     'docs/09-compact-smoke-checklist.md should spell out compact cleared scene-query spot-checks'),
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
    ('forbidden messaging-brand copy' in brand_smoke,
     'tool/brand_neutrality_smoke.sh should report the forbidden messaging-brand copy check clearly'),
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


def assert_catalog_includes(
    *,
    script_label: str,
    array_name: str,
    script_text: str,
    required_names: list[str],
) -> None:
    names = extract_declared_names(script_text, array_name)
    missing = [name for name in required_names if name not in names]
    if missing:
        missing_lines = '\n'.join(f'  - {name}' for name in missing)
        raise SystemExit(
            f'[docs-handoff-smoke] {script_label} is missing expected {array_name} coverage:\n'
            f'{missing_lines}'
        )


assert_names_exist(
    script_label='tool/demo_smoke.sh',
    array_name='TEST_NAMES',
    script_text=demo_smoke,
    target_label='test/widget_test.dart + test/widget/playback_export_feedback_test.dart',
    target_text=widget_test + '\n' + playback_export_feedback_test,
)
assert_names_exist(
    script_label='tool/release_smoke.sh',
    array_name='WIDGET_TEST_NAMES',
    script_text=release_smoke,
    target_label='test/widget_test.dart',
    target_text=widget_test,
)
assert_names_exist(
    script_label='tool/release_smoke.sh',
    array_name='PLAYBACK_EXPORT_FEEDBACK_TEST_NAMES',
    script_text=release_smoke,
    target_label='test/widget/playback_export_feedback_test.dart',
    target_text=playback_export_feedback_test,
)
assert_names_exist(
    script_label='tool/release_smoke.sh',
    array_name='RECOVERY_TEST_NAMES',
    script_text=release_smoke,
    target_label='test/widget/project_not_found_recovery_test.dart',
    target_text=recovery_test,
)
assert_names_exist(
    script_label='tool/release_smoke.sh',
    array_name='SCENE_ROUTE_SYNC_TEST_NAMES',
    script_text=release_smoke,
    target_label='test/widget/scene_route_sync_test.dart',
    target_text=scene_route_sync_test,
)
assert_catalog_includes(
    script_label='tool/release_smoke.sh',
    array_name='WIDGET_TEST_NAMES',
    script_text=release_smoke,
    required_names=[
        'focus preview escape shortcut closes the overlay',
        'focus preview long press exits cleanly',
        'playback preview re-follows earlier cues after backward scrub',
    ],
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
assert_catalog_includes(
    script_label='tool/compact_smoke.sh',
    array_name='TEST_NAMES',
    script_text=compact_smoke,
    required_names=[
        'compact project delete confirmation stays usable on narrow screens',
        'compact project delete confirmation keeps long project names readable on narrow screens',
        'compact editor and playback headers clamp long project names without exceptions',
        'focus preview long press exits cleanly',
        'compact demo flow stays usable across project list, editor, and playback',
    ],
)
assert_names_exist(
    script_label='tool/navigation_smoke.sh',
    array_name='WIDGET_TEST_NAMES',
    script_text=navigation_smoke,
    target_label='test/widget_test.dart',
    target_text=widget_test,
)
assert_names_exist(
    script_label='tool/navigation_smoke.sh',
    array_name='SCENE_ROUTE_SYNC_TEST_NAMES',
    script_text=navigation_smoke,
    target_label='test/widget/scene_route_sync_test.dart',
    target_text=scene_route_sync_test,
)
assert_names_exist(
    script_label='tool/navigation_smoke.sh',
    array_name='RECOVERY_TEST_NAMES',
    script_text=navigation_smoke,
    target_label='test/widget/project_not_found_recovery_test.dart',
    target_text=recovery_test,
)
assert_catalog_includes(
    script_label='tool/navigation_smoke.sh',
    array_name='SCENE_ROUTE_SYNC_TEST_NAMES',
    script_text=navigation_smoke,
    required_names=[
        'chat editor restores selected scene query when external route clears it',
        'playback restores selected scene query when external route clears it',
    ],
)
assert_names_exist(
    script_label='tool/import_smoke.sh',
    array_name='WIDGET_TEST_NAMES',
    script_text=import_smoke,
    target_label='test/widget_test.dart',
    target_text=widget_test,
)
assert_catalog_includes(
    script_label='tool/import_smoke.sh',
    array_name='WIDGET_TEST_NAMES',
    script_text=import_smoke,
    required_names=[
        'import project json preview lists projected projects and skipped invalid entries',
        'import project json preview cancel keeps projects unchanged',
        'compact import project dialog stays usable on narrow screens',
    ],
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
print('[docs-handoff-smoke] navigation smoke documentation/workflow checks are in sync')
print('[docs-handoff-smoke] navigation smoke keeps cleared-query route-restore regressions gated')
print('[docs-handoff-smoke] video fallback handoff docs stay linked to the manual release gates')
print('[docs-handoff-smoke] brand-neutrality release-gate documentation/workflow checks are in sync')
print('[docs-handoff-smoke] smoke script test-name catalogs are in sync')
print('[docs-handoff-smoke] compact smoke keeps the critical narrow-screen name/dialog regressions gated')
PY

manual_beta_output="$("$MANUAL_BETA_CHECKLIST_PATH")"

for expected_line in \
  "[manual-beta-checklist] automated baseline" \
  "- Start from a green ./tool/beta_handoff.sh run." \
  "- Keep docs/11-video-fallback-workflow.md open while validating Export Video behavior." \
  "- Use docs/fixtures/export-qa-project.json as the standard import/export QA sample." \
  "[manual-beta-checklist] manual pass order" \
  "1) docs/08-web-smoke-checklist.md" \
  "2) docs/09-compact-smoke-checklist.md" \
  "3) docs/04-export-qa-checklist.md" \
  "[manual-beta-checklist] run target" \
  "- Use a local browser session from /home/server/flutter/bin/flutter run -d web-server" \
  "- Repeat the compact pass around ~390px width and the ultra-compact checks around ~320px width" \
  "- For stale-link spot checks, manually clear ?sceneId=... in editor/playback URLs and confirm the app restores a valid scene" \
  "[manual-beta-checklist] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$manual_beta_output"; then
    echo "[docs-handoff-smoke] manual beta checklist output drifted: missing line: $expected_line" >&2
    exit 1
  fi
done

if ! [[ -s "$EXPORT_QA_FIXTURE_PATH" ]]; then
  echo "[docs-handoff-smoke] export QA fixture should remain non-empty for manual handoff: $EXPORT_QA_FIXTURE_PATH" >&2
  exit 1
fi

manual_beta_missing_stub_dir="$(mktemp -d)"
mkdir -p "$manual_beta_missing_stub_dir/docs/fixtures" "$manual_beta_missing_stub_dir/tool"
cp "$MANUAL_BETA_CHECKLIST_PATH" "$manual_beta_missing_stub_dir/tool/manual_beta_checklist.sh"
touch "$manual_beta_missing_stub_dir/docs/09-compact-smoke-checklist.md"
touch "$manual_beta_missing_stub_dir/docs/04-export-qa-checklist.md"
touch "$manual_beta_missing_stub_dir/docs/11-video-fallback-workflow.md"
printf '{}' > "$manual_beta_missing_stub_dir/docs/fixtures/export-qa-project.json"
chmod +x "$manual_beta_missing_stub_dir/tool/manual_beta_checklist.sh"

set +e
manual_beta_missing_output="$(
  cd "$manual_beta_missing_stub_dir" &&
  ./tool/manual_beta_checklist.sh 2>&1
)"
manual_beta_missing_status=$?
set -e

if [[ "$manual_beta_missing_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] manual beta checklist missing-file path drifted: expected non-zero status" >&2
  rm -rf "$manual_beta_missing_stub_dir"
  exit 1
fi

if ! grep -Fqx -- '[manual-beta-checklist] missing required handoff file: docs/08-web-smoke-checklist.md' <<<"$manual_beta_missing_output"; then
  echo "[docs-handoff-smoke] manual beta checklist missing-file output drifted" >&2
  rm -rf "$manual_beta_missing_stub_dir"
  exit 1
fi

rm -rf "$manual_beta_missing_stub_dir"

manual_beta_empty_fixture_stub_dir="$(mktemp -d)"
mkdir -p "$manual_beta_empty_fixture_stub_dir/docs/fixtures" "$manual_beta_empty_fixture_stub_dir/tool"
cp "$MANUAL_BETA_CHECKLIST_PATH" "$manual_beta_empty_fixture_stub_dir/tool/manual_beta_checklist.sh"
touch "$manual_beta_empty_fixture_stub_dir/docs/08-web-smoke-checklist.md"
touch "$manual_beta_empty_fixture_stub_dir/docs/09-compact-smoke-checklist.md"
touch "$manual_beta_empty_fixture_stub_dir/docs/04-export-qa-checklist.md"
touch "$manual_beta_empty_fixture_stub_dir/docs/11-video-fallback-workflow.md"
: > "$manual_beta_empty_fixture_stub_dir/docs/fixtures/export-qa-project.json"
chmod +x "$manual_beta_empty_fixture_stub_dir/tool/manual_beta_checklist.sh"

set +e
manual_beta_empty_fixture_output="$(
  cd "$manual_beta_empty_fixture_stub_dir" &&
  ./tool/manual_beta_checklist.sh 2>&1
)"
manual_beta_empty_fixture_status=$?
set -e

if [[ "$manual_beta_empty_fixture_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] manual beta checklist empty-fixture path drifted: expected non-zero status" >&2
  rm -rf "$manual_beta_empty_fixture_stub_dir"
  exit 1
fi

if ! grep -Fqx -- '[manual-beta-checklist] export QA fixture is empty: docs/fixtures/export-qa-project.json' <<<"$manual_beta_empty_fixture_output"; then
  echo "[docs-handoff-smoke] manual beta checklist empty-fixture output drifted" >&2
  rm -rf "$manual_beta_empty_fixture_stub_dir"
  exit 1
fi

rm -rf "$manual_beta_empty_fixture_stub_dir"

ai_helper_smoke_output="$("$AI_HELPER_SMOKE_PATH")"

for expected_line in \
  "[ai-helper-smoke] doctor path detects missing Gemini" \
  "[ai-helper-smoke] staged path-filter review reaches the Gemini invocation path" \
  "[ai-helper-smoke] preview-ask prints the local analysis payload without Gemini" \
  "[ai-helper-smoke] ask with a real question reaches the Gemini invocation path" \
  "[ai-helper-smoke] preview-ask and ask reject missing questions clearly" \
  "[ai-helper-smoke] preview-review prints the local review payload without Gemini" \
  "[ai-helper-smoke] explicit untracked path filters stay reviewable even with staged changes" \
  "[ai-helper-smoke] range-plus-path review reaches the Gemini invocation path" \
  "[ai-helper-smoke] missing-path review still fails fast with a clear no-diff signal" \
  "[ai-helper-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$ai_helper_smoke_output"; then
    echo "[docs-handoff-smoke] ai helper smoke output drifted: missing line: $expected_line" >&2
    exit 1
  fi
done

doctor_output="$("$AI_HELPER_PATH" doctor 2>&1 || true)"

for expected_line in \
  "===== GEMINI CLI DOCTOR =====" \
  "[ai-helper] repo: $ROOT_DIR" \
  "[ai-helper] missing: gemini" \
  "[ai-helper] doctor verdict: needs attention"; do
  if ! grep -Fqx -- "$expected_line" <<<"$doctor_output"; then
    echo "[docs-handoff-smoke] ai helper doctor output drifted: missing line: $expected_line" >&2
    exit 1
  fi
done

preview_ask_output="$("$AI_HELPER_PATH" preview-ask "Summarize helper fallback risks.")"

for expected_line in \
  "Repository root:" \
  "$ROOT_DIR" \
  "Task:" \
  "Summarize helper fallback risks."; do
  if ! grep -Fqx -- "$expected_line" <<<"$preview_ask_output"; then
    echo "[docs-handoff-smoke] ai helper preview-ask output drifted: missing line: $expected_line" >&2
    exit 1
  fi
done

desktop_docker_stub_dir="$(mktemp -d)"
cat > "$desktop_docker_stub_dir/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'docker|args=%s\n' "$*"
EOF
chmod +x "$desktop_docker_stub_dir/docker"

desktop_docker_output="$(
  cd "$ROOT_DIR" &&
  PATH="$desktop_docker_stub_dir:$PATH" "$ROOT_DIR/tool/desktop_docker.sh"
)"

if ! grep -Fqx -- 'docker|args=compose -f docker-compose.desktop.yml up --build' <<<"$desktop_docker_output"; then
  echo "[docs-handoff-smoke] desktop docker output drifted: missing the expected docker compose invocation" >&2
  rm -rf "$desktop_docker_stub_dir"
  exit 1
fi

rm -rf "$desktop_docker_stub_dir"

desktop_smoke_stub_dir="$(mktemp -d)"
cat > "$desktop_smoke_stub_dir/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ge 7 && "$1" == "compose" && "$2" == "-f" && "$4" == "ps" && "$5" == "--services" && "$6" == "--status" && "$7" == "running" ]]; then
  printf 'desktop\n'
  exit 0
fi

if [[ "$#" -ge 6 && "$1" == "compose" && "$2" == "-f" && "$4" == "logs" && "$5" == "--tail=20" ]]; then
  printf 'desktop-log|service=%s\n' "${6:-unknown}"
  exit 0
fi

exit 0
EOF
chmod +x "$desktop_smoke_stub_dir/docker"

cat > "$desktop_smoke_stub_dir/python3" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF
chmod +x "$desktop_smoke_stub_dir/python3"

desktop_smoke_output="$(
  cd "$ROOT_DIR" &&
  PATH="$desktop_smoke_stub_dir:$PATH" \
    DESKTOP_SMOKE_MAX_ATTEMPTS=20 \
    DESKTOP_SMOKE_SLEEP_SECONDS=0 \
    "$ROOT_DIR/tool/desktop_smoke.sh"
)"

for expected_line in \
  "[desktop-smoke] compose config" \
  "[desktop-smoke] build + boot" \
  "[desktop-smoke] wait for noVNC: http://localhost:6080/vnc.html?host=localhost&port=6080&autoconnect=true&resize=remote" \
  "[desktop-smoke] noVNC responded on attempt 1/20" \
  "desktop-log|service=desktop" \
  "[desktop-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$desktop_smoke_output"; then
    echo "[docs-handoff-smoke] desktop smoke output drifted: missing line: $expected_line" >&2
    rm -rf "$desktop_smoke_stub_dir"
    exit 1
  fi
done

rm -rf "$desktop_smoke_stub_dir"

desktop_smoke_failure_stub_dir="$(mktemp -d)"
cat > "$desktop_smoke_failure_stub_dir/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ge 4 && "$1" == "compose" && "$2" == "-f" && "$4" == "ps" ]]; then
  printf 'desktop-ps|args=%s\n' "$*"
  exit 0
fi

if [[ "$#" -ge 4 && "$1" == "compose" && "$2" == "-f" && "$4" == "logs" ]]; then
  printf 'desktop-logs|args=%s\n' "$*"
  exit 0
fi

exit 0
EOF
chmod +x "$desktop_smoke_failure_stub_dir/docker"

cat > "$desktop_smoke_failure_stub_dir/python3" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 1
EOF
chmod +x "$desktop_smoke_failure_stub_dir/python3"

set +e
desktop_smoke_failure_output="$(
  cd "$ROOT_DIR" &&
  PATH="$desktop_smoke_failure_stub_dir:$PATH" \
    DESKTOP_SMOKE_MAX_ATTEMPTS=2 \
    DESKTOP_SMOKE_SLEEP_SECONDS=0 \
    "$ROOT_DIR/tool/desktop_smoke.sh" 2>&1
)"
desktop_smoke_failure_status=$?
set -e

if [[ "$desktop_smoke_failure_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] desktop smoke failure-path drifted: expected non-zero status when noVNC never responds" >&2
  rm -rf "$desktop_smoke_failure_stub_dir"
  exit 1
fi

for expected_line in \
  "[desktop-smoke] compose config" \
  "[desktop-smoke] build + boot" \
  "[desktop-smoke] wait for noVNC: http://localhost:6080/vnc.html?host=localhost&port=6080&autoconnect=true&resize=remote" \
  "[desktop-smoke] noVNC did not become ready in time" \
  "desktop-ps|args=compose -f docker-compose.desktop.yml ps" \
  "desktop-logs|args=compose -f docker-compose.desktop.yml logs --tail=80 desktop"; do
  if ! grep -Fqx -- "$expected_line" <<<"$desktop_smoke_failure_output"; then
    echo "[docs-handoff-smoke] desktop smoke failure-path output drifted: missing line: $expected_line" >&2
    rm -rf "$desktop_smoke_failure_stub_dir"
    exit 1
  fi
done

rm -rf "$desktop_smoke_failure_stub_dir"

verify_stub_dir="$(mktemp -d)"
trap 'rm -rf "$verify_stub_dir"' EXIT

mkdir -p "$verify_stub_dir/tool"
cp "$VERIFY_PATH" "$verify_stub_dir/tool/verify.sh"
cp "$SMOKE_COMMON_PATH" "$verify_stub_dir/tool/smoke_common.sh"
chmod +x "$verify_stub_dir/tool/verify.sh" "$verify_stub_dir/tool/smoke_common.sh"

cat > "$verify_stub_dir/tool/web_shell_smoke.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'web-shell-smoke|args=%s\n' "$*"
EOF
chmod +x "$verify_stub_dir/tool/web_shell_smoke.sh"

cat > "$verify_stub_dir/tool/brand_neutrality_smoke.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'brand-neutrality-smoke|args=%s\n' "$*"
EOF
chmod +x "$verify_stub_dir/tool/brand_neutrality_smoke.sh"

cat > "$verify_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$verify_stub_dir/flutter-stub.sh"

verify_output="$(
  cd "$verify_stub_dir" &&
  SKIP_PUB_GET=1 SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$verify_stub_dir/flutter-stub.sh" ./tool/verify.sh
)"

for expected_line in \
  "[verify] using flutter: $verify_stub_dir/flutter-stub.sh (version handled upstream)" \
  "[verify] pub get skipped (already resolved upstream)" \
  "[verify] analyze skipped (handled upstream)" \
  "[verify] source web shell metadata" \
  "web-shell-smoke|args=web" \
  "[verify] source brand-neutrality" \
  "brand-neutrality-smoke|args=lib web" \
  "[verify] test" \
  "flutter|args=test" \
  "[verify] build web" \
  "flutter|args=build web" \
  "[verify] built web shell metadata" \
  "web-shell-smoke|args=build/web" \
  "[verify] built web brand-neutrality" \
  "brand-neutrality-smoke|args=build/web" \
  "[verify] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$verify_output"; then
    echo "[docs-handoff-smoke] verify output drifted: missing line: $expected_line" >&2
    exit 1
  fi
done

verify_missing_script_stub_dir="$(mktemp -d)"
mkdir -p "$verify_missing_script_stub_dir/tool"
cp "$VERIFY_PATH" "$verify_missing_script_stub_dir/tool/verify.sh"
cp "$SMOKE_COMMON_PATH" "$verify_missing_script_stub_dir/tool/smoke_common.sh"
chmod +x "$verify_missing_script_stub_dir/tool/verify.sh" "$verify_missing_script_stub_dir/tool/smoke_common.sh"

cat > "$verify_missing_script_stub_dir/tool/web_shell_smoke.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'web-shell-smoke|args=%s\n' "$*"
EOF
chmod +x "$verify_missing_script_stub_dir/tool/web_shell_smoke.sh"

cat > "$verify_missing_script_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$verify_missing_script_stub_dir/flutter-stub.sh"

set +e
verify_missing_script_output="$(
  cd "$verify_missing_script_stub_dir" &&
  SKIP_PUB_GET=1 SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$verify_missing_script_stub_dir/flutter-stub.sh" ./tool/verify.sh 2>&1
)"
verify_missing_script_status=$?
set -e

if [[ "$verify_missing_script_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] verify missing-script path drifted: expected non-zero status" >&2
  rm -rf "$verify_missing_script_stub_dir"
  exit 1
fi

if ! grep -Fqx -- "[verify] missing required script: $verify_missing_script_stub_dir/tool/brand_neutrality_smoke.sh" <<<"$verify_missing_script_output"; then
  echo "[docs-handoff-smoke] verify missing-script output drifted" >&2
  rm -rf "$verify_missing_script_stub_dir"
  exit 1
fi

rm -rf "$verify_missing_script_stub_dir"

compact_stub_dir="$(mktemp -d)"
cat > "$compact_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$compact_stub_dir/flutter-stub.sh"

compact_smoke_output="$(
  cd "$ROOT_DIR" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$compact_stub_dir/flutter-stub.sh" "$COMPACT_SMOKE_PATH"
)"

for expected_line in \
  "[compact-smoke] using flutter: $compact_stub_dir/flutter-stub.sh (version handled upstream)" \
  "[compact-smoke] analyze skipped (handled upstream)" \
  "[compact-smoke] tests: 40 compact/export + 4 mobile polish + 3 playback empty-state + 2 scene-status + 2 focus-preview auto-follow + 5 recovery/layout + 2 focus-preview chrome + 1 focus-preview short-height + 4 short-height entry/recovery cases (batched)" \
  "- If this targeted pass is green, run ./tool/verify.sh before release or deploy decisions." \
  "[compact-smoke] manual follow-up" \
  "- Then run ./tool/manual_beta_checklist.sh for the shared browser/compact/export handoff order." \
  "- This compact pass now also covers dialog safe-area/keyboard behavior, larger-text compact breakpoints on project/editor/playback surfaces, short-landscape compact app-bar flows, ultra-compact editor/playback footer stacking, deep long-scene focus-preview auto-follow, focus-preview chrome stacking at larger text, short-height focus-preview chrome, short-height empty/recovery entry shells, compact scene-selector ergonomics, empty playback recovery actions, and the compact empty-scene status badge." \
  "[compact-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$compact_smoke_output"; then
    echo "[docs-handoff-smoke] compact smoke output drifted: missing line: $expected_line" >&2
    rm -rf "$compact_stub_dir"
    exit 1
  fi
done

if ! grep -Fq -- 'flutter|args=test test/widget_test.dart test/widget/project_not_found_recovery_test.dart test/widget/mobile_compact_polish_test.dart test/widget/playback_empty_state_actions_test.dart test/widget/scene_status_badge_test.dart test/widget/focus_preview_autofollow_test.dart test/widget/focus_preview_chrome_test.dart test/widget/focus_preview_short_height_test.dart test/widget/short_height_entry_states_test.dart' <<<"$compact_smoke_output"; then
  echo "[docs-handoff-smoke] compact smoke output drifted: missing the expected batched flutter test invocation" >&2
  rm -rf "$compact_stub_dir"
  exit 1
fi

rm -rf "$compact_stub_dir"

compact_missing_file_stub_dir="$(mktemp -d)"
mkdir -p "$compact_missing_file_stub_dir/tool" "$compact_missing_file_stub_dir/test/widget"
cp "$COMPACT_SMOKE_PATH" "$compact_missing_file_stub_dir/tool/compact_smoke.sh"
cp "$SMOKE_COMMON_PATH" "$compact_missing_file_stub_dir/tool/smoke_common.sh"
touch "$compact_missing_file_stub_dir/test/widget/project_not_found_recovery_test.dart"
touch "$compact_missing_file_stub_dir/test/widget/mobile_compact_polish_test.dart"
touch "$compact_missing_file_stub_dir/test/widget/playback_empty_state_actions_test.dart"
touch "$compact_missing_file_stub_dir/test/widget/scene_status_badge_test.dart"
touch "$compact_missing_file_stub_dir/test/widget/focus_preview_autofollow_test.dart"
touch "$compact_missing_file_stub_dir/test/widget/focus_preview_chrome_test.dart"
touch "$compact_missing_file_stub_dir/test/widget/focus_preview_short_height_test.dart"
touch "$compact_missing_file_stub_dir/test/widget/short_height_entry_states_test.dart"
chmod +x "$compact_missing_file_stub_dir/tool/compact_smoke.sh" "$compact_missing_file_stub_dir/tool/smoke_common.sh"

cat > "$compact_missing_file_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$compact_missing_file_stub_dir/flutter-stub.sh"

set +e
compact_missing_file_output="$(
  cd "$compact_missing_file_stub_dir" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$compact_missing_file_stub_dir/flutter-stub.sh" ./tool/compact_smoke.sh 2>&1
)"
compact_missing_file_status=$?
set -e

if [[ "$compact_missing_file_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] compact smoke missing-file path drifted: expected non-zero status" >&2
  rm -rf "$compact_missing_file_stub_dir"
  exit 1
fi

if ! grep -Fqx -- '[compact-smoke] missing expected test file: test/widget_test.dart' <<<"$compact_missing_file_output"; then
  echo "[docs-handoff-smoke] compact smoke missing-file output drifted" >&2
  rm -rf "$compact_missing_file_stub_dir"
  exit 1
fi

rm -rf "$compact_missing_file_stub_dir"

import_stub_dir="$(mktemp -d)"
cat > "$import_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$import_stub_dir/flutter-stub.sh"

import_smoke_output="$(
  cd "$ROOT_DIR" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$import_stub_dir/flutter-stub.sh" "$IMPORT_SMOKE_PATH"
)"

for expected_line in \
  "[import-smoke] using flutter: $import_stub_dir/flutter-stub.sh (version handled upstream)" \
  "[import-smoke] analyze skipped (handled upstream)" \
  "[import-smoke] tests: 23 targeted import/widget/sanitizer/repository/fixture cases (batched)" \
  "- Run ./tool/beta_handoff.sh for the full preflight sequence when you want the release-ready gate stack." \
  "[import-smoke] manual follow-up" \
  "- Then run ./tool/manual_beta_checklist.sh for the shared browser/compact/export handoff order." \
  "- Keep one real browser import pass during that manual handoff for clipboard/file-picker behavior." \
  "[import-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$import_smoke_output"; then
    echo "[docs-handoff-smoke] import smoke output drifted: missing line: $expected_line" >&2
    rm -rf "$import_stub_dir"
    exit 1
  fi
done

if ! grep -Fq -- 'flutter|args=test test/widget_test.dart test/unit/features/projects/presentation/controllers/projects_controller_test.dart test/unit/features/projects/data/services/project_sanitizer_test.dart test/unit/features/projects/data/repositories/local_project_repository_test.dart test/unit/features/projects/domain/export_qa_fixture_test.dart' <<<"$import_smoke_output"; then
  echo "[docs-handoff-smoke] import smoke output drifted: missing the expected batched flutter test invocation" >&2
  rm -rf "$import_stub_dir"
  exit 1
fi

rm -rf "$import_stub_dir"

import_missing_file_stub_dir="$(mktemp -d)"
mkdir -p "$import_missing_file_stub_dir/tool" \
  "$import_missing_file_stub_dir/test/unit/features/projects/presentation/controllers" \
  "$import_missing_file_stub_dir/test/unit/features/projects/data/services" \
  "$import_missing_file_stub_dir/test/unit/features/projects/data/repositories" \
  "$import_missing_file_stub_dir/test/unit/features/projects/domain"
cp "$IMPORT_SMOKE_PATH" "$import_missing_file_stub_dir/tool/import_smoke.sh"
cp "$SMOKE_COMMON_PATH" "$import_missing_file_stub_dir/tool/smoke_common.sh"
touch "$import_missing_file_stub_dir/test/unit/features/projects/presentation/controllers/projects_controller_test.dart"
touch "$import_missing_file_stub_dir/test/unit/features/projects/data/services/project_sanitizer_test.dart"
touch "$import_missing_file_stub_dir/test/unit/features/projects/data/repositories/local_project_repository_test.dart"
touch "$import_missing_file_stub_dir/test/unit/features/projects/domain/export_qa_fixture_test.dart"
chmod +x "$import_missing_file_stub_dir/tool/import_smoke.sh" "$import_missing_file_stub_dir/tool/smoke_common.sh"

cat > "$import_missing_file_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$import_missing_file_stub_dir/flutter-stub.sh"

set +e
import_missing_file_output="$(
  cd "$import_missing_file_stub_dir" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$import_missing_file_stub_dir/flutter-stub.sh" ./tool/import_smoke.sh 2>&1
)"
import_missing_file_status=$?
set -e

if [[ "$import_missing_file_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] import smoke missing-file path drifted: expected non-zero status" >&2
  rm -rf "$import_missing_file_stub_dir"
  exit 1
fi

if ! grep -Fqx -- '[import-smoke] missing expected test file: test/widget_test.dart' <<<"$import_missing_file_output"; then
  echo "[docs-handoff-smoke] import smoke missing-file output drifted" >&2
  rm -rf "$import_missing_file_stub_dir"
  exit 1
fi

rm -rf "$import_missing_file_stub_dir"

navigation_stub_dir="$(mktemp -d)"
cat > "$navigation_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$navigation_stub_dir/flutter-stub.sh"

navigation_smoke_output="$(
  cd "$ROOT_DIR" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$navigation_stub_dir/flutter-stub.sh" "$NAVIGATION_SMOKE_PATH"
)"

for expected_line in \
  "[navigation-smoke] using flutter: $navigation_stub_dir/flutter-stub.sh (version handled upstream)" \
  "[navigation-smoke] analyze skipped (handled upstream)" \
  "[navigation-smoke] tests: 9 navigation widget + 8 route-sync + 3 recovery cases (batched)" \
  "[navigation-smoke] manual follow-up" \
  "- Then run ./tool/manual_beta_checklist.sh for the shared browser/compact/export handoff order." \
  "- If this targeted pass is green, keep browser back/forward, deep-link, and cleared-query spot-checks in that helper and its linked docs." \
  "- Then run ./tool/verify.sh before release or deploy decisions." \
  "[navigation-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$navigation_smoke_output"; then
    echo "[docs-handoff-smoke] navigation smoke output drifted: missing line: $expected_line" >&2
    rm -rf "$navigation_stub_dir"
    exit 1
  fi
done

if ! grep -Fq -- 'flutter|args=test test/widget_test.dart test/widget/scene_route_sync_test.dart test/widget/project_not_found_recovery_test.dart' <<<"$navigation_smoke_output"; then
  echo "[docs-handoff-smoke] navigation smoke output drifted: missing the expected batched flutter test invocation" >&2
  rm -rf "$navigation_stub_dir"
  exit 1
fi

rm -rf "$navigation_stub_dir"

navigation_missing_file_stub_dir="$(mktemp -d)"
mkdir -p "$navigation_missing_file_stub_dir/tool" "$navigation_missing_file_stub_dir/test/widget"
cp "$NAVIGATION_SMOKE_PATH" "$navigation_missing_file_stub_dir/tool/navigation_smoke.sh"
cp "$SMOKE_COMMON_PATH" "$navigation_missing_file_stub_dir/tool/smoke_common.sh"
touch "$navigation_missing_file_stub_dir/test/widget/scene_route_sync_test.dart"
touch "$navigation_missing_file_stub_dir/test/widget/project_not_found_recovery_test.dart"
chmod +x "$navigation_missing_file_stub_dir/tool/navigation_smoke.sh" "$navigation_missing_file_stub_dir/tool/smoke_common.sh"

cat > "$navigation_missing_file_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$navigation_missing_file_stub_dir/flutter-stub.sh"

set +e
navigation_missing_file_output="$(
  cd "$navigation_missing_file_stub_dir" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$navigation_missing_file_stub_dir/flutter-stub.sh" ./tool/navigation_smoke.sh 2>&1
)"
navigation_missing_file_status=$?
set -e

if [[ "$navigation_missing_file_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] navigation smoke missing-file path drifted: expected non-zero status" >&2
  rm -rf "$navigation_missing_file_stub_dir"
  exit 1
fi

if ! grep -Fqx -- '[navigation-smoke] missing expected test file: test/widget_test.dart' <<<"$navigation_missing_file_output"; then
  echo "[docs-handoff-smoke] navigation smoke missing-file output drifted" >&2
  rm -rf "$navigation_missing_file_stub_dir"
  exit 1
fi

rm -rf "$navigation_missing_file_stub_dir"

demo_stub_dir="$(mktemp -d)"
cat > "$demo_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$demo_stub_dir/flutter-stub.sh"

demo_smoke_output="$(
  cd "$ROOT_DIR" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$demo_stub_dir/flutter-stub.sh" "$DEMO_SMOKE_PATH"
)"

for expected_line in \
  "[demo-smoke] using flutter: $demo_stub_dir/flutter-stub.sh (version handled upstream)" \
  "[demo-smoke] analyze skipped (handled upstream)" \
  "[demo-smoke] tests: 21 targeted demo/import/export cases" \
  "[demo-smoke] manual demo checklist" \
  "1) Run app: $demo_stub_dir/flutter-stub.sh run -d web-server" \
  "10) Then use the shared handoff helper: ./tool/manual_beta_checklist.sh" \
  "[demo-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$demo_smoke_output"; then
    echo "[docs-handoff-smoke] demo smoke output drifted: missing line: $expected_line" >&2
    rm -rf "$demo_stub_dir"
    exit 1
  fi
done

if ! grep -Fq -- 'flutter|args=test test/widget_test.dart test/widget/playback_export_feedback_test.dart' <<<"$demo_smoke_output"; then
  echo "[docs-handoff-smoke] demo smoke output drifted: missing the expected batched flutter test invocation" >&2
  rm -rf "$demo_stub_dir"
  exit 1
fi

rm -rf "$demo_stub_dir"

demo_missing_file_stub_dir="$(mktemp -d)"
mkdir -p "$demo_missing_file_stub_dir/tool" "$demo_missing_file_stub_dir/test/widget"
cp "$DEMO_SMOKE_PATH" "$demo_missing_file_stub_dir/tool/demo_smoke.sh"
cp "$SMOKE_COMMON_PATH" "$demo_missing_file_stub_dir/tool/smoke_common.sh"
touch "$demo_missing_file_stub_dir/test/widget/playback_export_feedback_test.dart"
chmod +x "$demo_missing_file_stub_dir/tool/demo_smoke.sh" "$demo_missing_file_stub_dir/tool/smoke_common.sh"

cat > "$demo_missing_file_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$demo_missing_file_stub_dir/flutter-stub.sh"

set +e
demo_missing_file_output="$(
  cd "$demo_missing_file_stub_dir" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$demo_missing_file_stub_dir/flutter-stub.sh" ./tool/demo_smoke.sh 2>&1
)"
demo_missing_file_status=$?
set -e

if [[ "$demo_missing_file_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] demo smoke missing-file path drifted: expected non-zero status" >&2
  rm -rf "$demo_missing_file_stub_dir"
  exit 1
fi

if ! grep -Fqx -- '[demo-smoke] missing expected test file: test/widget_test.dart' <<<"$demo_missing_file_output"; then
  echo "[docs-handoff-smoke] demo smoke missing-file output drifted" >&2
  rm -rf "$demo_missing_file_stub_dir"
  exit 1
fi

rm -rf "$demo_missing_file_stub_dir"

release_stub_dir="$(mktemp -d)"
cat > "$release_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$release_stub_dir/flutter-stub.sh"

release_smoke_output="$(
  cd "$ROOT_DIR" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$release_stub_dir/flutter-stub.sh" "$RELEASE_SMOKE_PATH"
)"

for expected_line in \
  "[release-smoke] using flutter: $release_stub_dir/flutter-stub.sh (version handled upstream)" \
  "[release-smoke] analyze skipped (handled upstream)" \
  "[release-smoke] widget tests: 32 widget + 1 export-QA avatar preview + 2 focus-preview auto-follow + 4 focus-preview chrome + 1 focus-preview short-height + 4 mobile polish + 3 playback empty-state + 7 export feedback + 3 portfolio pre-flight + 5 recovery + 5 scene-status badge + 12 route-sync + 4 short-height entry/recovery + 1 timeline-QA marker cases" \
  "[release-smoke] unit tests: 7 export payload and filename cases (batched)" \
  "- This is a fast preflight, not a replacement for ./tool/verify.sh." \
  "[release-smoke] manual follow-up" \
  "- Then run ./tool/manual_beta_checklist.sh for the shared browser/compact/export handoff order." \
  "- Spot-check the wide-layout Focus Preview transport overlay in a browser so cue/seek/scrub behavior still matches the main preview." \
  "- Keep docs/11-video-fallback-workflow.md with the handoff so downstream render users know Export Video emits a documented .json package." \
  "[release-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$release_smoke_output"; then
    echo "[docs-handoff-smoke] release smoke output drifted: missing line: $expected_line" >&2
    rm -rf "$release_stub_dir"
    exit 1
  fi
done

if ! grep -Fq -- 'flutter|args=test test/widget_test.dart test/widget/export_qa_avatar_preview_test.dart test/widget/focus_preview_autofollow_test.dart test/widget/focus_preview_chrome_test.dart test/widget/focus_preview_short_height_test.dart test/widget/mobile_compact_polish_test.dart test/widget/playback_empty_state_actions_test.dart test/widget/playback_export_feedback_test.dart test/widget/portfolio_preflight_badge_test.dart test/widget/project_not_found_recovery_test.dart test/widget/scene_status_badge_test.dart test/widget/scene_route_sync_test.dart test/widget/short_height_entry_states_test.dart test/widget/timeline_qa_markers_test.dart' <<<"$release_smoke_output"; then
  echo "[docs-handoff-smoke] release smoke output drifted: missing the expected batched widget-test invocation" >&2
  rm -rf "$release_stub_dir"
  exit 1
fi

if ! grep -Fq -- 'flutter|args=test test/unit/core/utils/export_file_name_test.dart test/unit/features/playback/data/services/screenshot_export_service_test.dart test/unit/features/playback/data/services/video_export_fallback_service_test.dart test/unit/features/playback/domain/playback_timeline_test.dart test/unit/features/projects/data/services/project_package_export_service_test.dart test/unit/features/projects/data/services/project_portfolio_export_service_test.dart test/unit/features/projects/domain/export_qa_fixture_test.dart' <<<"$release_smoke_output"; then
  echo "[docs-handoff-smoke] release smoke output drifted: missing the expected batched unit-test invocation" >&2
  rm -rf "$release_stub_dir"
  exit 1
fi

rm -rf "$release_stub_dir"

release_missing_file_stub_dir="$(mktemp -d)"
mkdir -p \
  "$release_missing_file_stub_dir/tool" \
  "$release_missing_file_stub_dir/test/widget" \
  "$release_missing_file_stub_dir/test/unit/core/utils" \
  "$release_missing_file_stub_dir/test/unit/features/playback/data/services" \
  "$release_missing_file_stub_dir/test/unit/features/playback/domain" \
  "$release_missing_file_stub_dir/test/unit/features/projects/data/services" \
  "$release_missing_file_stub_dir/test/unit/features/projects/domain"
cp "$RELEASE_SMOKE_PATH" "$release_missing_file_stub_dir/tool/release_smoke.sh"
cp "$SMOKE_COMMON_PATH" "$release_missing_file_stub_dir/tool/smoke_common.sh"
touch "$release_missing_file_stub_dir/test/widget/export_qa_avatar_preview_test.dart"
touch "$release_missing_file_stub_dir/test/widget/focus_preview_autofollow_test.dart"
touch "$release_missing_file_stub_dir/test/widget/focus_preview_chrome_test.dart"
touch "$release_missing_file_stub_dir/test/widget/focus_preview_short_height_test.dart"
touch "$release_missing_file_stub_dir/test/widget/mobile_compact_polish_test.dart"
touch "$release_missing_file_stub_dir/test/widget/playback_empty_state_actions_test.dart"
touch "$release_missing_file_stub_dir/test/widget/playback_export_feedback_test.dart"
touch "$release_missing_file_stub_dir/test/widget/portfolio_preflight_badge_test.dart"
touch "$release_missing_file_stub_dir/test/widget/project_not_found_recovery_test.dart"
touch "$release_missing_file_stub_dir/test/widget/scene_status_badge_test.dart"
touch "$release_missing_file_stub_dir/test/widget/scene_route_sync_test.dart"
touch "$release_missing_file_stub_dir/test/widget/short_height_entry_states_test.dart"
touch "$release_missing_file_stub_dir/test/widget/timeline_qa_markers_test.dart"
touch "$release_missing_file_stub_dir/test/unit/core/utils/export_file_name_test.dart"
touch "$release_missing_file_stub_dir/test/unit/features/playback/data/services/screenshot_export_service_test.dart"
touch "$release_missing_file_stub_dir/test/unit/features/playback/data/services/video_export_fallback_service_test.dart"
touch "$release_missing_file_stub_dir/test/unit/features/playback/domain/playback_timeline_test.dart"
touch "$release_missing_file_stub_dir/test/unit/features/projects/data/services/project_package_export_service_test.dart"
touch "$release_missing_file_stub_dir/test/unit/features/projects/data/services/project_portfolio_export_service_test.dart"
touch "$release_missing_file_stub_dir/test/unit/features/projects/domain/export_qa_fixture_test.dart"
chmod +x "$release_missing_file_stub_dir/tool/release_smoke.sh" "$release_missing_file_stub_dir/tool/smoke_common.sh"

cat > "$release_missing_file_stub_dir/flutter-stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter|args=%s\n' "$*"
EOF
chmod +x "$release_missing_file_stub_dir/flutter-stub.sh"

set +e
release_missing_file_output="$(
  cd "$release_missing_file_stub_dir" &&
  SMOKE_SKIP_VERSION=1 SMOKE_SKIP_ANALYZE=1 FLUTTER_BIN="$release_missing_file_stub_dir/flutter-stub.sh" ./tool/release_smoke.sh 2>&1
)"
release_missing_file_status=$?
set -e

if [[ "$release_missing_file_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] release smoke missing-file path drifted: expected non-zero status" >&2
  rm -rf "$release_missing_file_stub_dir"
  exit 1
fi

if ! grep -Fqx -- '[release-smoke] missing expected test file: test/widget_test.dart' <<<"$release_missing_file_output"; then
  echo "[docs-handoff-smoke] release smoke missing-file output drifted" >&2
  rm -rf "$release_missing_file_stub_dir"
  exit 1
fi

rm -rf "$release_missing_file_stub_dir"

beta_handoff_smoke_output="$("$BETA_HANDOFF_SMOKE_PATH")"

for expected_line in \
  "[beta-handoff-smoke] stubbed beta_handoff order stays intact" \
  "[beta-handoff-smoke] all preflight stage labels stay surfaced" \
  "[beta-handoff-smoke] downstream smoke scripts inherit skip version/analyze flags" \
  "[beta-handoff-smoke] verify receives SKIP_PUB_GET=1 from beta_handoff" \
  "[beta-handoff-smoke] built web follow-up labels stay surfaced" \
  "[beta-handoff-smoke] manual follow-up keeps checklist and video workflow pointers visible" \
  "[beta-handoff-smoke] early stage failures stop later preflights and manual follow-up" \
  "[beta-handoff-smoke] missing required scripts fail before startup work begins" \
  "[beta-handoff-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$beta_handoff_smoke_output"; then
    echo "[docs-handoff-smoke] beta handoff smoke output drifted: missing line: $expected_line" >&2
    exit 1
  fi
done

web_shell_smoke_output="$("$ROOT_DIR/tool/web_shell_smoke.sh" web)"

for expected_line in \
  "[web-shell-smoke] validated shell metadata in $ROOT_DIR/web" \
  "[web-shell-smoke] title: Production Chat Prop" \
  "[web-shell-smoke] short_name: Chat Prop" \
  "[web-shell-smoke] theme: #155EEF" \
  "[web-shell-smoke] icons: 4" \
  "[web-shell-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$web_shell_smoke_output"; then
    echo "[docs-handoff-smoke] web shell smoke output drifted: missing line: $expected_line" >&2
    exit 1
  fi
done

web_shell_missing_manifest_stub_dir="$(mktemp -d)"
cat > "$web_shell_missing_manifest_stub_dir/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Production Chat Prop</title>
  </head>
  <body></body>
</html>
EOF
: > "$web_shell_missing_manifest_stub_dir/favicon.png"

set +e
web_shell_missing_manifest_output="$("$ROOT_DIR/tool/web_shell_smoke.sh" "$web_shell_missing_manifest_stub_dir" 2>&1)"
web_shell_missing_manifest_status=$?
set -e

if [[ "$web_shell_missing_manifest_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] web shell smoke missing-manifest path drifted: expected non-zero status" >&2
  rm -rf "$web_shell_missing_manifest_stub_dir"
  exit 1
fi

if ! grep -Fqx -- "[web-shell-smoke] missing manifest.json: $web_shell_missing_manifest_stub_dir/manifest.json" <<<"$web_shell_missing_manifest_output"; then
  echo "[docs-handoff-smoke] web shell smoke missing-manifest output drifted" >&2
  rm -rf "$web_shell_missing_manifest_stub_dir"
  exit 1
fi

rm -rf "$web_shell_missing_manifest_stub_dir"

brand_smoke_output="$("$BRAND_SMOKE_PATH" lib web)"

if ! grep -Eq '^\[brand-neutrality-smoke\] validated [0-9]+ text files across: lib, web$' <<<"$brand_smoke_output"; then
  echo "[docs-handoff-smoke] brand-neutrality smoke output drifted: missing validated-count line for lib/web targets" >&2
  exit 1
fi

for expected_line in \
  "[brand-neutrality-smoke] no forbidden messaging-brand copy found in scanned app surfaces" \
  "[brand-neutrality-smoke] done"; do
  if ! grep -Fqx -- "$expected_line" <<<"$brand_smoke_output"; then
    echo "[docs-handoff-smoke] brand-neutrality smoke output drifted: missing line: $expected_line" >&2
    exit 1
  fi
done

brand_smoke_failure_stub_dir="$(mktemp -d)"
mkdir -p "$brand_smoke_failure_stub_dir/tool" "$brand_smoke_failure_stub_dir/lib"
cp "$BRAND_SMOKE_PATH" "$brand_smoke_failure_stub_dir/tool/brand_neutrality_smoke.sh"
printf "const kBad = 'WhatsApp look';\n" > "$brand_smoke_failure_stub_dir/lib/bad_copy.dart"
chmod +x "$brand_smoke_failure_stub_dir/tool/brand_neutrality_smoke.sh"

set +e
brand_smoke_failure_output="$(
  cd "$brand_smoke_failure_stub_dir" &&
  ./tool/brand_neutrality_smoke.sh lib 2>&1
)"
brand_smoke_failure_status=$?
set -e

if [[ "$brand_smoke_failure_status" -eq 0 ]]; then
  echo "[docs-handoff-smoke] brand-neutrality smoke failure path drifted: expected non-zero status" >&2
  rm -rf "$brand_smoke_failure_stub_dir"
  exit 1
fi

if ! grep -Fq -- "[brand-neutrality-smoke] brand-safe copy check failed:" <<<"$brand_smoke_failure_output"; then
  echo "[docs-handoff-smoke] brand-neutrality smoke failure output drifted: missing failure header" >&2
  rm -rf "$brand_smoke_failure_stub_dir"
  exit 1
fi

if ! grep -Fq -- "lib/bad_copy.dart:1: string literal contains forbidden brand 'WhatsApp'" <<<"$brand_smoke_failure_output"; then
  echo "[docs-handoff-smoke] brand-neutrality smoke failure output drifted: missing offending file summary" >&2
  rm -rf "$brand_smoke_failure_stub_dir"
  exit 1
fi

rm -rf "$brand_smoke_failure_stub_dir"

echo "[docs-handoff-smoke] done"
