# Video Fallback Workflow

Svrha: jasno objasniti što današnji `Export Video` gumb isporučuje u beta MVP-u i kako taj `.json` paket ide dalje u post-produkciju.

## Trenutno stanje

Production Chat Prop u web MVP-u još ne renderira gotovi `.mp4` ili `.mov` direktno iz appa.

Umjesto toga, `Export Video` izvozi **video fallback package** (`.json`) koji čuva:
- cijeli projekt
- trenutno odabranu scenu
- sortirane poruke za odabranu scenu
- export hintove (`includeDeviceFrame`, `cleanPreview`, ciljne omjere)
- kratki workflow podsjetnik za downstream render

To je namjerni sprint-4 fallback iz `03-roadmap-and-sprints.md`: korisnik mora dobiti **jasno dokumentiran privremeni workaround za video izlaz**.

## Što operator dobije iz appa

Naziv datoteke prati oblik:

```text
pcp_video_fallback_<project>_<scene>_<timestamp>.json
```

Na webu app pokušava pokrenuti download. Ako platforma to ne dopusti, UI fallback jasno javlja da je JSON kopiran u clipboard kako bi se paket ipak mogao spremiti ili zalijepiti u drugi alat.

## Struktura paketa

Fallback paket sadrži ove glavne ključeve:

- `meta`
  - `tool`: `Production Chat Prop`
  - `format`: `video_fallback_package`
  - `version`: `1`
  - `exportedAt`: ISO timestamp izvoza
- `project`
  - normalizirani projekt sa svim scenama
  - odgovarajuća scena u `project.scenes` ima poruke već sortirane po `timestampSeconds`
- `selectedScene`
  - trenutno odabrana scena za render
  - `messages` su sortirane po `timestampSeconds`
- `renderHints`
  - `targetRatios`: `9:16`, `16:9`
  - `includeDeviceFrame`
  - `cleanPreview`
- `workflow`
  - ugrađeni tekstualni podsjetnik za downstream render korake

## Preporučeni handoff za beta tim

1. U Playbacku odabrati scenu i željeni omjer (`9:16` ili `16:9`).
2. Podesiti `Show Device Frame` i `Clean Preview Mode` prema željenom izlazu.
3. Kliknuti `Export Video`.
4. Spremiti dobiveni `.json` paket uz naziv scene/shota u shared folder produkcije.
5. Motion/video editor u svom render workflowu koristi:
   - `selectedScene.messages` kao izvor cuejeva
   - `timestampSeconds` za tempo i raspored poruka
   - `selectedScene.aspectRatio` za osnovni layout
   - `renderHints.includeDeviceFrame` i `renderHints.cleanPreview` za vizualnu varijantu
   - `project` ako treba puni kontekst scena ili dodatni metadata handoff
6. Render napraviti izvan appa (npr. interni motion template, custom renderer ili ručni compositing workflow).

## Minimalna pravila za downstream renderer

Downstream workflow bi trebao poštovati barem ovo:
- poruke renderirati redom iz `selectedScene.messages`
- koristiti `timestampSeconds` kao cue timeline
- zadržati incoming/outgoing smjer, status i typing metadata
- poštovati `selectedScene.aspectRatio`
- po potrebi izvesti i `9:16` i `16:9` varijantu

## Kako ovo provjeriti prije beta handoffa

Za ručni pass koristi:
- `docs/04-export-qa-checklist.md` — provjera da payload i fallback ponašanje odgovaraju previewu
- `docs/08-web-smoke-checklist.md` — brzi browser pass
- `docs/09-compact-smoke-checklist.md` — narrow/phone-width pass

Ako tim traži gotov video iz samog appa, to je **sljedeći feature** i nije isto što i trenutni documented fallback workflow.