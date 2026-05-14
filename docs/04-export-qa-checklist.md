# Export QA Checklist (Sprint 4)

Svrha: brza ručna provjera da je export workflow konzistentan s previewem i da fallback ponašanje radi predvidljivo.

## 1) Preduvjeti
- Pokrenut app lokalno (`flutter run -d web-server` ili browser target)
- Prije ručnog passa pokrenuti `./tool/release_smoke.sh` kao brzi automatski preflight za export/reliability regressions (widget + export unit testovi)
- Prije release/deploy odluke i dalje odraditi puni `./tool/verify.sh`
- Postoji barem jedan projekt sa scenom i porukama
- Testirati i na praznoj sceni (0 poruka)

## 2) Screenshot export (PNG)
- [ ] U Playbacku uključiti/isključiti `Show Device Frame`
- [ ] Uključiti/isključiti `Clean Preview Mode`
- [ ] Kliknuti `Export Screenshot`
- [ ] Provjeriti:
  - [ ] labela `Export readiness` pokazuje očekivano stanje prije exporta (`Ready` kad scena ima poruke)
  - [ ] na webu se pokreće download `.png` datoteke
  - [ ] naziv datoteke sadrži projekt + scenu + timestamp
  - [ ] sadržaj odgovara trenutnom previewu, uključujući frame/clean toggle stanje (timeline, status chipovi, typing)

## 3) Video fallback export (`.json`)
- [ ] Kliknuti `Export Video`
- [ ] Provjeriti:
  - [ ] na webu se pokreće download `.json` datoteke ili, ako download nije dostupan, app jasno javlja da je fallback JSON kopiran u clipboard
  - [ ] payload sadrži `project`, `selectedScene`, `renderHints`, `workflow`
  - [ ] `renderHints.includeDeviceFrame` i `cleanPreview` prate trenutno stanje toggleova
  - [ ] poruke u `selectedScene.messages` su sortirane po `timestampSeconds`
  - [ ] odgovarajuća scena u `project.scenes` ne proturječi `selectedScene.messages` redoslijedu

## 4) Omjeri izlaza (9:16 / 16:9)
- [ ] U Playbacku prebaciti `Scene ratio` između `9:16` i `16:9`
- [ ] Potvrditi da:
  - [ ] labela prikazuje odabrani omjer
  - [ ] stanje playbacka ostaje stabilno (timecode se ne resetira)
  - [ ] export fallback payload reflektira odabrani omjer kroz `selectedScene.aspectRatio`

## 5) Edge-case provjere
- [ ] Prazna scena:
  - [ ] `Export readiness` prikazuje `No messages in scene`
  - [ ] `Export Screenshot` je disabled
  - [ ] `Export Video` je disabled
- [ ] Duga scena (15+ poruka):
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
