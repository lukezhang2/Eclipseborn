#!/usr/bin/env bash
## Install Godot 4.3 + web export templates if missing. Idempotent.
set -euo pipefail

GODOT_VERSION="4.3"
GODOT_TAG="4.3-stable"
INSTALL_DIR="${GODOT_INSTALL_DIR:-/usr/local}"
BIN="${INSTALL_DIR}/bin/godot"
TEMPLATES_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable"

link_godot() {
	if command -v godot >/dev/null 2>&1; then
		return 0
	fi
	if [[ -x "$BIN" ]]; then
		sudo mkdir -p /usr/local/bin
		# Avoid "same file" error when BIN is already /usr/local/bin/godot
		if [[ "$(readlink -f "$BIN" 2>/dev/null || echo "$BIN")" != "$(readlink -f /usr/local/bin/godot 2>/dev/null || true)" ]]; then
			sudo ln -sfn "$BIN" /usr/local/bin/godot || sudo cp -f "$BIN" /usr/local/bin/godot
		fi
	fi
}

has_templates() {
	[[ -f "${TEMPLATES_DIR}/web_release.zip" ]] || [[ -f "${TEMPLATES_DIR}/web_nothreads_release.zip" ]]
}

if command -v godot >/dev/null 2>&1 && has_templates; then
	echo "Godot ready: $(godot --version 2>/dev/null || true)"
	exit 0
fi

# Partial install: binary present, templates missing (or vice versa)
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if ! command -v godot >/dev/null 2>&1 && [[ ! -x "$BIN" ]]; then
	echo "Downloading Godot ${GODOT_TAG}…"
	curl -fsSL -o "$TMP/godot.zip" \
		"https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_TAG}_linux.x86_64.zip"
	unzip -qo "$TMP/godot.zip" -d "$TMP/godot"
	sudo mkdir -p "${INSTALL_DIR}/bin"
	sudo cp "$TMP/godot/Godot_v${GODOT_TAG}_linux.x86_64" "$BIN"
	sudo chmod +x "$BIN"
fi

link_godot

if ! has_templates; then
	echo "Downloading export templates…"
	curl -fsSL -o "$TMP/templates.tpz" \
		"https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_TAG}_export_templates.tpz"
	mkdir -p "$TEMPLATES_DIR"
	unzip -qo "$TMP/templates.tpz" -d "$TMP/templates"
	cp -R "$TMP/templates/templates/"* "$TEMPLATES_DIR/"
fi

link_godot
if ! command -v godot >/dev/null 2>&1; then
	echo "ERROR: godot not on PATH after install" >&2
	exit 1
fi
echo "Godot installed: $(godot --version)"
