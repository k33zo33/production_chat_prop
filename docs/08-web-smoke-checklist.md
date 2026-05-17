# Web Smoke Checklist

Svrha: ultra-kratki ljudski smoke pass za potvrdu da web MVP izgleda spremno za demo, handoff i prvi stakeholder pregled.

## 1. Pokretanje
- [ ] Pokreni web build ili lokalni web run
- [ ] Otvori app u browseru
- [ ] Potvrdi da browser tab prikazuje `Production Chat Prop`
- [ ] Potvrdi da nema očitih layout breakova na početnom ekranu
- [ ] Ponovi kratki pass i na uskom viewportu (~390 px širine) radi compact layout provjere

## 2. Project list flow
- [ ] Na početnom ekranu klikni `Load Demo Project`
- [ ] Potvrdi da se pojavi demo projekt kartica
- [ ] Potvrdi da je portfolio readiness summary vidljiv i da CTA gumbi ne djeluju "mrtvo"
- [ ] Klikni `Preview Ready Project` i potvrdi da otvara Playback
- [ ] Vrati se na project list pa klikni `Continue Editing` i potvrdi da otvara editor bez rušenja
- [ ] Ako postoji projekt s attention stanjem, klikni `Review Attention Project`
- [ ] Na uskom viewportu potvrdi da se prikaže compact overflow meni u app baru
- [ ] Otvori project menu i provjeri da osnovne akcije postoje
- [ ] Otvori `Open Chat Editor`

## 3. Editor flow
- [ ] Potvrdi da su scene, likovi i poruke vidljivi
- [ ] Na uskom viewportu potvrdi da su scene akcije dostupne kroz overflow meni
- [ ] Ako koristiš scene deep-link (`?sceneId=...`), probaj browser back/forward i potvrdi da aktivna scena ostane sinkronizirana s URL-om
- [ ] Promijeni barem jednu poruku ili timestamp
- [ ] Vrati se natrag na project list bez rušenja stanja

## 4. Playback flow
- [ ] Otvori `Open Playback`
- [ ] Provjeri `Play`, `Pause`, `Restart`, slider i cue gumbe
- [ ] Ako koristiš scene deep-link (`?sceneId=...`), probaj browser back/forward i potvrdi da playback prebaci scenu bez zaglavljenog starog odabira
- [ ] Klikni `Open Focus Preview` i potvrdi da možeš pustiti/pauzirati preview, koristiti cue/seek gumbe i scrub slider te ga zatvoriti bez rušenja stanja
- [ ] Na uskom viewportu potvrdi da nema očitog overlap/overflow loma u export i transport kontrolama
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
