# Master prompt za Codex

Kopiraj ovaj prompt u Codex na početku projekta.

---

You are helping me bootstrap a new Flutter project called **Production Chat Prop**.

Read and follow these documents as the source of truth:
- `01-product-spec-mvp.md`
- `02-technical-architecture-flutter.md`
- `03-roadmap-and-sprints.md`

## Product summary
Production Chat Prop is a Flutter Web-first application for creating, editing, playing back, and exporting simulated chat conversations for production use cases such as ads, series, film props, storyboards, and post-production assets.

This is **not** a prank app and **not** a clone of WhatsApp, Messenger, Instagram, Telegram, or any other real brand. The app must use an original visual system and original theme names.

## What I want you to do now
Create the **initial project skeleton** for the MVP.

## Technical constraints
- Flutter stable channel
- Target: Web first
- Use **Riverpod** for state management
- Use **GoRouter** for routing
- Use a **feature-first layered architecture**
- Keep persistence local for MVP
- Do not add auth, backend, cloud sync, or AI generation features
- Keep the code simple, readable, and easy to extend
- Avoid overengineering

## Initial deliverables
Please generate:
1. Folder structure according to the architecture doc
2. `main.dart`, `app.dart`, and router setup
3. Basic theme setup
4. Data/domain/presentation structure for these features:
   - projects
   - chat_editor
   - playback
5. Dart models for:
   - Project
   - Scene
   - Character
   - Message
6. Basic repository interface and a simple local in-memory or local-storage-backed implementation
7. Initial screens:
   - ProjectListPage
   - ChatEditorPage
   - PlaybackPage
8. Dummy seed data so the app runs immediately
9. Minimal tests for models or basic logic

## Architecture rules
- UI must not directly own business logic
- Keep controllers/providers separate from widgets
- Models should support JSON serialization
- The code should be organized by feature
- Reusable UI goes in `core/widgets`
- Shared theming goes in `core/theme`
- Routing goes in `app/router.dart`

## UX scope for this first pass
- Project list shows existing projects and button for new project
- Chat editor shows characters sidebar, messages list, and add-message form placeholder
- Playback page shows a mock conversation preview plus Play/Pause/Restart controls
- No need to implement final export yet; create clear placeholders for screenshot and video export actions

## Output rules
- Generate the code in a way that can compile after dependency installation
- Prefer a small number of files over too many abstract layers
- Add short comments only where they help readability
- Do not invent features outside the documents
- If something is ambiguous, choose the simplest implementation that keeps the architecture clean

## After generating code
Also provide:
1. a short explanation of the folder structure
2. a list of dependencies to add to `pubspec.yaml`
3. a step-by-step checklist for what to implement next in Sprint 1

---

## Follow-up prompt za Sprint 1
When the bootstrap is done, use this follow-up prompt:

Implement Sprint 1 from `03-roadmap-and-sprints.md`.
Use the current codebase and do not rewrite the architecture.
Focus on:
- solid Dart models
- local project loading/saving
- project list UI
- opening a dummy project in the editor
- clean Riverpod providers
- basic tests

Return code changes file by file.

---

## Follow-up prompt za Chat Editor
Implement the first functional version of `ChatEditorPage` based on `01-product-spec-mvp.md` and `02-technical-architecture-flutter.md`.

Requirements:
- characters sidebar
- message list
- add/edit/delete message actions
- select character per message
- edit timestamp and status
- switch between 2 to 3 original chat styles

Keep the UI production-friendly and simple.
Do not imitate any real messaging brand.

---

## Follow-up prompt za Playback
Implement the first working playback flow.

Requirements:
- Play / Pause / Restart
- simple time-based reveal of messages using `timestampSeconds`
- scrubber slider
- typing indicator support
- playback preview UI based on the active chat style

Keep playback logic separated from editor logic.
