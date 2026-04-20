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

These are not current blockers for the web test/stability gate, but are sensible next steps:

- [ ] Small web polish/release pass (spacing, typography, visual consistency audit)
- [ ] Manual export QA on real browser session for PNG/video output quality
- [ ] Short demo flow / smoke checklist for stakeholder review
- [ ] Decide whether next phase is mobile kickoff or extra web polish

## Recommended next step

Run a short manual web smoke pass, then either:
1. declare web MVP done and start mobile kickoff, or
2. spend one small pass on web polish/release prep only.

## Latest verification snapshot

- `flutter analyze` passed
- `flutter test test/widget_test.dart` passed
- `flutter build web` passed
