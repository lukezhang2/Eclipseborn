#!/usr/bin/env bash
## Ensure Godot, export Web, cache-bust the .pck so GitHub Pages/browsers pick up new builds.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash "$ROOT/tools/ensure-godot.sh"

VERSION="$(rg -o 'config/version="([^"]+)"' -r '$1' project.godot | head -1 || true)"
if [[ -z "${VERSION}" ]]; then
	VERSION="0.0.0"
fi
SAFE_VER="${VERSION//./_}"
PACK_NAME="index-${SAFE_VER}.pck"

echo "Exporting Web build for version ${VERSION}…"
godot --headless --path "$ROOT" --import
godot --headless --path "$ROOT" --export-release "Web" "$ROOT/index.html"

if [[ ! -f "$ROOT/index.pck" ]]; then
	echo "ERROR: index.pck missing after export" >&2
	exit 1
fi

cp -f "$ROOT/index.pck" "$ROOT/$PACK_NAME"
PCK_SIZE="$(wc -c < "$ROOT/$PACK_NAME" | tr -d ' ')"
WASM_SIZE=0
if [[ -f "$ROOT/index.wasm" ]]; then
	WASM_SIZE="$(wc -c < "$ROOT/index.wasm" | tr -d ' ')"
fi

python3 - "$ROOT/index.html" "$PACK_NAME" "$PCK_SIZE" "$WASM_SIZE" "$VERSION" <<'PY'
import re
import sys

html_path, pack_name, pck_size, wasm_size, version = sys.argv[1:6]


def patch_config(block: str) -> str:
	if '"mainPack"' in block:
		block = re.sub(r'"mainPack"\s*:\s*"[^"]*"', f'"mainPack":"{pack_name}"', block)
	else:
		block = block.replace(
			'"executable":"index"',
			f'"executable":"index","mainPack":"{pack_name}"',
			1,
		)
	sizes = f'"{pack_name}":{pck_size}'
	if wasm_size != "0":
		sizes += f',"index.wasm":{wasm_size}'
	block = re.sub(r'"fileSizes"\s*:\s*\{[^}]*\}', f'"fileSizes":{{{sizes}}}', block, count=1)
	return block


text = open(html_path, encoding="utf-8").read()
text = re.sub(r'src="index\.js(\?v=[^"]*)?"', f'src="index.js?v={version}"', text)
text = re.sub(
	r'const GODOT_CONFIG = \{.*?\};',
	lambda m: patch_config(m.group(0)),
	text,
	count=1,
	flags=re.S,
)
if 'http-equiv="Cache-Control"' not in text:
	text = text.replace(
		"</title>",
		'</title>\n\t\t<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />\n'
		'\t\t<meta http-equiv="Pragma" content="no-cache" />\n'
		'\t\t<meta http-equiv="Expires" content="0" />',
		1,
	)
open(html_path, "w", encoding="utf-8").write(text)
print(f"Patched index.html → mainPack={pack_name} v={version} size={pck_size}")
PY

# Drop older versioned packs so the repo stays small.
find "$ROOT" -maxdepth 1 -name 'index-*.pck' ! -name "$PACK_NAME" -print -delete || true

echo "Web export ready: ${PACK_NAME} (v${VERSION})"
