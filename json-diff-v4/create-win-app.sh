#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Packages a lightweight Windows-ready folder that can be
# zipped and shared. Uses Edge in app mode (no address bar,
# looks native). Works on all Windows 10/11 machines.
# Run this on your Mac — no Windows tools needed.
# ═══════════════════════════════════════════════════════════════
set -e

APP_NAME="JSON Diff v4"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build-win"
APP_DIR="$BUILD_DIR/$APP_NAME"

echo "Packaging $APP_NAME for Windows..."

rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR"

# Copy the HTML app
cp "$SCRIPT_DIR/index.html" "$APP_DIR/"

# ─── VBScript launcher (preferred: no console window) ───
cat > "$APP_DIR/JSON Diff v4.vbs" << 'VBSCRIPT'
' JSON Diff v4 — Opens in Microsoft Edge app mode (no address bar, looks native)
' Works on Windows 10/11 where Edge is pre-installed.
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
strHTML = objFSO.BuildPath(strDir, "index.html")

' Try Edge first (app mode = no tabs, no address bar)
strEdge = ""
strEdgePaths = Array( _
    objShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & "\Microsoft\Edge\Application\msedge.exe", _
    objShell.ExpandEnvironmentStrings("%ProgramFiles%") & "\Microsoft\Edge\Application\msedge.exe", _
    objShell.ExpandEnvironmentStrings("%LocalAppData%") & "\Microsoft\Edge\Application\msedge.exe" _
)
For Each p In strEdgePaths
    If objFSO.FileExists(p) Then
        strEdge = p
        Exit For
    End If
Next

If strEdge <> "" Then
    objShell.Run """" & strEdge & """ --app=""file:///" & Replace(strHTML, "\", "/") & """ --window-size=1400,900", 1, False
Else
    ' Fallback: open in default browser
    objShell.Run "cmd /c start """" """ & strHTML & """", 0, False
End If
VBSCRIPT

# ─── Batch launcher (alternative: shows brief console flash) ───
cat > "$APP_DIR/JSON Diff v4.bat" << 'BATCH'
@echo off
REM JSON Diff v4 — Opens in Edge app mode (native look)
REM For a console-free launch, use "JSON Diff v4.vbs" instead.
setlocal

set "HTML=%~dp0index.html"

REM Try Edge in app mode first
for %%E in (
    "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
    "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
    "%LocalAppData%\Microsoft\Edge\Application\msedge.exe"
) do (
    if exist %%E (
        start "" %%E --app="file:///%HTML:\=/%" --window-size=1400,900
        exit /b
    )
)

REM Fallback: default browser
start "" "%HTML%"
BATCH

# ─── README ───
cat > "$APP_DIR/README.txt" << 'README'
JSON Diff v4 for Windows
═════════════════════════

Quick Start:
  Double-click "JSON Diff v4.vbs" to launch.
  (Or use "JSON Diff v4.bat" if .vbs is blocked.)

The app opens in Microsoft Edge's app mode — no address bar,
no tabs, looks and feels like a native desktop application.
Works on any Windows 10/11 machine (Edge is pre-installed).

Features:
  • Deep comparison of two JSON objects
  • Ignore array order, string casing, or specific keys
  • Side-by-side diff view with click-to-locate
  • Key frequency analysis tab
  • Export results as JSON, CSV, or Text
  • Drag & drop JSON files
  • Virtual scrolling for large files (10,000+ diffs)
  • Web Worker for non-blocking computation

For a standalone .exe (optional):
  1. Install .NET 8 SDK:  winget install Microsoft.DotNet.SDK.8
  2. Run create-win-exe.bat
  3. The resulting JSONDeepDiff.exe is fully self-contained.
README

# Copy the exe build files too
cp "$SCRIPT_DIR/JSONDeepDiff.cs" "$APP_DIR/"
cp "$SCRIPT_DIR/create-win-exe.bat" "$APP_DIR/"

echo ""
echo "Created: $APP_DIR"
echo ""
echo "Contents:"
ls -1 "$APP_DIR"
echo ""
echo "To distribute: zip the '$APP_NAME' folder and share."
echo "On Windows: double-click 'JSON Diff v4.vbs' to launch."
