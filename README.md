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
- Sprint 5 feature scope isporučen; završni release-gate QA/polish je i dalje aktivan:
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

## Desktop u Dockeru

Desktop varijanta koristi službeni Flutter Linux scaffold i pokreće aplikaciju u Docker kontejneru preko virtualnog X ekrana. GUI je dostupan kroz noVNC u browseru, tako da na hostu ne treba imati Flutter desktop toolchain.

Sigurnosna napomena: ovaj setup je namijenjen lokalnom developmentu na istom računalu. noVNC i VNC portovi su sada vezani samo na `127.0.0.1`; ne izlaži ih dalje bez dodatne autentikacije/proxy sloja.

```bash
./tool/desktop_docker.sh
```

Za brzi health/smoke check Docker desktop flowa bez ručnog otvaranja preglednika koristi:

```bash
./tool/desktop_smoke.sh
```

Nakon što se image izgradi i aplikacija pokrene, otvori:

```text
http://localhost:6080/vnc.html?host=localhost&port=6080&autoconnect=true&resize=remote
```

Direktna Compose komanda je:

```bash
docker compose -f docker-compose.desktop.yml up --build
```

Kontejner expose-a i VNC port `5900` samo na `localhost`. Lokalni app podaci spremaju se u Docker volume `production_chat_prop_desktop_config`.

## Quality Gate

GitHub Actions i lokalni beta handoff koriste isti redoslijed za web release gate:

`web_shell_smoke -> demo_smoke -> import_smoke -> release_smoke -> compact_smoke -> verify -> built web_shell_smoke`

`./tool/beta_handoff.sh` dodatno vrti mali docs-sync preflight kako README, checklist i CI ne bi tiho odlutali iz stvarnog handoff reda.

Uz to, GitHub Actions sada vrti i zaseban `desktop_smoke` job koji pokreće `./tool/desktop_smoke.sh` kako bi Docker desktop packaging/noVNC flow ostao živ bez miješanja u web handoff redoslijed.

Ako sve prođe, CI upload-a gotovi web build artefakt.

Najčešće komande:

```bash
./tool/demo_smoke.sh
./tool/import_smoke.sh
./tool/release_smoke.sh
./tool/compact_smoke.sh
./tool/desktop_smoke.sh
./tool/verify.sh
./tool/beta_handoff.sh
```

Napomene:
- `./tool/release_smoke.sh` je brži export/reliability preflight i sada pokriva i ciljane export unit testove, ali nije zamjena za puni `./tool/verify.sh` prije release odluke.
- `./tool/compact_smoke.sh` sada hvata i stale-link/missing-project recovery putanje, ne samo narrow layout i export kontrole.
- `./tool/beta_handoff.sh` vrti cijeli standardni redoslijed, uključujući import/recovery gate, i na kraju podsjeti na ručne checklist provjere.
- Za ručni compact/mobile i export pass koristi:
  - `docs/09-compact-smoke-checklist.md`
  - `docs/04-export-qa-checklist.md`
  - `docs/11-video-fallback-workflow.md`
- Standardni ručni import/export QA sample je `docs/fixtures/export-qa-project.json`.
- Trenutni `Export Video` workflow isporučuje dokumentirani `.json` handoff paket za downstream render, ne gotovi video file iz samog appa.

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
- `11-video-fallback-workflow.md`
