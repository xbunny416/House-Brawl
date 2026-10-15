#!/usr/bin/env bash
# Strict type-check of src/ with luau-lsp, using Roblox API definitions and the Rojo sourcemap.
# Usage: scripts/typecheck.sh   (set LUAU_DEFS to reuse an already-downloaded definitions file)
set -euo pipefail

LUAU_LSP_VERSION="1.70.1" # keep in sync with rokit.toml
DEFS="${LUAU_DEFS:-build/globalTypes.None.d.luau}"

if [ ! -f "$DEFS" ]; then
	mkdir -p "$(dirname "$DEFS")"
	curl -fsSL "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/${LUAU_LSP_VERSION}/scripts/globalTypes.None.d.luau" \
		-o "$DEFS"
fi

rojo sourcemap default.project.json --output sourcemap.json
luau-lsp analyze \
	--platform=roblox \
	--definitions="@roblox=$DEFS" \
	--sourcemap=sourcemap.json \
	--base-luaurc=.luaurc \
	--ignore="**/Vendor/**" \
	src
