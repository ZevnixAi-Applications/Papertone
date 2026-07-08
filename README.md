# Papertone

A macOS menu-bar utility that lays a warm, matte "paper" texture over the
screen to soften glare, with adjustable presets and per-app exceptions.

## Features (current)
- Screen-wide, click-through paper overlay across all displays & Spaces
- Textures: Classic Matte, Sunbaked Parchment
- Strength / Warmth / Grain controls (SwiftUI settings panel)
- Glare softening via display gamma
- Per-app exceptions (auto-off for chosen apps)
- Launch at login
- Menu-bar only (no Dock clutter)

## Requirements
- macOS 13+
- Xcode 26+
- [XcodeGen](https://github.com/yonatanp/XcodeGen) (`brew install xcodegen`)

## Build & run
```sh
./build.sh          # icon → project → signed build → install to /Applications → launch
```

Or manually:
```sh
xcodegen generate                    # regenerate Papertone.xcodeproj from project.yml
open Papertone.xcodeproj              # then build/run in Xcode
```

> `Papertone.xcodeproj` is generated from `project.yml` and is git-ignored —
> run `xcodegen generate` (or `./build.sh`) after cloning.

## Structure
```
App/                 main menu-bar app (overlay, GUI, presets, gamma)
Shared/              settings model (shared with future Control Center extension)
project.yml          XcodeGen project spec
make_icon.swift      generates the app icon from an emoji
build.sh             one-command build & install
```

## Roadmap
- Preset engine + looks: Sepia, Night Warm, Faded Film, Vivid/Punch, custom presets
- Comfort: scheduling, dim-below-minimum
- Power: per-app profiles, global hotkey
- Control Center toggle (WidgetKit control extension)
