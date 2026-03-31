#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_BIN="${FLUTTER_BIN:-/home/server/flutter/bin/flutter}"

echo "[demo-smoke] using flutter: $FLUTTER_BIN"
"$FLUTTER_BIN" --version

echo "[demo-smoke] analyze"
"$FLUTTER_BIN" analyze

echo "[demo-smoke] targeted widget tests"
"$FLUTTER_BIN" test --plain-name "add demo project action seeds prefilled project"
"$FLUTTER_BIN" test --plain-name "create project and navigate to chat editor from project card"
"$FLUTTER_BIN" test --plain-name "create project and navigate to playback from project card"
"$FLUTTER_BIN" test --plain-name "project popup copy json writes clipboard and shows feedback"
"$FLUTTER_BIN" test --plain-name "project popup download json shows fallback feedback on unsupported platform"
"$FLUTTER_BIN" test --plain-name "import project json dialog adds new project card"
"$FLUTTER_BIN" test --plain-name "import json file button shows fallback when no file is selected"
"$FLUTTER_BIN" test --plain-name "video export button shows fallback package feedback"

echo
echo "[demo-smoke] manual demo checklist"
echo "1) Run app: $FLUTTER_BIN run -d web-server"
echo "2) Create or load demo project from empty state"
echo "3) Open Chat Editor, tweak one message, return to Projects"
echo "4) Open project card menu and try Copy JSON / Download JSON"
echo "5) Import that payload with Import Project JSON (paste or file picker)"
echo "6) Open Playback, verify controls + export feedback"
echo "7) Optional: follow docs/04-export-qa-checklist.md"

echo "[demo-smoke] done"
