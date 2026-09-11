#!/bin/bash
# Builds ScreenRuler.app into ./build. Use "./build.sh install" to also copy
# the app to /Applications and start it.
set -euo pipefail

cd "$(dirname "$0")"
APP="build/ScreenRuler.app"

echo "==> Compiling (universal binary)"
ARCHS=(--arch arm64 --arch x86_64)
if ! swift build -c release "${ARCHS[@]}" >/dev/null 2>&1; then
  echo "    universal build not possible, using this machine's architecture"
  ARCHS=()
  swift build -c release
fi
BIN="$(swift build -c release "${ARCHS[@]}" --show-bin-path 2>/dev/null | tail -1)/ScreenRuler"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ScreenRuler"
cp Resources/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "==> Signing (ad-hoc)"
codesign --force --sign - --timestamp=none "$APP" >/dev/null

if [[ "${1:-}" == "install" ]]; then
  echo "==> Installing to /Applications"
  pkill -x ScreenRuler || true
  rm -rf /Applications/ScreenRuler.app
  cp -R "$APP" /Applications/ScreenRuler.app
  open /Applications/ScreenRuler.app
  echo "    started from /Applications"
else
  echo "Done: $APP   (run it with: open $APP)"
fi
