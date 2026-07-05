#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="TileManager"
BUNDLE_ID="com.local.TileManager"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
EXECUTABLE="$ROOT_DIR/.build/release/$APP_NAME"

swift build -c release --product "$APP_NAME" --package-path "$ROOT_DIR"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>TileManager uses Accessibility to detect title-bar double-clicks and resize the selected window.</string>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
PLIST

SIGNING_IDENTITY="${TILEMANAGER_CODESIGN_IDENTITY:-}"
if [[ -z "$SIGNING_IDENTITY" ]]; then
    SIGNING_IDENTITY="$(
        security find-identity -v -p codesigning 2>/dev/null \
            | sed -n 's/.*"\(.*\)".*/\1/p' \
            | head -n 1
    )"
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
    SIGNING_IDENTITY="-"
    echo "Signing $APP_NAME with ad-hoc identity"
else
    echo "Signing $APP_NAME with identity: $SIGNING_IDENTITY"
fi

codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_DIR"
echo "$APP_DIR"
