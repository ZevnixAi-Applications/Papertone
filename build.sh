#!/bin/bash
# Regenerates the Xcode project, builds signed, installs to /Applications, launches.
# Build output goes to ~/Library/Caches (NOT the Desktop) so Finder/Spotlight
# never picks up the intermediate .app as a duplicate.
set -e
cd "$(dirname "$0")"

DD="$HOME/Library/Caches/Papertone-DerivedData"

echo "→ project"
xcodegen generate >/dev/null

echo "→ build"
xcodebuild -project Papertone.xcodeproj -scheme Papertone \
  -configuration Debug -derivedDataPath "$DD" build 2>&1 | tail -3

echo "→ install"
pkill -f "Papertone" 2>/dev/null || true
sleep 1
rm -rf /Applications/Papertone.app
cp -R "$DD/Build/Products/Debug/Papertone.app" /Applications/
touch /Applications/Papertone.app
open /Applications/Papertone.app
echo "✓ Installed & launched /Applications/Papertone.app"
