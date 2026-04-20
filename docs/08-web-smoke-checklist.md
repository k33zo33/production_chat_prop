# Web Smoke Checklist

Svrha: ultra-kratki ljudski smoke pass za potvrdu da web MVP izgleda spremno za demo, handoff i prvi stakeholder pregled.

## 1. Pokretanje
- [ ] Pokreni web build ili lokalni web run
- [ ] Otvori app u browseru
- [ ] Potvrdi da browser tab prikazuje `Production Chat Prop`
- [ ] Potvrdi da nema očitih layout breakova na početnom ekranu

## 2. Project list flow
- [ ] Na početnom ekranu klikni `Load Demo Project`
- [ ] Potvrdi da se pojavi demo projekt kartica
- [ ] Otvori project menu i provjeri da osnovne akcije postoje
- [ ] Otvori `Open Chat Editor`

## 3. Editor flow
- [ ] Potvrdi da su scene, likovi i poruke vidljivi
- [ ] Promijeni barem jednu poruku ili timestamp
- [ ] Vrati se natrag na project list bez rušenja stanja

## 4. Playback flow
- [ ] Otvori `Open Playback`
- [ ] Provjeri `Play`, `Pause`, `Restart`, slider i cue gumbe
- [ ] Provjeri da `Space`, `←`, `→`, `R` rade ako je fokus na appu
- [ ] Potvrdi da se timecode i visible message summary mijenjaju tijekom playbacka

## 5. Export flow
- [ ] Provjeri da `Export readiness` prikazuje očekivano stanje
- [ ] Klikni `Export Screenshot`
- [ ] Klikni `Export Video`
- [ ] Potvrdi da browser ponašanje izgleda očekivano (download ili jasan fallback feedback)

## 6. Gotovost za web MVP
Web MVP se može smatrati praktično gotovim ako:
- [ ] analyze/test/build gate je već zelen
- [ ] ovaj kratki smoke pass ne otkrije blocker
- [ ] demo flow izgleda dovoljno čisto za pokazivanje
