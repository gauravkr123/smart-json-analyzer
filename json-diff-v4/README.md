# JSON Deep Diff — UI App

Lightweight, portable UI to compare two JSON objects with a deep diff and options to ignore order, casing, and specific keys.

## How to run (any Mac)

1. **Easiest:** Double-click `index.html` — it opens in your default browser.
2. **Or:** Double-click `Open JSON Diff.command` (opens `index.html` in the default browser).
3. **Or:** Drag the whole `json-diff-app` folder anywhere and open `index.html` from there.

No install, no CLI, no server. Works offline.

## 100% portable .app (no external dependencies)

To get a **standalone** `.app` that runs with **no browser** (UI runs inside the app using the system WebKit):

```bash
cd json-diff-app
chmod +x create-mac-app.sh
./create-mac-app.sh
```

**Requires:** Xcode or Xcode Command Line Tools (`xcode-select --install`) for a one-time compile.  
**Result:** `build/JSON Deep Diff.app` — copy it anywhere; it needs nothing else (no Safari/Chrome, no network).

## .app that opens in browser (no compilation)

If you don’t want to compile, use the script that builds an .app which opens the tool in your default browser:

```bash
chmod +x create-mac-app-browser.sh
./create-mac-app-browser.sh
```

Creates `build/JSON Deep Diff (opens in browser).app`. At run time it uses your default browser.

## Options

| Option | Description |
|--------|-------------|
| **Ignore array/object order** | Treats arrays (and object key order) as unordered when comparing, so `[1,2,3]` vs `[3,2,1]` can be considered equal. |
| **Ignore string casing** | Compares strings case-insensitively (e.g. `"Hello"` vs `"hello"`). |
| **Ignore keys** | Comma-separated list of key names to exclude from comparison (e.g. `id, timestamp, _meta`). Any property with that name, at any level, is skipped. |

## Usage

1. Paste or type JSON in **JSON A** and **JSON B**, or use **Load file → A** / **Load file → B** to load from `.json` files.
2. Set the options you want (order, case, keys to ignore).
3. Click **Compare**.
4. The **Diff result** panel shows added (green), removed (red), and changed (yellow) with the JSON path and values.

## Portable package

Copy the entire `json-diff-app` folder to any Mac (e.g. USB, cloud, another machine). As long as you open `index.html` in a browser, it works. No dependencies.
