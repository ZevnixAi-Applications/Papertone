# Papertone — Vision & Roadmap

A working note for picking the project back up any day. For user-facing docs
see [README.md](README.md); for shipping a build see [RELEASE.md](RELEASE.md).

## Vision

Make a Mac screen feel like **warm paper** instead of a harsh backlit panel —
so long reading and work sessions are easier on the eyes. Calm, native, and out
of the way (menu-bar only, click-through, per-app aware).

Positioning: the "paper tone" niche is currently served only by **paid, closed**
apps. Papertone is the **free, open-source, polished** alternative — and a public
engineering showcase for **Zevnix AI**.

## Where it is now — v0.1 (shipped)

- Public, MIT-licensed, signed + notarized DMG on GitHub Releases.
- **Effect engine**, all scaled by one master Intensity:
  - Overlay layer: tint, paper grain, vignette (transparent, click-through, all displays/Spaces).
  - Display-curve layer: warmth, contrast (S-curve), black-lift, white-drop via gamma tables.
- **6 presets** (Classic Matte, Sunbaked Parchment, Sepia, Night Warm, Faded Film, Vivid Punch) + save/delete **custom presets**.
- **Per-app exceptions**, **launch at login**, menu-bar quick preset switching.
- Distribution: **direct (Developer ID + notarization)** — not the App Store, whose sandbox blocks display-gamma access.

## Architecture (quick map)

```
App/         menu-bar app: AppDelegate, Overlay, Gamma, Textures(grain), SettingsView, main
Shared/      Settings (model + persistence) + Presets (LookParams/Preset catalog)
project.yml  XcodeGen spec (.xcodeproj is generated, not committed)
build.sh     generate → build → install to /Applications → launch
release.sh   Developer ID sign → notarize → staple → DMG
make_icon.swift / docs/  icon + product-shot generators
```

- Iterate: `./build.sh`
- Ship an update: bump `MARKETING_VERSION` in `project.yml`, then `./release.sh`

## What's next

**Phase C — Comfort**
- Scheduling: auto on/off by a time range (start simple; sunset-via-location later).
- Dim below the system minimum brightness (for dark rooms).

**Phase D — Power**
- Per-app profiles: a different look/intensity per app (not just on/off exceptions).
- Global hotkey: toggle / cycle presets from the keyboard.

**Phase E — Control Center toggle**
- WidgetKit control extension (`ControlWidgetToggle` + App Intent) + App Group shared state.
- macOS 26 supports third-party Control Center controls. Controls can only be
  buttons/toggles (no slider), so this is an on/off toggle.

**Polish & growth**
- Menu-bar **monochrome glyph** (single-colour silhouette) to replace the emoji.
- **Landing page** + a Sparkle-based **in-app auto-updater** (updates are manual re-downloads today).
- **Launch/promo**: r/macapps, Product Hunt, Show HN, and PRs to `awesome-mac` / `awesome-macos`.

## Known constraints (by design, not bugs)

- No third-party app can change **true saturation, grayscale, invert, or hue** on
  the whole display — macOS reserves that for Accessibility. "Vivid Punch" is a
  **contrast** curve, not a saturation boost.
- Gamma-based looks require **direct distribution** (sandbox off), so App Store is out unless the feature set is reduced to overlay-only.
- Screenshots can't capture the gamma looks (same reason Night Shift doesn't show
  in screenshots). The `docs/` shots are **faithful composites** built from the
  app's exact overlay + gamma math (`docs/generate_shots.py`).

## Definition of "shipped an update"
1. Build a feature on a branch or `main`, verify with `./build.sh`.
2. Bump the version in `project.yml`.
3. `./release.sh` → notarized DMG.
4. `gh release create vX.Y … dist/Papertone.dmg`.
