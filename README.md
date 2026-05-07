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
- Sprint 5 polish (u tijeku):
  - demo seed akcija iz Project Lista (`Add Demo Project`) za brzi showcase flow
  - empty-state quick actions (`Create Project`, `Load Demo Project`)
  - scene style presetovi (`studio_default`, `cleanroom_day`, `night_shift`, `warm_paper`)
  - style preset izbor u Scene Settings dijalogu
  - primjena style paleta na poruke u editoru i playbacku
  - Project list quality-of-life:
    - scene/message/max-duration summary po kartici
    - quick type akcije (`Set Type: Ad/Series/Other`)
    - dodatni sort `Updated (Oldest)`
    - JSON handoff flow (`Copy JSON` + `Download JSON` po kartici, `Export All Projects JSON` iz top bara, `Import Project JSON` iz top bara ili `.json` file pickera, single i batch payload, s preview potvrdom prije importa)
  - Playback quality-of-life:
    - progress summary (`Progress %` + `Visible messages`)
    - export readiness status (`Ready` / `No messages in scene` / `Export in progress`)
    - quick seek kontrole `-5s` i `+5s`
    - keyboard kontrole (`Space`, `←`, `→`, `R`) za web playback
  - Chat editor feedback:
    - validacijski snackbari za neispravan timestamp, negativan timestamp i prazan tekst poruke

## Lokalno pokretanje

Ako `flutter` nije globalno na PATH-u, koristi apsolutnu putanju:

```bash
/home/server/flutter/bin/flutter pub get
/home/server/flutter/bin/flutter analyze
/home/server/flutter/bin/flutter test
/home/server/flutter/bin/flutter run -d web-server
```

## Quality Gate

Za puni lokalni release check koristi:

```bash
./tool/verify.sh
```

Isti verify gate sada vrti i GitHub Actions workflow iz `.github/workflows/flutter_ci.yml`, uključujući `flutter build web` i upload gotovog web artefakta.

Za brzi demo smoke check koristi:

```bash
./tool/demo_smoke.sh
```

Za fokusirani compact/export regresijski pass koristi:

```bash
./tool/compact_smoke.sh
```

Za release-gate export/reliability preflight koristi:

```bash
./tool/release_smoke.sh
```

To je namjerno brži pass, ne zamjena za puni `./tool/verify.sh` prije release odluke.

Za standardni beta handoff redoslijed koristi:

```bash
./tool/beta_handoff.sh
```

To vrti `release_smoke -> compact_smoke -> verify`, pa na kraju podsjeti na tri ručne checklist provjere.

Za ručni compact/mobile pass koristi:

- `docs/09-compact-smoke-checklist.md`
- `docs/04-export-qa-checklist.md`

## Demo Flow

Za 2-3 minute walkthrough koristi:

- `docs/07-demo-script.md`

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
- `06-product-description.md`
- `07-demo-script.md`
- `08-web-smoke-checklist.md`
- `09-compact-smoke-checklist.md`
