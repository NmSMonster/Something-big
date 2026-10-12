#!/usr/bin/env bash
# Runs every local quality gate for Tiny Trouble:
#   1. rojo build            - validates default.project.json and produces a place file
#   2. luau-lsp analyze      - strict type check against the Roblox API (needs globalTypes)
#   3. selene                - lint (downloads the Roblox API dump on first run)
#   4. stylua --check        - formatting
#
# Usage: ./scripts/check.sh        (from the tiny-trouble folder)
set -euo pipefail

cd "$(dirname "$0")/.."

LUAU_LSP_VERSION="$(grep -oE 'luau-lsp@[0-9.]+' aftman.toml | head -1 | cut -d@ -f2)"
TYPES_DIR=".luau-types"
TYPES_FILE="$TYPES_DIR/globalTypes.d.luau"

echo "==> rojo build"
rojo build default.project.json -o build/TinyTrouble.rbxlx
rojo sourcemap default.project.json -o sourcemap.json

echo "==> luau-lsp analyze"
mkdir -p "$TYPES_DIR"
if [ ! -f "$TYPES_FILE" ]; then
  echo "    downloading Roblox API types for luau-lsp $LUAU_LSP_VERSION"
  curl -fsSL "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$LUAU_LSP_VERSION/scripts/globalTypes.None.d.luau" -o "$TYPES_FILE"
fi
luau-lsp analyze --sourcemap=sourcemap.json --definitions="$TYPES_FILE" src

echo "==> selene"
selene src

echo "==> stylua --check"
stylua --check src

echo "All checks passed."
