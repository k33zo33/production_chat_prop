# Web Done Checklist

## Current status

This checklist reflects the current web MVP state after the automated beta handoff stack passed end-to-end (`./tool/beta_handoff.sh`). The remaining beta work is now mostly manual browser/export QA plus any final polish we decide to keep in scope.

## Core MVP flow

- [x] Project list exists and opens correctly
- [x] New project creation works
- [x] Project rename / duplicate / delete flows work
- [x] Project type changes work
- [x] Import JSON flow works
- [x] Local project persistence/import-export project flows exist
- [x] Chat editor opens from project list and portfolio CTA paths
- [x] Character CRUD works
- [x] Scene CRUD works
- [x] Message CRUD works
- [x] Scene template / empty-scene recovery flow works
- [x] Playback opens from project and portfolio flows
- [x] Playback play / pause / restart / seek controls work
- [x] Playback remains stable after scene message clearing
- [x] Playback remains responsive with 500+ messages
- [x] Screenshot/video export buttons and readiness states are wired

## Quality gates

- [x] `flutter analyze`
- [x] `flutter test test/widget_test.dart`
- [x] `flutter build web`
- [x] `./tool/web_shell_smoke.sh` validates shell metadata, icons, and brand-neutral web copy
- [x] `./tool/brand_neutrality_smoke.sh` scans user-facing app copy and built web output for forbidden real-brand references
- [x] `./tool/demo_smoke.sh` covers the core beta demo/import/export flow
- [x] `./tool/import_smoke.sh` hardens JSON import, sanitizer, and persistence recovery paths
- [x] `./tool/ai_helper_smoke.sh` keeps the Gemini helper wrapper parsing and fallback behavior covered without depending on a live Gemini backend
- [x] `./tool/beta_handoff.sh`
- [x] `./tool/desktop_smoke.sh` keeps the Docker desktop fallback path checked in CI as a separate gate
- [x] Main widget flow stabilized on web

## MVP alignment vs docs

From `01-product-spec-mvp.md` and `03-roadmap-and-sprints.md`, the web MVP expectations that are clearly covered now include:

- [x] Project list
- [x] Chat editor
- [x] Playback mode
- [x] Screenshot/video export entry points
- [x] Long-conversation stability expectation (500+ messages)
- [x] Basic widget-test coverage for critical flows

## Remaining non-blocking follow-up items

These are not current blockers for the automated web gate, but are sensible next steps before calling release/demo quality fully done:

- [ ] Small web polish/release pass (spacing, typography, visual consistency audit)
- [ ] Manual export QA on real browser session for PNG/video output quality and browser-specific download/clipboard behavior
- [x] Video fallback handoff is now explicitly documented for downstream render users (`11-video-fallback-workflow.md`)
- [x] Short demo flow / smoke checklist for stakeholder review (`07-demo-script.md`, `08-web-smoke-checklist.md`)
- [ ] Decide whether next phase is mobile kickoff or extra web polish

## Recommended verification order

1. Run `./tool/beta_handoff.sh` for the standard beta preflight order (`docs_handoff_smoke -> ai_helper_smoke -> web_shell_smoke -> brand_neutrality_smoke -> demo_smoke -> import_smoke -> release_smoke -> compact_smoke -> navigation_smoke -> verify -> built web_shell_smoke -> built brand_neutrality_smoke`)
2. Run `./tool/manual_beta_checklist.sh` so the browser/export handoff starts from one standard manual order and fixture
3. Run the quick browser pass from `08-web-smoke-checklist.md`
4. Run the narrow-screen pass from `09-compact-smoke-checklist.md`
5. Run the focused export pass from `04-export-qa-checklist.md` and keep `11-video-fallback-workflow.md` alongside the handoff
6. If all five are clean, treat web MVP as functionally ready and choose between:
   - mobile kickoff, or
   - one final web polish-only pass

## Recommended next step

Run `./tool/manual_beta_checklist.sh`, then finish the three manual checklists (`08-web-smoke-checklist.md`, `09-compact-smoke-checklist.md`, and `04-export-qa-checklist.md`) using the latest green `./tool/beta_handoff.sh` run as the automated baseline.

