// Settings model — the single source of truth. Persists to UserDefaults and
// drives both the SwiftUI panel and the overlay/gamma.

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

private struct SettingsData: Codable {
    var enabled: Bool
    var params: LookParams
    var intensity: Double
    var selectedPresetID: String?
    var customPresets: [Preset]
    var exceptions: [AppRef]
}

final class PaperSettings: ObservableObject {
    @Published var enabled: Bool               { didSet { persist() } }
    @Published var params: LookParams          { didSet { persist() } }   // active live look
    @Published var intensity: Double            { didSet { persist() } }   // master 0...1
    @Published var selectedPresetID: String?    { didSet { persist() } }   // nil = custom/modified
    @Published var customPresets: [Preset]      { didSet { persist() } }
    @Published var exceptions: [AppRef]         { didSet { persist() } }

    private static let key = "PapertoneSettingsV2"

    init() {
        let base = PresetCatalog.preset(id: PresetCatalog.defaultID)!
        var data = SettingsData(enabled: true, params: base.params, intensity: 0.4,
                                selectedPresetID: base.id, customPresets: [], exceptions: [])
        if let raw = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(SettingsData.self, from: raw) {
            data = decoded
        }
        enabled = data.enabled
        params = data.params
        intensity = data.intensity
        selectedPresetID = data.selectedPresetID
        customPresets = data.customPresets
        exceptions = data.exceptions
    }

    private func persist() {
        let data = SettingsData(enabled: enabled, params: params, intensity: intensity,
                                selectedPresetID: selectedPresetID,
                                customPresets: customPresets, exceptions: exceptions)
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: Self.key)
        }
    }

    // MARK: Presets

    var allPresets: [Preset] { PresetCatalog.builtIn + customPresets }

    func selectPreset(_ preset: Preset) {
        params = preset.params
        selectedPresetID = preset.id
    }

    /// Apply an edit to the live look and mark it as no-longer-matching a preset.
    func editParams(_ change: (inout LookParams) -> Void) {
        var p = params
        change(&p)
        params = p
        selectedPresetID = nil
    }

    func saveCurrentAsPreset(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let preset = Preset(id: UUID().uuidString, name: trimmed, builtIn: false, params: params)
        customPresets.append(preset)
        selectedPresetID = preset.id
    }

    func deleteCustomPreset(_ preset: Preset) {
        customPresets.removeAll { $0.id == preset.id }
        if selectedPresetID == preset.id { selectedPresetID = nil }
    }

    // MARK: Per-app exceptions

    func removeException(_ app: AppRef) {
        exceptions.removeAll { $0.bundleID == app.bundleID }
    }

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

    // MARK: Launch at login (works from the built .app)

    var launchAtLoginEnabled: Bool { SMAppService.mainApp.status == .enabled }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else  { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Papertone launch-at-login error: \(error.localizedDescription)")
        }
        objectWillChange.send()
    }
}
