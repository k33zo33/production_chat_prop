# Production Chat Prop

Production Chat Prop je Flutter web-first MVP za kreiranje i reprodukciju simuliranih chat razgovora za produkcijske potrebe.

## MVP bootstrap status

Ovaj commit pokriva Fazu 0 bootstrap:
- Flutter projekt inicijaliziran u rootu repozitorija
- Web-first setup
- Riverpod + GoRouter + very_good_analysis
- Feature-first početna struktura mapa
- Početni router, tema i placeholder ekrani:
  - Project List
  - Chat Editor
  - Playback
- Početni domenski modeli:
  - `Project`
  - `Scene`
  - `Character`
  - `Message`

## Lokalno pokretanje

Ako `flutter` nije globalno na PATH-u, koristi apsolutnu putanju:

```bash
/home/server/flutter/bin/flutter pub get
/home/server/flutter/bin/flutter analyze
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
