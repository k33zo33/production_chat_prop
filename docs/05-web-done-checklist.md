# Web Done Checklist

## Current status

This checklist reflects the current web MVP state after the widget test stabilization and playback/project-flow fixes.

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

1. Run `./tool/beta_handoff.sh` for the standard beta preflight order (`web_shell_smoke -> brand_neutrality_smoke -> demo_smoke -> import_smoke -> release_smoke -> compact_smoke -> navigation_smoke -> verify -> built web_shell_smoke -> built brand_neutrality_smoke`)
2. Run the quick browser pass from `08-web-smoke-checklist.md`
3. Run the narrow-screen pass from `09-compact-smoke-checklist.md`
4. Run the focused export pass from `04-export-qa-checklist.md` and keep `11-video-fallback-workflow.md` alongside the handoff
5. If all four are clean, treat web MVP as functionally ready and choose between:
   - mobile kickoff, or
   - one final web polish-only pass

## Recommended next step

Run `./tool/beta_handoff.sh`, then finish the three manual checklists.

## Latest verification snapshot

- `bash tool/verify.sh` passed (`flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web`)
- video fallback export now has a dedicated handoff explainer so beta users know that `Export Video` currently emits a documented `.json` render package rather than a final encoded movie file
- `bash tool/demo_smoke.sh` now covers the core beta walkthrough path plus portfolio-readiness CTA navigation and import/export handoff regressions before the heavier release gates
- `bash tool/import_smoke.sh` now catches JSON import, sanitizer, and persisted-project recovery regressions before export/mobile passes
- `./tool/compact_smoke.sh` passed for targeted compact/export regressions, including narrow delete confirmations, long project-name/header clamping, project-list search/filter/sort controls, portfolio-readiness CTA flows, and stale-link recovery paths
- `./tool/navigation_smoke.sh` now catches scene deep-link sync, stale route query normalization, and recovery navigation regressions before the heavier full-suite verify step
- `bash tool/release_smoke.sh` now covers empty-scene export disabling, focus-preview transport/keyboard flow, export toggle feedback, aspect-ratio stability, and long-chat responsiveness as a faster pre-manual gate, not a replacement for the full verify/build step
- GitHub Actions now mirrors `./tool/beta_handoff.sh` so push/PR CI exercises `web_shell_smoke -> brand_neutrality_smoke -> demo_smoke -> import_smoke -> release_smoke -> compact_smoke -> navigation_smoke -> verify -> built web_shell_smoke -> built brand_neutrality_smoke` before uploading the web artifact
- GitHub Actions now also runs `./tool/desktop_smoke.sh` as a separate `desktop_smoke` job so Docker desktop packaging/noVNC regressions surface before they become a beta handoff surprise
- web shell metadata is now gated too, so title/manifest/icon regressions or accidental real-brand references get caught before beta handoff
- user-facing app copy and built output now get a dedicated brand-neutrality scan too, so accidental forbidden messaging-brand labels are blocked before beta handoff
- playback preview toggle behavior is covered so frame/clean preview state affects the export preview
- video fallback export covers unsupported-download environments with clipboard fallback feedback
- playback screenshot/export output should still be manually checked in a real browser before release, but the desktop playback frame now gives the preview more breathing room so browser QA is closer to the final export surface
