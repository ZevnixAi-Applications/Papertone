// Wires everything together: menu bar, settings window, and re-applies the
// effect whenever settings change or the frontmost app changes.

import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = PaperSettings()
    private let overlay = OverlayController()
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar apps don't advertise a runtime icon by default, so minimized
        // windows show a blank badge. Set it explicitly from the asset catalog.
        if let icon = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = icon
        }

        buildStatusItem()

        // Any settings change → re-apply on the next runloop tick (values
        // are updated by then).
        cancellable = settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.apply() }
        }

        // Per-app exceptions: react when the frontmost app changes.
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(frontmostChanged),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)

        apply()

        // Show the control panel on launch so opening the app = seeing the GUI.
        openSettings()
    }

    // Re-open the panel when the app is opened again from Finder/Spotlight/Dock.
    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        GammaController.restore()
    }

    @objc private func frontmostChanged() { apply() }

    // MARK: Menu bar

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = statusItem.button {
            b.title = "📜"                 // scroll emoji, always visible in the menu bar
            b.image = nil
        }

        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Enable paper effect",
                                action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        let settingsItem = NSMenuItem(title: "Settings…",
                                      action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Papertone",
                              action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled() { settings.enabled.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let host = NSHostingController(rootView: SettingsView(settings: settings))
            let win = NSWindow(contentViewController: host)
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.title = "Papertone"
            win.isReleasedWhenClosed = false
            // Sit just above the overlay so the panel isn't washed out by the tint.
            win.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
            settingsWindow = win
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: Apply state to the overlay + gamma

    private func apply() {
        statusItem.menu?.item(at: 0)?.state = settings.enabled ? .on : .off

        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let excepted = frontmost != nil &&
            settings.exceptions.contains { $0.bundleID == frontmost }
        let on = settings.enabled && !excepted

        let style = TextureCatalog.style(for: settings.textureID)
        overlay.apply(style: style,
                      strength: settings.strength,
                      warmth: settings.warmth,
                      grain: settings.grain,
                      visible: on)

        if on && settings.softness > 0 {
            GammaController.apply(softness: settings.softness)
        } else {
            GammaController.restore()
        }
    }
}
