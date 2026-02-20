#!/bin/bash
# Creates a .app that opens the JSON Diff UI in your default browser.
# No compilation needed. The .app depends on your default browser at run time.

set -e
APP_NAME="JSON Deep Diff"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME (opens in browser).app"
RESOURCES="$APP_DIR/Contents/Resources"
MACOS="$APP_DIR/Contents/MacOS"

mkdir -p "$RESOURCES" "$MACOS"

cp "$SCRIPT_DIR/index.html" "$RESOURCES/"

cat > "$MACOS/launcher" << 'LAUNCHER'
#!/bin/bash
RESOURCES="$(dirname "$0")/../Resources"
open "$RESOURCES/index.html"
LAUNCHER
chmod +x "$MACOS/launcher"

cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>launcher</string>
  <key>CFBundleIdentifier</key>
  <string>com.jsondiff.app.browser</string>
  <key>CFBundleName</key>
  <string>JSON Deep Diff</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
</dict>
</plist>
PLIST

echo "Created: $APP_DIR"
echo "This .app opens the tool in your default browser."
