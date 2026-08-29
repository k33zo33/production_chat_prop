# Production Chat Prop docs

Ovo je aktivni dokumentacijski indeks za trenutni `production_chat_prop` repo, ne više samo starter paket za novi scaffold.

## Core product docs
- `01-product-spec-mvp.md` — MVP scope, use-caseovi i product pravila
- `02-technical-architecture-flutter.md` — arhitektura, feature split i release pristup
- `03-roadmap-and-sprints.md` — sprint plan i scope guardrails

## Beta / release docs
- `04-export-qa-checklist.md` — ručni export QA pass
- `05-web-done-checklist.md` — trenutni web MVP status i release gate pregled
- `06-product-description.md` — kratki product/landing copy draft
- `07-demo-script.md` — 2-3 minute demo walkthrough
- `08-web-smoke-checklist.md` — kratki browser smoke pass
- `09-compact-smoke-checklist.md` — compact/mobile smoke pass
- `11-video-fallback-workflow.md` — objašnjenje trenutnog `Export Video` JSON handoff workflowa

## Developer workflow docs
- `04-codex-master-prompt.md` — historical prompt/bootstrap reference
- `05-vscode-setup-and-workflow.md` — editor/workstation workflow notes
- `10-ai-helper-workflow.md` — Gemini read-only helper workflow, wrapper ponašanje i `./tool/ai_helper.sh doctor` preflight
- `tool/ai_helper_smoke.sh` — mali lokalni smoke pass za helper wrapper parsing i fallback ponašanje
- `production-chat-prop.code-workspace` — opcionalni VS Code workspace file

## Recommended reading order
1. `01-product-spec-mvp.md`
2. `02-technical-architecture-flutter.md`
3. `03-roadmap-and-sprints.md`
4. `05-web-done-checklist.md`
5. relevant smoke / QA checklist for the slice you are touching

## Practical usage
- Za product odluke: kreni od `01` + `03`
- Za arhitekturu i repo wiring: kreni od `02`
- Za beta handoff/release provjeru: kreni od `05`, zatim pokreni `./tool/manual_beta_checklist.sh`, pa odradi `08`, `09`, `04`, `11`
- Za helper/review workflow: kreni s `./tool/ai_helper.sh doctor`, a kad diraš wrapper pokreni i `./tool/ai_helper_smoke.sh`, zatim vidi `10-ai-helper-workflow.md`

## Notes
- Helper workflow je Gemini-only dok se ne odluči drugačije; starije Claude reference treba tretirati kao povijesne ili overridane novijim pravilima.
- `Export Video` u trenutnom beta MVP-u i dalje znači dokumentirani `.json` handoff paket, ne finalni encoded video render.
