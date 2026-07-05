#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="TileManager"
SOURCE_APP="$ROOT_DIR/.build/$APP_NAME.app"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/$APP_NAME.app"

"$ROOT_DIR/scripts/build-app.sh" >/dev/null

pkill -x "$APP_NAME" 2>/dev/null || true
mkdir -p "$DEST_DIR"
rm -rf "$DEST_APP"
ditto "$SOURCE_APP" "$DEST_APP"
codesign --verify --deep --strict "$DEST_APP"
open "$DEST_APP"

echo "$DEST_APP"
