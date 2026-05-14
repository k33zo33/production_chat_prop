#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_INPUT="${1:-web}"

if [[ "$TARGET_INPUT" = /* ]]; then
  TARGET_DIR="$TARGET_INPUT"
else
  TARGET_DIR="$ROOT_DIR/$TARGET_INPUT"
fi

INDEX_PATH="$TARGET_DIR/index.html"
MANIFEST_PATH="$TARGET_DIR/manifest.json"
FAVICON_PATH="$TARGET_DIR/favicon.png"

if [[ ! -f "$INDEX_PATH" ]]; then
  echo "[web-shell-smoke] missing index.html: $INDEX_PATH" >&2
  exit 1
fi

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "[web-shell-smoke] missing manifest.json: $MANIFEST_PATH" >&2
  exit 1
fi

if [[ ! -f "$FAVICON_PATH" ]]; then
  echo "[web-shell-smoke] missing favicon.png: $FAVICON_PATH" >&2
  exit 1
fi

python3 - "$TARGET_DIR" "$INDEX_PATH" "$MANIFEST_PATH" <<'PY'
import json
import pathlib
import re
import sys

_, target_dir_raw, index_path_raw, manifest_path_raw = sys.argv

target_dir = pathlib.Path(target_dir_raw)
index_path = pathlib.Path(index_path_raw)
manifest_path = pathlib.Path(manifest_path_raw)
index_html = index_path.read_text(encoding='utf-8')
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))

forbidden_brand_pattern = re.compile(
    r'\b(whatsapp|telegram|instagram|messenger|imessage)\b',
    re.IGNORECASE,
)

combined_copy = '\n'.join([
    index_html,
    json.dumps(manifest, ensure_ascii=False),
])

if forbidden_brand_pattern.search(combined_copy):
    match = forbidden_brand_pattern.search(combined_copy)
    raise SystemExit(
        '[web-shell-smoke] brand-neutrality check failed: '
        f'found forbidden brand reference "{match.group(0)}"'
    )


def require(pattern: str, label: str) -> re.Match[str]:
    match = re.search(pattern, index_html, flags=re.IGNORECASE)
    if not match:
        raise SystemExit(f'[web-shell-smoke] missing {label} in {index_path}')
    return match


title = require(r'<title>\s*([^<]+?)\s*</title>', 'document title').group(1).strip()
if title != 'Production Chat Prop':
    raise SystemExit(
        '[web-shell-smoke] unexpected document title: '
        f'{title!r} (expected "Production Chat Prop")'
    )

apple_title = require(
    r'<meta\s+name="apple-mobile-web-app-title"\s+content="([^"]+)"',
    'apple-mobile-web-app-title meta',
).group(1).strip()
if apple_title != 'Production Chat Prop':
    raise SystemExit(
        '[web-shell-smoke] unexpected apple-mobile-web-app-title: '
        f'{apple_title!r}'
    )

meta_description = require(
    r'<meta\s+name="description"\s+content="([^"]+)"',
    'description meta',
).group(1).strip()
if 'production-safe' not in meta_description.lower():
    raise SystemExit(
        '[web-shell-smoke] description meta should reinforce production-safe positioning'
    )

meta_theme = require(
    r'<meta\s+name="theme-color"\s+content="([^"]+)"',
    'theme-color meta',
).group(1).strip()

apple_touch_icon = require(
    r'<link\s+rel="apple-touch-icon"\s+href="([^"]+)"',
    'apple-touch-icon link',
).group(1).strip()
if not (target_dir / apple_touch_icon).is_file():
    raise SystemExit(
        '[web-shell-smoke] missing apple-touch-icon asset: '
        f'{target_dir / apple_touch_icon}'
    )

if manifest.get('name') != 'Production Chat Prop':
    raise SystemExit(
        '[web-shell-smoke] unexpected manifest name: '
        f'{manifest.get("name")!r}'
    )

short_name = str(manifest.get('short_name', '')).strip()
if not short_name:
    raise SystemExit('[web-shell-smoke] manifest short_name must not be blank')

if manifest.get('display') != 'standalone':
    raise SystemExit(
        '[web-shell-smoke] manifest display must stay standalone '
        f'(got {manifest.get("display")!r})'
    )

if manifest.get('orientation') != 'portrait-primary':
    raise SystemExit(
        '[web-shell-smoke] manifest orientation must stay portrait-primary '
        f'(got {manifest.get("orientation")!r})'
    )

manifest_theme = str(manifest.get('theme_color', '')).strip()
if manifest_theme != meta_theme:
    raise SystemExit(
        '[web-shell-smoke] theme-color mismatch between index.html and manifest.json '
        f'({meta_theme!r} vs {manifest_theme!r})'
    )

icons = manifest.get('icons') or []
if not icons:
    raise SystemExit('[web-shell-smoke] manifest must declare icons')

for icon in icons:
    src = str(icon.get('src', '')).strip()
    if not src:
        raise SystemExit('[web-shell-smoke] manifest icon src must not be blank')
    icon_path = target_dir / src
    if not icon_path.is_file():
        raise SystemExit(
            '[web-shell-smoke] missing manifest icon asset: '
            f'{icon_path}'
        )

print(f'[web-shell-smoke] validated shell metadata in {target_dir}')
print(f'[web-shell-smoke] title: {title}')
print(f'[web-shell-smoke] short_name: {short_name}')
print(f'[web-shell-smoke] theme: {meta_theme}')
print(f'[web-shell-smoke] icons: {len(icons)}')
PY

echo "[web-shell-smoke] done"
