# Production Chat Prop

Production Chat Prop je Flutter web-first MVP za kreiranje i reprodukciju simuliranih chat razgovora za produkcijske potrebe.

## Trenutni status

- Faza 0 završena: bootstrap, routing, folder struktura, lint setup
- Sprint 1/2 osnova:
  - modeli (`Project`, `Scene`, `Character`, `Message`) + JSON serijalizacija
  - lokalno spremanje projekata
  - Project list CRUD (create/rename/duplicate/delete)
  - Chat editor:
    - likovi CRUD
    - poruke CRUD + reorder + bulk delete
    - scene CRUD + reorder + duplicate
    - scene template akcije
- Sprint 3 osnova:
  - Playback controller (play/pause/restart/scrub/seek/end)
  - typing indikator, status prikaz, cue skokovi
  - sinkronizacija s editor promjenama
- Sprint 4 početni deliverables:
  - PNG screenshot export pipeline (web download + fallback poruka)
  - video fallback package export (`.json`) za post-produkcijski workflow
  - kontrola scene omjera 9:16 / 16:9 u Playbacku

## Lokalno pokretanje

Ako `flutter` nije globalno na PATH-u, koristi apsolutnu putanju:

```bash
/home/server/flutter/bin/flutter pub get
/home/server/flutter/bin/flutter analyze
/home/server/flutter/bin/flutter test
/home/server/flutter/bin/flutter run -d web-server
```

## Struktura

```text
lib/
  app/
  core/
    theme/
    widgets/
    utils/
  features/
    projects/
      data/
      domain/
      presentation/
    chat_editor/
      data/
      domain/
      presentation/
    playback/
      presentation/
  main.dart
```

## Reference docs

Izvor istine za scope i arhitekturu nalazi se u `docs/`:
- `01-product-spec-mvp.md`
- `02-technical-architecture-flutter.md`
- `03-roadmap-and-sprints.md`
- `04-export-qa-checklist.md`
