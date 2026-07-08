#!/bin/bash
# Builds a signed + notarized + stapled Papertone.dmg for distribution.
# Prereqs (one-time): a "Developer ID Application" cert in your keychain, and
# notarization credentials stored under the profile below (see RELEASE.md).
set -e
cd "$(dirname "$0")"

APP_NAME="Papertone"
NOTARY_PROFILE="papertone-notary"
DD="$HOME/Library/Caches/Papertone-DerivedData"
DIST="dist"

# 1. Find the Developer ID Application identity.
DEVID=$(security find-identity -v -p codesigning \
        | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.+)".*/\1/')
if [ -z "$DEVID" ]; then
  echo "✗ No 'Developer ID Application' certificate found."
  echo "  Create one: Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application."
  exit 1
fi
echo "Signing identity: $DEVID"

# 2. Build Release unsigned (we sign explicitly afterwards).
echo "→ build (Release)"
xcodegen generate >/dev/null
xcodebuild -project "${APP_NAME}.xcodeproj" -scheme "${APP_NAME}" \
  -configuration Release -derivedDataPath "$DD" \
  CODE_SIGNING_ALLOWED=NO build >/dev/null

rm -rf "$DIST"; mkdir -p "$DIST"
APP="$DIST/${APP_NAME}.app"
cp -R "$DD/Build/Products/Release/${APP_NAME}.app" "$APP"

# 3. Sign with Developer ID + hardened runtime + secure timestamp.
echo "→ codesign"
codesign --force --options runtime --timestamp \
  --entitlements App/Papertone.entitlements \
  --sign "$DEVID" "$APP"
codesign --verify --strict --verbose=2 "$APP"

# 4. Notarize the app (zip → submit → wait).
echo "→ notarize app"
ditto -c -k --keepParent "$APP" "$DIST/${APP_NAME}.zip"
xcrun notarytool submit "$DIST/${APP_NAME}.zip" \
  --keychain-profile "$NOTARY_PROFILE" --wait
rm -f "$DIST/${APP_NAME}.zip"

# 5. Staple the ticket onto the app.
echo "→ staple app"
xcrun stapler staple "$APP"

# 6. Build a DMG (app + /Applications shortcut).
echo "→ dmg"
DMGROOT="$DIST/dmgroot"; mkdir -p "$DMGROOT"
cp -R "$APP" "$DMGROOT/"
ln -s /Applications "$DMGROOT/Applications"
DMG="$DIST/${APP_NAME}.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMGROOT" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$DMGROOT"

# 7. Notarize + staple the DMG itself.
echo "→ notarize dmg"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"

echo "✓ Ready to distribute: $DMG"
