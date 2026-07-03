#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_DIR="$ROOT_DIR/CodexCatStatus.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
PKGINFO="$CONTENTS_DIR/PkgInfo"
BUILD_DIR="$ROOT_DIR/.build"
MODULE_CACHE_DIR="$BUILD_DIR/module-cache"

mkdir -p "$MACOS_DIR"
mkdir -p "$MODULE_CACHE_DIR"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CodexCatStatus</string>
  <key>CFBundleIdentifier</key>
  <string>local.codex.cat.status</string>
  <key>CFBundleName</key>
  <string>Codex Cat Status</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

printf 'APPL????' > "$PKGINFO"

swiftc -O -framework AppKit \
  -module-cache-path "$MODULE_CACHE_DIR" \
  "$ROOT_DIR/CodexCatStatus.swift" \
  -o "$MACOS_DIR/CodexCatStatus"

echo "Built $APP_DIR"
