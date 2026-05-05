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
- [x] Short demo flow / smoke checklist for stakeholder review (`07-demo-script.md`, `08-web-smoke-checklist.md`)
- [ ] Decide whether next phase is mobile kickoff or extra web polish

## Recommended verification order

1. Run `./tool/release_smoke.sh` for targeted export/reliability regressions
2. Run `./tool/compact_smoke.sh` for phone-width compact/export regressions
3. Run `./tool/verify.sh` for the full analyze + test + web build gate
4. Run the quick browser pass from `08-web-smoke-checklist.md`
5. Run the narrow-screen pass from `09-compact-smoke-checklist.md`
6. Run the focused export pass from `04-export-qa-checklist.md`
7. If all six are clean, treat web MVP as functionally ready and choose between:
   - mobile kickoff, or
   - one final web polish-only pass

## Recommended next step

Run `./tool/release_smoke.sh`, then `./tool/compact_smoke.sh`, then `./tool/verify.sh`, then finish the three manual checklists.

## Latest verification snapshot

- `bash tool/verify.sh` passed (`flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web`)
- `bash tool/compact_smoke.sh` passed for targeted compact/export regressions
- `bash tool/release_smoke.sh` now covers empty-scene export disabling, export toggle feedback, aspect-ratio stability, and long-chat responsiveness as a faster pre-manual gate, not a replacement for the full verify/build step
- playback preview toggle behavior is covered so frame/clean preview state affects the export preview
- video fallback export covers unsupported-download environments with clipboard fallback feedback
- playback screenshot/export output should still be manually checked in a real browser because the current web/desktop content frame constrains rendered preview width
