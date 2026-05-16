#!/usr/bin/env bash
set -euo pipefail

display="${DISPLAY:-:99}"
geometry="${VNC_GEOMETRY:-1440x900x24}"
vnc_port="${VNC_PORT:-5900}"
novnc_port="${NOVNC_PORT:-6080}"

cleanup() {
  jobs -pr | xargs -r kill
}
trap cleanup EXIT

mkdir -p "$HOME/.config" "$HOME/.cache"
mkdir -p -m 700 /tmp/runtime-appuser
export DISPLAY="$display"
export XDG_RUNTIME_DIR=/tmp/runtime-appuser

Xvfb "$display" -screen 0 "$geometry" -nolisten tcp -ac >/tmp/xvfb.log 2>&1 &
until xdpyinfo -display "$display" >/dev/null 2>&1; do
  sleep 0.2
done

fluxbox >/tmp/fluxbox.log 2>&1 &
x11vnc \
  -display "$display" \
  -forever \
  -listen 0.0.0.0 \
  -nopw \
  -rfbport "$vnc_port" \
  -shared \
  -xkb \
  >/tmp/x11vnc.log 2>&1 &

websockify \
  --web=/usr/share/novnc \
  "0.0.0.0:${novnc_port}" \
  "localhost:${vnc_port}" \
  >/tmp/novnc.log 2>&1 &

echo "Production Chat Prop desktop is starting."
echo "Open noVNC at http://localhost:${novnc_port}/vnc.html?host=localhost&port=${novnc_port}&autoconnect=true&resize=remote"

exec /app/production_chat_prop "$@"
