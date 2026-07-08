// Settings model — the single source of truth for the whole app.
// Persists to UserDefaults, drives both the SwiftUI panel and the overlay.

import AppKit
import Combine
import ServiceManagement
import UniformTypeIdentifiers

/// An app the user wants excluded from the effect (for true colour).
struct AppRef: Codable, Identifiable, Hashable {
    let bundleID: String
    let name: String
    var id: String { bundleID }
}

/// Codable snapshot used for saving/loading.
private struct SettingsData: Codable {
    var enabled: Bool
    var textureID: String
    var strength: Double
    var warmth: Double
    var grain: Double
    var softness: Double
    var exceptions: [AppRef]
}

final class PaperSettings: ObservableObject {
    // Property observers persist on change. (didSet does NOT fire during init.)
    @Published var enabled: Bool       { didSet { persist() } }
    @Published var textureID: String   { didSet { persist() } }
    @Published var strength: Double     { didSet { persist() } }   // overall effect 0...1
    @Published var warmth: Double       { didSet { persist() } }   // 0 cool … 1 warm
    @Published var grain: Double        { didSet { persist() } }   // texture amount 0...1
    @Published var softness: Double     { didSet { persist() } }   // gamma glare-softening 0...1
    @Published var exceptions: [AppRef] { didSet { persist() } }

    private static let key = "PapermanSettings"

    init() {
        var data = SettingsData(enabled: true, textureID: "matte",
                                strength: 0.4, warmth: 0.5, grain: 0.5,
                                softness: 0.0, exceptions: [])
        if let raw = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(SettingsData.self, from: raw) {
            data = decoded
        }
        enabled = data.enabled
        textureID = data.textureID
        strength = data.strength
        warmth = data.warmth
        grain = data.grain
        softness = data.softness
        exceptions = data.exceptions
    }

    private func persist() {
        let data = SettingsData(enabled: enabled, textureID: textureID,
                                strength: strength, warmth: warmth, grain: grain,
                                softness: softness, exceptions: exceptions)
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: Self.key)
        }
    }

    // MARK: Per-app exceptions

    func removeException(_ app: AppRef) {
        exceptions.removeAll { $0.bundleID == app.bundleID }
    }

    /// Opens a file picker on /Applications and adds the chosen app.
    func addExceptionViaPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Add"
        guard panel.runModal() == NSApplication.ModalResponse.OK, let url = panel.url,
              let id = Bundle(url: url)?.bundleIdentifier else { return }
        let name = FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
        if !exceptions.contains(where: { $0.bundleID == id }) {
            exceptions.append(AppRef(bundleID: id, name: name))
        }
    }

    // MARK: Launch at login (works from the built .app, not `swift run`)

    var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else  { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Paperman launch-at-login error: \(error.localizedDescription)")
        }
        objectWillChange.send()   // refresh the toggle's displayed state
    }
}
