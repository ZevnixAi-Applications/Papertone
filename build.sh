#!/bin/bash
# Regenerates icon + Xcode project, builds signed, installs to /Applications, launches.
set -e
cd "$(dirname "$0")"

echo "→ project"
xcodegen generate >/dev/null

echo "→ build"
xcodebuild -project Papertone.xcodeproj -scheme Papertone \
  -configuration Debug -derivedDataPath build build 2>&1 | tail -3

echo "→ install"
pkill -f "Papertone" 2>/dev/null || true
sleep 1
rm -rf /Applications/Papertone.app
cp -R "build/Build/Products/Debug/Papertone.app" /Applications/
open /Applications/Papertone.app
echo "✓ Installed & launched /Applications/Papertone.app"
