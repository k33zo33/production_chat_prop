#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COMPOSE_FILE="${DESKTOP_SMOKE_COMPOSE_FILE:-docker-compose.desktop.yml}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
NOVNC_PATH="${DESKTOP_SMOKE_PATH:-/vnc.html?host=localhost&port=${NOVNC_PORT}&autoconnect=true&resize=remote}"
NOVNC_URL="${DESKTOP_SMOKE_URL:-http://localhost:${NOVNC_PORT}${NOVNC_PATH}}"
MAX_ATTEMPTS="${DESKTOP_SMOKE_MAX_ATTEMPTS:-20}"
SLEEP_SECONDS="${DESKTOP_SMOKE_SLEEP_SECONDS:-2}"
SERVICE_NAME="${DESKTOP_SMOKE_SERVICE:-desktop}"

cleanup() {
  docker compose -f "$COMPOSE_FILE" down >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[desktop-smoke] compose config"
docker compose -f "$COMPOSE_FILE" config >/dev/null

echo "[desktop-smoke] build + boot"
docker compose -f "$COMPOSE_FILE" up --build -d

echo "[desktop-smoke] wait for noVNC: $NOVNC_URL"
for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
  if python3 - "$NOVNC_URL" <<'PY'
import sys
import urllib.request

url = sys.argv[1]

try:
    with urllib.request.urlopen(url, timeout=10) as response:
        body = response.read(4096).decode('utf-8', 'ignore')
        if response.status != 200 or 'noVNC' not in body:
            raise SystemExit(1)
except Exception:
    raise SystemExit(1)
PY
  then
    echo "[desktop-smoke] noVNC responded on attempt ${attempt}/${MAX_ATTEMPTS}"
    if ! docker compose -f "$COMPOSE_FILE" ps --services --status running | grep -Fxq "$SERVICE_NAME"; then
      echo "[desktop-smoke] service is not running after noVNC became reachable" >&2
      docker compose -f "$COMPOSE_FILE" ps >&2 || true
      docker compose -f "$COMPOSE_FILE" logs --tail=80 "$SERVICE_NAME" >&2 || true
      exit 1
    fi

    docker compose -f "$COMPOSE_FILE" logs --tail=20 "$SERVICE_NAME"
    echo "[desktop-smoke] done"
    exit 0
  fi

  sleep "$SLEEP_SECONDS"
done

echo "[desktop-smoke] noVNC did not become ready in time" >&2
docker compose -f "$COMPOSE_FILE" ps >&2 || true
docker compose -f "$COMPOSE_FILE" logs --tail=80 "$SERVICE_NAME" >&2 || true
exit 1
