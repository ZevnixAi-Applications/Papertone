# Releasing Papertone (Developer ID + notarization)

Papertone is distributed **directly** (not the App Store) because it uses
display-gamma APIs that the App Store sandbox disallows. That means Developer
ID signing + Apple notarization so it opens without Gatekeeper warnings.

## One-time setup

### 1. Developer ID Application certificate
Xcode → **Settings → Accounts** → select the team (`76Z3N79K53`) →
**Manage Certificates…** → **＋** → **Developer ID Application**.
(Requires the Account Holder / Admin role on the Apple Developer account.)

### 2. App-specific password
appleid.apple.com → **Sign-In & Security → App-Specific Passwords** →
generate one (label it e.g. `papertone-notary`) and copy it.

### 3. Store notarization credentials
Run once (keeps the password in your keychain, not in any file):
```sh
xcrun notarytool store-credentials "papertone-notary" \
  --apple-id "<your-apple-id-email>" \
  --team-id 76Z3N79K53 \
  --password "<app-specific-password>"
```

## Cut a release
```sh
./release.sh        # build → sign (Developer ID + hardened runtime) →
                    # notarize → staple → DMG → notarize + staple DMG
```
Output: `dist/Papertone.dmg` — a signed, notarized disk image anyone can
install by dragging Papertone into Applications.

## Notes
- Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml` for each release.
- There is no in-app auto-updater yet (future: Sparkle). Updates are manual re-downloads for now.
