#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "$#" -gt 0 ]]; then
  TARGETS=("$@")
else
  TARGETS=("lib" "web")
fi

python3 - "$ROOT_DIR" "${TARGETS[@]}" <<'PY'
import pathlib
import re
import sys

_, root_raw, *target_args = sys.argv

root_dir = pathlib.Path(root_raw)
targets = [pathlib.Path(target) for target in target_args]

forbidden_brand_pattern = re.compile(
    r'\b(whatsapp|telegram|instagram|messenger|imessage)\b',
    re.IGNORECASE,
)
raw_text_extensions = {'.html', '.json', '.css', '.js', '.txt'}
text_extensions = raw_text_extensions | {'.dart'}


def iter_dart_string_literals(text: str):
    i = 0
    length = len(text)

    while i < length:
        raw_literal = False
        start = i

        if text[i] in 'rR' and i + 1 < length and text[i + 1] in {'"', "'"}:
            raw_literal = True
            i += 1
        elif text[i] not in {'"', "'"}:
            i += 1
            continue

        quote = text[i]
        triple = text.startswith(quote * 3, i)
        i += 3 if triple else 1
        content_start = i

        while i < length:
            if triple:
                if text.startswith(quote * 3, i):
                    yield start, text[content_start:i]
                    i += 3
                    break
                i += 1
                continue

            if not raw_literal and text[i] == '\\':
                i += 2
                continue

            if text[i] == quote:
                yield start, text[content_start:i]
                i += 1
                break

            i += 1


def normalize_path(path: pathlib.Path) -> pathlib.Path:
    return path if path.is_absolute() else root_dir / path


violations: list[str] = []
scanned_files = 0
skipped_targets: list[str] = []

for target in targets:
    target_path = normalize_path(target)
    if not target_path.exists():
        skipped_targets.append(str(target))
        continue

    scan_paths = [target_path] if target_path.is_file() else sorted(
        path for path in target_path.rglob('*') if path.is_file()
    )

    for path in scan_paths:
        if path.suffix.lower() not in text_extensions:
            continue

        try:
            text = path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue

        scanned_files += 1
        relative_path = path.relative_to(root_dir)

        if path.suffix.lower() == '.dart':
            # Keep Dart scanning focused on user-facing copy in string literals.
            # Comments stay out of scope to avoid noisy false positives.
            for offset, literal in iter_dart_string_literals(text):
                match = forbidden_brand_pattern.search(literal)
                if match is None:
                    continue
                line = text.count('\n', 0, offset) + 1
                snippet = ' '.join(literal.strip().split())
                violations.append(
                    f'{relative_path}:{line}: string literal contains forbidden brand '
                    f'{match.group(0)!r}: {snippet[:160]}'
                )
            continue

        if path.suffix.lower() in raw_text_extensions:
            for line_number, line in enumerate(text.splitlines(), start=1):
                match = forbidden_brand_pattern.search(line)
                if match is None:
                    continue
                violations.append(
                    f'{relative_path}:{line_number}: text contains forbidden brand '
                    f'{match.group(0)!r}: {line.strip()[:160]}'
                )

if violations:
    joined = '\n'.join(violations)
    raise SystemExit(
        '[brand-neutrality-smoke] brand-safe copy check failed:\n'
        f'{joined}'
    )

scanned_targets = ', '.join(str(target) for target in targets)
print(f'[brand-neutrality-smoke] validated {scanned_files} text files across: {scanned_targets}')
if skipped_targets:
    print(
        '[brand-neutrality-smoke] skipped missing targets: '
        + ', '.join(skipped_targets)
    )
print('[brand-neutrality-smoke] no forbidden messaging-brand copy found in scanned app surfaces')
PY

echo "[brand-neutrality-smoke] done"
