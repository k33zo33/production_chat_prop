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

checks = [
    (expected_sequence in readme,
     'README quality gate sequence is missing ai_helper_smoke/docs_handoff_smoke/navigation_smoke or is out of date'),
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
     'verify receives SKIP_PUB_GET=1 from beta_handoff' in beta_handoff_smoke,
     'tool/beta_handoff_smoke.sh should keep validating beta_handoff order and skip-flag wiring'),
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
    ('mobile compact polish coverage drifted' in compact_smoke and
     'playback empty-state coverage drifted' in compact_smoke and
     'recovery coverage drifted' in compact_smoke and
     'focus preview auto-follow coverage drifted' in compact_smoke and
     'focus preview short-height coverage drifted' in compact_smoke and
     'short-height entry-state coverage drifted' in compact_smoke,
     'tool/compact_smoke.sh should keep the focused coverage-drift guards for dedicated test files'),
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

echo "[docs-handoff-smoke] done"
