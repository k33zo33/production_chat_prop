# Demo Script (2-3 minute walkthrough)

## Cilj demoa
U 2-3 minute pokazati tri MVP use-casea:
1. priprema scene (editor)
2. playback kontrola
3. export workflow

## Priprema prije demoa
- pokreni app (`/home/server/flutter/bin/flutter run -d web-server`)
- na početnom ekranu koristi `Load Demo Project`
- otvori `Demo Project 1`

## Koraci uživo
1) **Project list (20-30s)**
- pokaži da je demo projekt označen badgeom `DEMO PRESET`
- istakni scene/message sažetak na kartici
- pokaži `Copy JSON` i `Download JSON` na kartici, `Export All Projects JSON` u top baru, pa `Import Project JSON` u top baru (paste ili `.json` file picker) za handoff između timova; spomeni da import podržava i batch payload (`projects: []`)
- otvori `Open Chat Editor`

2) **Chat editor (45-60s)**
- pokaži scene, likove i poruke bez koda
- promijeni jednu poruku (npr. tekst ili timestamp)
- vrati se na `Back to Projects`

3) **Playback (45-60s)**
- otvori `Open Playback`
- pokaži `Play / Pause / Restart`, slider i cue gumbe
- koristi tipkovnicu: `Space`, `←`, `→`, `R`
- pokaži da progress i visible-messages summary reagiraju u realnom vremenu

4) **Export (30-40s)**
- pokaži `Export readiness`
- klikni `Export Screenshot` ili `Export Video`
- objasni fallback ponašanje na platformama bez direktnog download/export supporta

## Završna poruka (10s)
"Production Chat Prop omogućuje produkcijskom timu da od ideje do playback-ready chata dođe u nekoliko minuta, uz predvidljiv output za set i post-produkciju."

## Optional Q&A backup točke
- lokalno spremanje projekata
- JSON handoff (`Copy JSON` / `Download JSON` / `Export All Projects JSON` / `Import Project JSON` / file picker import / batch import)
- 9:16 i 16:9 ratio podrška
- scene/template workflow
- test coverage i verify/demo-smoke skripte
