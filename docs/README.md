# Production Chat Prop — starter paket za Codex

Ovaj paket je pripremljen kao ulaz za AI coding asistenta i kao početna dokumentacija za novi Flutter projekt.

## Što je unutra
- `01-product-spec-mvp.md` — proizvodna specifikacija MVP-a
- `02-technical-architecture-flutter.md` — tehnička arhitektura i odluke
- `03-roadmap-and-sprints.md` — faze rada i sprintovi
- `04-codex-master-prompt.md` — glavni prompt koji zalijepiš u Codex
- `04-export-qa-checklist.md` — ručna QA checklista za export flow
- `05-vscode-setup-and-workflow.md` — preporučeni način rada u VS Codeu
- `06-product-description.md` — landing/product copy draft za prezentaciju
- `07-demo-script.md` — koraci za 2-3 minute produkt demo walkthrough
- `production-chat-prop.code-workspace` — opcionalni workspace file za VS Code

## Preporučeni redoslijed
1. Napravi novi folder/repo: `production_chat_prop`
2. Kopiraj ove dokumente u root projekta ili u `docs/`
3. Otvori folder u VS Codeu
4. Pokreni Codex i prvo mu daj sadržaj iz `04-codex-master-prompt.md`
5. Nakon što generira skeleton, radi po sprintovima iz `03-roadmap-and-sprints.md`

## Napomena
Za jedan Flutter app **ne trebaš** odmah poseban multi-root VS Code workspace. Dovoljan je jedan folder. Workspace file je uključen kao opcija ako kasnije dodaš landing page, backend ili asset pipeline.
