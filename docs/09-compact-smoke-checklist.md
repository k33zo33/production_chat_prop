# Compact / Mobile Smoke Checklist

Svrha: kratki ručni pass za phone-width layout prije beta demoa ili release odluke.

Preporučeni viewport:
- ~390 px širine za standardni compact layout
- ~320 px širine za ultra-compact playback i project-list provjeru

## 1. Project list
- [ ] Otvori app na uskom viewportu
- [ ] Potvrdi da app bar koristi overflow meni umjesto širokog seta akcija
- [ ] Klikni `Load Demo Project` ili `Add Demo Project`
- [ ] Na ~320 px potvrdi da project list ostaje scrollabilan i da nema očitog overflowa u gornjim kontrolama ili summary kartici
- [ ] Probaj search, type filter i sort dropdown
- [ ] Uđi u `Select Projects` i potvrdi da bulk akcije ostaju dostupne kroz overflow meni

## 2. Chat editor
- [ ] Otvori `Open Chat Editor`
- [ ] Potvrdi da compact app bar koristi overflow meni za `Open Playback` i `Back to Projects`
- [ ] Potvrdi da je scene selector upotrebljiv na uskoj širini
- [ ] Otvori scene overflow meni i provjeri `Duplicate Scene` i `Edit Scene Settings`
- [ ] U `Edit Scene Settings` promijeni preset i aspect ratio pa spremi
- [ ] Dodaj ili izmijeni barem jednu poruku
- [ ] U message selection modu potvrdi da stacked `Clear` / `Delete` akcije ostaju klikabilne

## 3. Playback
- [ ] Otvori `Open Playback`
- [ ] Potvrdi da compact app bar koristi overflow meni za `Open Chat Editor` i `Back to Projects`
- [ ] Potvrdi da export kontrole rade u compact layoutu
- [ ] Potvrdi da transport kontrole rade bez overlap/overflow loma
- [ ] Na ~320 px širine provjeri ultra-compact varijantu `Play/Pause`, `Restart`, seek i cue gumba
- [ ] Skrolaj do dna playback ekrana i potvrdi da `Open Chat Editor` otvara editor, a `Back to Projects` vraća na listu projekata
- [ ] Promijeni scenu i potvrdi da se progress resetira na novu scenu
- [ ] Promijeni ratio između `9:16` i `16:9` bez gubitka playback stanja

## 4. Export i feedback
- [ ] Klikni `Export Screenshot`
- [ ] Klikni `Export Video`
- [ ] Potvrdi da su success/fallback poruke jasne i da layout ne puca nakon snackbara

## 5. Release gate
Compact layout se može smatrati spremnim za beta pass ako:
- [ ] nema overflow exceptiona ili vizualnih lomova na ~390 px
- [ ] ultra-compact playback ostaje upravljiv na ~320 px
- [ ] project list, editor i playback flow možeš proći bez blokera
