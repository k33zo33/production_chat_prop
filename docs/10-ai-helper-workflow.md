# AI Helper Workflow

Ovaj projekt trenutno koristi **Gemini CLI** kao read-only helper alat.

## Osnovno pravilo
- Za helper analizu i review **ne koristi MCP kao default path**.
- Preferirani način je direktni CLI poziv u read-only modu.
- Helper služi za analizu, review, debugging i drugi pogled prije odluke.
- Helper ne smije pisati, editirati, commitati ni pushati kod.

## Kada koristiti helpere

### 0. Prvo provjeri helper okruženje
Ako helper u ovom okruženju zna biti nedostupan, prvo provjeri lokalni setup:

```bash
./tool/ai_helper.sh doctor
```

To je brzi preflight za:
- `git`
- `timeout`
- `gemini`
- trenutni `HELPER_TIMEOUT_SECONDS`

Ako `doctor` padne, nemoj očekivati da će `review` ili `ask` uspjeti bez popravka lokalnog CLI setupa.

Ako mijenjaš wrapper, brzo potvrdi lokalno ponašanje bez oslanjanja na pravi Gemini CLI:

```bash
./tool/ai_helper_smoke.sh
```

Ako želiš vidjeti točan review payload koji wrapper generira bez poziva prema Gemini backendu:

```bash
./tool/ai_helper.sh preview-review -- tool/ai_helper.sh
```

### 1. Prije svakog commita
Obavezno pokrenuti zajednički review trenutnog diffa:

```bash
./tool/ai_helper.sh review
```

Ako želiš review specifičnog raspona diffa:

```bash
./tool/ai_helper.sh review origin/main...HEAD
```

Ako želiš review samo određenih fileova, ali uz isti default commit-kandidat base (`--cached` kad ima staged promjena, inače `HEAD` + untracked):

```bash
./tool/ai_helper.sh review -- tool/ai_helper.sh docs/10-ai-helper-workflow.md
```

Ako želiš i custom diff range i path filter zajedno:

```bash
./tool/ai_helper.sh review HEAD~1..HEAD -- tool/ai_helper.sh
```

Očekivani workflow:
1. napravi slice
2. pokreni lokalnu verifikaciju
3. ako želiš review točno onoga što planiraš commitati, prvo stageaj diff (`git add -A` ili ciljane fileove)
4. pokreni `./tool/ai_helper.sh review`
5. primijeni koristan feedback ako helper vrati koristan nalaz
6. odluči je li diff spreman za commit

Napomena:
- Kad **nema staged promjena**, `review` automatski uključuje tracked working-tree diff **i untracked fileove**.
- Kad **ima staged promjena**, default review ostaje fokusiran na staged diff kao commit kandidat.
- Kad želiš samo dio tog default kandidata, koristi `review -- <paths...>` umjesto custom diff rangea.
- Kad želiš specifičan range i samo dio tog rangea, koristi `review <diff-range> -- <paths...>`. To je najkorisnije za već commitani range poput `HEAD~1..HEAD`, ne za trenutni staged kandidat.

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
- Gemini CLI se pokreće non-interactive preko `gemini -p ''` uz payload preko stdin-a
- Gemini radi u `--approval-mode plan`
- Timeout se može podesiti preko `HELPER_TIMEOUT_SECONDS` varijable okoline
- Prompt payload se helperu šalje preko stdin-a kako veliki diffovi ne bi padali na shell `ARG_MAX` limit
- Wrapper helper promptu inline-a kratak repo/workflow sažetak (scope, source-of-truth docs, heartbeat prioritet) kako analiza ne bi ovisila o git-ignored lokalnim datotekama poput `AGENTS.md` ili `HEARTBEAT.md`
- Za untracked fileove skripta generira patch-style pregled (`git diff --no-color --no-ext-diff --no-index`) tako da review ne preskoči nove datoteke
- Za binarne untracked fileove skripta preskače raw patch i zadržava samo stat sažetak da review ostane čitljiv
- `./tool/ai_helper_smoke.sh` koristi privremeni git repo kako bi provjerio doctor, staged path-filter review, combined range+path review i clear no-diff failure bez pravog helper backenda
- `preview-review` ispisuje puni review payload lokalno, pa možeš debugirati diff selection / path filtering čak i kad `gemini` nije dostupan
- `doctor` daje brzi signal nedostaje li lokalni `gemini` binary prije nego što review padne tek na kraju slicea
- `review -- <paths...>` sada filtrira isti default staged/HEAD review kandidat, umjesto da tiho promijeni diff base
- `review <diff-range> -- <paths...>` sada podržava i custom range i path filter u istoj komandi
- Ako lokalni Gemini CLI vrati unsupported-client / unsupported-tier grešku, wrapper sada ispisuje jasan hint da treba popraviti lokalni auth/client setup umjesto generičkog faila

## Pravila odlučivanja
- Helper je pomoćni reviewer, ne autor odluke.
- Ako nalaz izgleda razumno, primijeni ga.
- Ako helper nije dostupan ili je lokalni client/auth setup pokvaren, osloni se na product docs, repo kontekst i test evidence dok se helper ne popravi.
- Ako helper traži dodatni kontekst ili postavi follow-up pitanje koje stvarno blokira odluku, stani i eskaliraj korisniku.

## Što nije dozvoljeno
- Ne koristiti helpere za automatsko pisanje koda u ovom workflowu.
- Ne ulaziti u beskonačne petlje review -> follow-up -> review.
- Ne tretirati helper nalaz kao zamjenu za `flutter analyze`, `flutter test`, `./tool/release_smoke.sh` ili `./tool/verify.sh`.
