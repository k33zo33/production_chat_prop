# VS Code setup i workflow

## Kratka preporuka
Za ovaj projekt kreni s **jednim folderom / jednim git repozitorijem**.

### Nemoj odmah raditi multi-root workspace ako nemaš razlog
Za jednu Flutter aplikaciju je najbolje:
1. napraviti novi folder `production_chat_prop`
2. otvoriti taj folder u VS Codeu
3. unutar njega držati `lib/`, `test/`, `docs/` i ostale projektne datoteke

**Workspace file** ima smisla tek ako kasnije dodaš:
- zaseban landing page projekt
- backend servis
- asset pipeline ili tools repo
- više povezanih repozitorija odjednom

## Preporučena struktura root foldera
```text
production_chat_prop/
  docs/
    01-product-spec-mvp.md
    02-technical-architecture-flutter.md
    03-roadmap-and-sprints.md
    04-codex-master-prompt.md
  lib/
  test/
  web/
  pubspec.yaml
  analysis_options.yaml
  README.md
```

## Najbolji workflow s Codexom
1. Napravi novi folder i inicijaliziraj git repo.
2. Kopiraj dokumente u `docs/`.
3. Otvori cijeli folder u VS Codeu.
4. Pokreni Codex unutar tog foldera.
5. Zalijepi sadržaj iz `04-codex-master-prompt.md`.
6. Pusti Codex da generira osnovni skeleton projekta.
7. Pregledaj diff prije prihvaćanja.
8. Pokreni lokalno app i tek onda traži sljedeći sprint.

## Što Codex može napraviti dobro
- napraviti Flutter bootstrap
- složiti strukturu foldera
- generirati modele i osnovne providere
- generirati početne widgete i stranice
- napisati test skeleton

## Što ti trebaš držati pod kontrolom
- scope proizvoda
- arhitekturu
- naziv i granice featurea
- UX prioritete
- pravne i vizualne smjernice

## Konkretne terminal komande
```bash
flutter create production_chat_prop
cd production_chat_prop
git init
mkdir docs
```

Nakon toga kopiraj dokumente u `docs/` i kreni s Codex promptom.

## Moj preporučeni način rada
- **Folder first**
- **Git repo odmah**
- **Docs u root/docs**
- **Codex koristiš kao implementatora, ne kao product ownera**

## Pravilo za svaki veći korak
Za svaku veću fazu daj Codexu:
- jedan jasan cilj
- relevantni dio dokumentacije
- ograničenja što ne smije dirati
- traženi output po datotekama
