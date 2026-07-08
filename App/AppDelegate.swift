// Wires everything together: menu bar, settings window, and re-applies the
// effect whenever settings change or the frontmost app changes.

import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
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
        menu.delegate = self            // rebuilt on open so state is always current
        statusItem.menu = menu
    }

    // Rebuild the menu each time it opens: current enable state + preset list.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let toggle = NSMenuItem(title: "Enable paper effect",
                                action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        toggle.state = settings.enabled ? .on : .off
        menu.addItem(toggle)

        menu.addItem(.separator())
        let header = NSMenuItem(title: "Preset", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        for preset in settings.allPresets {
            let item = NSMenuItem(title: preset.name,
                                  action: #selector(pickPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.id
            item.state = (settings.selectedPresetID == preset.id) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings…",
                                      action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quit = NSMenuItem(title: "Quit Papertone",
                              action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func toggleEnabled() { settings.enabled.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func pickPreset(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let preset = settings.allPresets.first(where: { $0.id == id }) else { return }
        settings.selectPreset(preset)
    }

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
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let excepted = frontmost != nil &&
            settings.exceptions.contains { $0.bundleID == frontmost }
        let on = settings.enabled && !excepted && settings.intensity > 0

        overlay.apply(params: settings.params,
                      intensity: on ? settings.intensity : 0,
                      visible: on)

        if on {
            GammaController.apply(settings.params, intensity: settings.intensity)
        } else {
            GammaController.restore()
        }
    }
}
