# Export QA Checklist (Sprint 4)

Svrha: brza ručna provjera da je export workflow konzistentan s previewem i da fallback ponašanje radi predvidljivo.

## 1) Preduvjeti
- Pokrenut app lokalno (`flutter run -d web-server` ili browser target)
- Prije ručnog passa pokrenuti `./tool/release_smoke.sh` kao brzi automatski preflight za export/reliability regressions (widget + export unit testovi)
- Prije release/deploy odluke i dalje odraditi puni `./tool/verify.sh`
- U app učitati standardni QA projekt preko `Load Export QA Project` quick action ili ručno importati `docs/fixtures/export-qa-project.json`
- Fixture već pokriva:
  - portrait scenu za hero screenshot pass
  - landscape scenu za 16:9 provjeru
  - praznu scenu za disabled export stanje
  - dugu scenu za playback/endurance provjeru

## 2) Screenshot export (PNG)
- [ ] Otvoriti `Scene 1 - Hero Portrait` u Playbacku
- [ ] Uključiti/isključiti `Show Device Frame`
- [ ] Uključiti/isključiti `Clean Preview Mode`
- [ ] Kliknuti `Export Screenshot`
- [ ] Provjeriti:
  - [ ] labela `Export readiness` pokazuje očekivano stanje prije exporta (`Ready` kad scena ima poruke)
  - [ ] na webu se pokreće download `.png` datoteke
  - [ ] naziv datoteke sadrži projekt + scenu + timestamp
  - [ ] sadržaj odgovara trenutnom previewu, uključujući frame/clean toggle stanje (timeline, status chipovi, typing)

## 3) Video fallback export (`.json`)
- [ ] Ostati na `Scene 1 - Hero Portrait` ili prebaciti na `Scene 2 - Hero Landscape`
- [ ] Kliknuti `Export Video`
- [ ] Provjeriti:
  - [ ] na webu se pokreće download `.json` datoteke ili, ako download nije dostupan, app jasno javlja da je fallback JSON kopiran u clipboard
  - [ ] payload sadrži `project`, `selectedScene`, `renderHints`, `workflow`
  - [ ] `renderHints.includeDeviceFrame` i `cleanPreview` prate trenutno stanje toggleova
  - [ ] poruke u `selectedScene.messages` su sortirane po `timestampSeconds`
  - [ ] odgovarajuća scena u `project.scenes` ne proturječi `selectedScene.messages` redoslijedu

## 4) Omjeri izlaza (9:16 / 16:9)
- [ ] Otvoriti `Scene 2 - Hero Landscape`
- [ ] U Playbacku prebaciti `Scene ratio` između `9:16` i `16:9`
- [ ] Potvrditi da:
  - [ ] labela prikazuje odabrani omjer
  - [ ] stanje playbacka ostaje stabilno (timecode se ne resetira)
  - [ ] export fallback payload reflektira odabrani omjer kroz `selectedScene.aspectRatio`

## 5) Edge-case provjere
- [ ] Prazna scena (`Scene 3 - Empty Export Check`):
  - [ ] `Export readiness` prikazuje `No messages in scene`
  - [ ] `Export Screenshot` je disabled
  - [ ] `Export Video` je disabled
- [ ] Duga scena (`Scene 4 - Long Playback Run`, 15+ poruka):
  - [ ] Playback i scrub rade bez rušenja
  - [ ] export gumbi ostaju aktivni
- [ ] Brza promjena kontrola:
  - [ ] toggle frame/clean, pa odmah export
  - [ ] promjena ratio tijekom playbacka
  - [ ] bez exceptiona i bez gubitka stanja

## 6) Minimalna release gate pravila
- [ ] `./tool/release_smoke.sh` prolazi
- [ ] `flutter analyze` prolazi bez issuea
- [ ] `flutter test` prolazi
- [ ] `flutter build web` prolazi
- [ ] ručni QA iz ove liste odrađen barem jednom prije release/deploy odluke
