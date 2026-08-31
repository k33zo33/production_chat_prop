#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COMPOSE_FILE="${DESKTOP_SMOKE_COMPOSE_FILE:-docker-compose.desktop.yml}"
if [[ "$COMPOSE_FILE" = /* ]]; then
  COMPOSE_PATH="$COMPOSE_FILE"
else
  COMPOSE_PATH="$ROOT_DIR/$COMPOSE_FILE"
fi

if [[ ! -f "$COMPOSE_PATH" ]]; then
  echo "[desktop-docker] missing compose file: $COMPOSE_PATH" >&2
  exit 1
fi

docker compose -f "$COMPOSE_FILE" up --build
