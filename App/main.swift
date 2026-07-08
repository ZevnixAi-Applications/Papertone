// Paperman — menu-bar utility that lays a warm matte "paper" texture over
// the screen and can soften glare via display gamma.

import AppKit
import CoreGraphics

// Safety net: if we're killed (Ctrl-C / SIGTERM) restore the display gamma
// so a softened screen never gets left behind.
signal(SIGINT)  { _ in CGDisplayRestoreColorSyncSettings(); exit(0) }
signal(SIGTERM) { _ in CGDisplayRestoreColorSyncSettings(); exit(0) }

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu-bar only, no Dock icon
app.run()
