#!/bin/bash
# Builds a 100% portable Mac .app with no external dependencies.
# The app embeds a WebView and your HTML — no browser required.
# Requires: Xcode Command Line Tools (xcode-select --install) or Xcode.

set -e
APP_NAME="JSON Diff v4"
BINARY_NAME="JSONDeepDiff"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
RESOURCES="$APP_DIR/Contents/Resources"
MACOS="$APP_DIR/Contents/MacOS"

echo "Building $APP_NAME.app (standalone, no external browser)..."

mkdir -p "$RESOURCES" "$MACOS"

# Compile Swift app (uses system WebKit — no extra deps)
if ! command -v swiftc &>/dev/null; then
  echo "Error: swiftc not found. Install Xcode or run: xcode-select --install"
  exit 1
fi
swiftc -o "$MACOS/$BINARY_NAME" "$SCRIPT_DIR/main.swift" "$SCRIPT_DIR/JSONDeepDiff.swift" \
  -framework Cocoa -framework WebKit

# Copy HTML into the app bundle
cp "$SCRIPT_DIR/index.html" "$RESOURCES/"

# App icon
if [ -f "$SCRIPT_DIR/icon.png" ]; then
  echo "Generating app icon..."
  bash "$SCRIPT_DIR/make-icns.sh" "$SCRIPT_DIR/icon.png" "$RESOURCES/AppIcon.icns"
fi

# Info.plist (include document type so app accepts dropped .json files)
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$BINARY_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.jsondiff.v4</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>JSON</string>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.json</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

echo "Created: $APP_DIR"
echo "Move '$APP_NAME.app' anywhere — it runs with no external dependencies (no browser needed)."