## Latest verification snapshot

- `./tool/beta_handoff.sh` passed end-to-end (`docs_handoff_smoke -> ai_helper_smoke -> web_shell_smoke -> brand_neutrality_smoke -> demo_smoke -> import_smoke -> release_smoke -> compact_smoke -> navigation_smoke -> verify -> built web_shell_smoke -> built brand_neutrality_smoke`)
- `bash tool/verify.sh` passed (`flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web`)
- video fallback export now has a dedicated handoff explainer so beta users know that `Export Video` currently emits a documented `.json` render package rather than a final encoded movie file
- the tracked export QA fixture now includes an embedded avatar sample in the hero portrait scene, so manual browser export QA can confirm avatar retention in both PNG preview/export and fallback JSON payloads
- `bash tool/demo_smoke.sh` now covers the core beta walkthrough path plus portfolio-readiness CTA navigation and import/export handoff regressions before the heavier release gates
- `bash tool/import_smoke.sh` now catches JSON import, sanitizer, and persisted-project recovery regressions before export/mobile passes
- `./tool/compact_smoke.sh` passed for targeted compact/export regressions, including larger-text compact breakpoints on project list/editor/playback surfaces, narrow delete confirmations, long project-name/header clamping, short-landscape compact navigation/focus-preview flows, deep long-scene focus-preview auto-follow on phone-width layouts, short-height empty/recovery entry shells, project-list search/filter/sort controls, portfolio-readiness CTA flows, stale-link recovery paths, ultra-compact editor/playback footer stacking, and focus-preview chrome stacking at larger text
- `./tool/navigation_smoke.sh` now catches scene deep-link sync, stale route query normalization, and recovery navigation regressions before the heavier full-suite verify step
- `bash tool/release_smoke.sh` now covers empty-scene export disabling, larger-text compact breakpoint regressions, deep long-scene focus-preview auto-follow alongside focus-preview transport/keyboard flow plus compact/wide chrome stacking and timeline/preview-state continuity, export toggle feedback, aspect-ratio stability, and long-chat responsiveness as a faster pre-manual gate, not a replacement for the full verify/build step
- `release_smoke` and `compact_smoke` now also fail on coverage-count drift for the dedicated focused test files they fully own, so targeted smoke coverage is less likely to erode quietly after test-file reshuffles
- `./tool/beta_handoff.sh` now also keeps the aggregate path leaner by reusing one upstream Flutter banner + `pub get` + `analyze`, then relying on skip ponovljenog flutter bannera, skip dodatnog analyze, and skip ponovnog `pub get` in the downstream stack
- GitHub Actions now mirrors `./tool/beta_handoff.sh` so push/PR CI exercises `docs_handoff_smoke -> ai_helper_smoke -> web_shell_smoke -> brand_neutrality_smoke -> demo_smoke -> import_smoke -> release_smoke -> compact_smoke -> navigation_smoke -> verify -> built web_shell_smoke -> built brand_neutrality_smoke` before uploading the web artifact
- GitHub Actions now also runs `./tool/ai_helper_smoke.sh` as a separate `helper_smoke` job, and the main `beta_handoff` job explicitly waits for it so CI ordering stays aligned with the local handoff
- GitHub Actions now also runs `./tool/desktop_smoke.sh` as a separate `desktop_smoke` job so Docker desktop packaging/noVNC regressions surface before they become a beta handoff surprise
- web shell metadata is now gated for both source `web/` assets and built `build/web` output, so title/manifest/icon regressions get caught before beta handoff
- user-facing app copy and built output now get dedicated brand-neutrality scans, so accidental forbidden messaging-brand labels are blocked before beta handoff
- playback preview toggle behavior is covered so frame/clean preview state affects the export preview
- video fallback export covers unsupported-download environments with clipboard fallback feedback
- playback screenshot/export output should still be manually checked in a real browser before release, but the desktop playback frame now gives the preview more breathing room so browser QA is closer to the final export surface
