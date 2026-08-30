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
- `10-ai-helper-workflow.md` — Gemini read-only helper workflow, `doctor` preflight i lokalni `preview-ask` / `preview-review` debug path
- `tool/demo_smoke.sh` — brzi demo-flow preflight za seedani showcase put kroz project list, editor i playback
- `tool/release_smoke.sh` — fokusirani export/reliability/focus-preview preflight prije punog verify i rucnog browser passa
- `tool/compact_smoke.sh` — fokusirani compact/mobile preflight za narrow layout, overflow akcije i export kontrole
- `tool/import_smoke.sh` — brzi import/recovery/stale-state preflight za JSON handoff i project recovery tokove
- `tool/brand_neutrality_smoke.sh` — sken user-facing copyja i build outputa za zabranjene reference na stvarne messaging brandove
- `tool/navigation_smoke.sh` — brzi deep-link, stale-query i recovery navigation preflight prije skupljeg verify koraka
- `tool/manual_beta_checklist.sh` — zajednicki rucni browser/compact/export handoff redoslijed s fixture i video-workflow podsjetnikom
- `tool/desktop_smoke.sh` — zaseban Docker desktop packaging/noVNC smoke gate koji ne mijesa desktop fallback provjeru u glavni web handoff red
- `tool/web_shell_smoke.sh` — brzi source/build web shell metadata, icon i brand-copy preflight za `web/` i `build/web`
- `tool/docs_handoff_smoke.sh` — brzi docs/checklist/workflow drift preflight za release handoff redoslijed i guardrailove
- `tool/ai_helper_smoke.sh` — mali lokalni smoke pass za helper wrapper parsing i fallback ponašanje
- `tool/beta_handoff_smoke.sh` — brzi shell-level smoke za `beta_handoff.sh` orchestration redoslijed i skip-flag wiring bez pravog Flutter stacka
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
- Ako diraš demo seed ili showcase flow, pokreni `./tool/demo_smoke.sh` prije skupljeg Flutter gatea.
- Ako diraš export, playback reliability ili focus-preview ponasanje, pokreni `./tool/release_smoke.sh` prije punog verify i rucnog browser passa.
- Ako diraš compact/mobile layout, overflow akcije ili narrow playback kontrole, pokreni `./tool/compact_smoke.sh` prije punog verify koraka.
- Ako diraš import/export handoff, stale route recovery ili project JSON flow, pokreni `./tool/import_smoke.sh` prije skupljeg Flutter gatea.
- Ako diraš user-facing copy, branding ili build output copy, pokreni `./tool/brand_neutrality_smoke.sh lib web`, a po potrebi i `./tool/brand_neutrality_smoke.sh build/web`.
- Ako diraš scene routing, deep-link query ili recovery navigation ponašanje, pokreni `./tool/navigation_smoke.sh` prije punog verify koraka.
- Ako diraš Docker desktop fallback ili noVNC packaging flow, pokreni `./tool/desktop_smoke.sh` kao odvojeni gate umjesto da se oslanjaš samo na web handoff.
- Ako diraš `web/`, manifest, favicon, title/meta copy ili built web shell output, pokreni `./tool/web_shell_smoke.sh web` i po potrebi `./tool/web_shell_smoke.sh build/web`.
- Ako diraš handoff docs, CI redoslijed ili smoke gate wiring, prvo pokreni `./tool/docs_handoff_smoke.sh` da uhvati docs/checklist/workflow drift prije skupljeg Flutter gatea.
- Ako diraš `tool/beta_handoff.sh`, prvo pokreni `./tool/beta_handoff_smoke.sh` da provjeriš orchestration redoslijed i skip-flag wiring prije skupljeg Flutter gatea.
- `release_smoke` i `compact_smoke` nisu samo name-check gateovi: dedicated focused test fileovi koje u potpunosti posjeduju sada failaju i na coverage drift, pa tiha erozija handoff zaštite teže prolazi.
- Za helper/review workflow: kreni s `./tool/ai_helper.sh doctor`, za payload debug koristi `./tool/ai_helper.sh preview-ask ...` ili `./tool/ai_helper.sh preview-review ...`, a kad diraš wrapper pokreni i `./tool/ai_helper_smoke.sh`, zatim vidi `10-ai-helper-workflow.md`

## Notes
- Helper workflow je Gemini-only dok se ne odluči drugačije; starije Claude reference treba tretirati kao povijesne ili overridane novijim pravilima.
- `Export Video` u trenutnom beta MVP-u i dalje znači dokumentirani `.json` handoff paket, ne finalni encoded video render.
