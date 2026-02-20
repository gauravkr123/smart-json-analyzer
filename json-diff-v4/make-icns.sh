#!/bin/bash
# Convert a PNG to a macOS .icns icon file.
# Usage: ./make-icns.sh input.png output.icns
set -e
INPUT="$1"
OUTPUT="${2:-AppIcon.icns}"
ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
sips -z 16 16     "$INPUT" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32 32     "$INPUT" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32 32     "$INPUT" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64 64     "$INPUT" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128 128   "$INPUT" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256 256   "$INPUT" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$INPUT" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512 512   "$INPUT" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$INPUT" --out "$ICONSET/icon_512x512.png"    >/dev/null
sips -z 1024 1024 "$INPUT" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$OUTPUT"
rm -rf "$(dirname "$ICONSET")"
echo "Created: $OUTPUT"
