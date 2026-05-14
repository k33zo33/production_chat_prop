# AI Helper Workflow

Ovaj projekt koristi **Claude CLI** i **Gemini CLI** kao read-only helper alate.

## Osnovno pravilo
- Za helper analizu i review **ne koristi MCP kao default path**.
- Preferirani način je direktni CLI poziv u read-only modu.
- Oba helpera služe za analizu, review, debugging i drugi pogled prije odluke.
- Nijedan helper ne smije pisati, editirati, commitati ni pushati kod.

## Kada koristiti helpere

### 1. Prije svakog commita
Obavezno pokrenuti zajednički review trenutnog diffa:

```bash
./tool/ai_helper.sh review
```

Ako želiš review specifičnog raspona diffa:

```bash
./tool/ai_helper.sh review origin/main...HEAD
```

Očekivani workflow:
1. napravi slice
2. pokreni lokalnu verifikaciju
3. ako želiš review točno onoga što planiraš commitati, prvo stageaj diff (`git add -A` ili ciljane fileove)
4. pokreni `./tool/ai_helper.sh review`
5. usporedi Claude i Gemini nalaze
6. primijeni koristan feedback
7. odluči je li diff spreman za commit

Napomena:
- Kad **nema staged promjena**, `review` automatski uključuje tracked working-tree diff **i untracked fileove**.
- Kad **ima staged promjena**, default review ostaje fokusiran na staged diff kao commit kandidat.

### 2. Kad zapneš
Za read-only pomoć ili drugi pogled koristi:

```bash
./tool/ai_helper.sh ask "Tvoje pitanje ovdje"
```

Primjeri:

```bash
./tool/ai_helper.sh ask "Pregledaj playback export pristup i reci koji je najsigurniji sljedeći korak."
./tool/ai_helper.sh ask "Pogledaj ovu arhitekturu i reci postoji li jednostavniji način bez scope creepa."
```

## Tehnički detalji
- Claude CLI se pokreće non-interactive preko `claude -p`
- Claude radi u `--permission-mode plan` i ograničen je na `Read,Grep,Glob` alate
- Gemini CLI se pokreće non-interactive preko `gemini -p ''` uz payload preko stdin-a
- Gemini radi u `--approval-mode plan`
- Wrapper skripta ispisuje Claude i Gemini sekcije odvojeno radi lakše usporedbe
- Ako jedan helper faila, nije instaliran, ili istekne timeout, wrapper nastavlja s drugim helperom
- Timeout se može podesiti preko `HELPER_TIMEOUT_SECONDS` varijable okoline
- Prompt payload se helperima šalje preko stdin-a kako veliki diffovi ne bi padali na shell `ARG_MAX` limit
- Claude u oba moda dobiva `--add-dir` pristup za read-only čitanje repoa, dok Gemini odgovara samo na temelju prompt payload-a
- Za untracked fileove skripta generira patch-style pregled (`git diff --no-color --no-ext-diff --no-index`) tako da review ne preskoči nove datoteke
- Za binarne untracked fileove skripta preskače raw patch i zadržava samo stat sažetak da review ostane čitljiv

## Pravila odlučivanja
- Claude i Gemini su helperi, ne autori odluke.
- Ako se slažu i nalaz je razuman, primijeni ga.
- Ako se razilaze, preferiraj:
  1. product docs
  2. repo kontekst i test evidence
  3. manji i sigurniji diff
- Ako helper traži dodatni kontekst ili postavi follow-up pitanje koje stvarno blokira odluku, stani i eskaliraj korisniku.

## Što nije dozvoljeno
- Ne koristiti helpere za automatsko pisanje koda u ovom workflowu.
- Ne ulaziti u beskonačne petlje review -> follow-up -> review.
- Ne tretirati helper nalaz kao zamjenu za `flutter analyze`, `flutter test`, `./tool/release_smoke.sh` ili `./tool/verify.sh`.
