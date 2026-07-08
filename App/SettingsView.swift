// The GUI control panel (SwiftUI), hosted in an AppKit window.

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: PaperSettings
    @State private var showingSave = false
    @State private var newPresetName = ""

    var body: some View {
        Form {
            // MARK: Look
            Section("Look") {
                Toggle("Enable paper effect", isOn: $settings.enabled)

                Picker("Preset", selection: presetBinding) {
                    ForEach(settings.allPresets) { preset in
                        Text(preset.name).tag(preset.id)
                    }
                    if settings.selectedPresetID == nil {
                        Text("Custom (modified)").tag("__custom__")
                    }
                }

                slider("Intensity", value: $settings.intensity)
            }

            // MARK: Fine-tune
            Section("Fine-tune") {
                ColorPicker("Tint colour", selection: tintColorBinding, supportsOpacity: false)
                slider("Tint amount", value: param(\.tintAlpha), max: 0.6)
                slider("Grain",       value: param(\.grainAlpha), max: 0.3)
                slider("Vignette",    value: param(\.vignette), max: 0.6)
                Divider()
                Text("Display curve — needs the direct (non–App-Store) build.")
                    .font(.caption).foregroundStyle(.secondary)
                slider("Warmth",     value: param(\.warmth))
                slider("Contrast",   value: param(\.contrast))
                slider("Black lift", value: param(\.blackLift))
                slider("White drop", value: param(\.whiteDrop))

                Button("Save as preset…") {
                    newPresetName = ""
                    showingSave = true
                }
            }

            // MARK: My presets
            if !settings.customPresets.isEmpty {
                Section("My presets") {
                    ForEach(settings.customPresets) { preset in
                        HStack {
                            Button(preset.name) { settings.selectPreset(preset) }
                                .buttonStyle(.link)
                            Spacer()
                            Button {
                                settings.deleteCustomPreset(preset)
                            } label: {
                                Image(systemName: "trash").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            // MARK: Per-app exceptions
            Section("Per-app exceptions") {
                if settings.exceptions.isEmpty {
                    Text("No exceptions. Add apps that need true colour (e.g. Figma, Photoshop) — the effect turns off while they're in front.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(settings.exceptions) { app in
                        HStack {
                            Text(app.name)
                            Spacer()
                            Button {
                                settings.removeException(app)
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                Button("Add app…") { settings.addExceptionViaPanel() }
            }

            // MARK: General
            Section("General") {
                Toggle("Launch at login", isOn: launchBinding)
                Text("Available when running the built Papertone.app.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 640)
        .alert("Save preset", isPresented: $showingSave) {
            TextField("Preset name", text: $newPresetName)
            Button("Save") { settings.saveCurrentAsPreset(name: newPresetName) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save the current look as a reusable preset.")
        }
    }

    // MARK: Bindings & helpers

    private var presetBinding: Binding<String> {
        Binding(get: { settings.selectedPresetID ?? "__custom__" },
                set: { id in
                    if let p = settings.allPresets.first(where: { $0.id == id }) {
                        settings.selectPreset(p)
                    }
                })
    }

    /// A binding to one Double field of the live look; editing marks it custom.
    private func param(_ keyPath: WritableKeyPath<LookParams, Double>) -> Binding<Double> {
        Binding(get: { settings.params[keyPath: keyPath] },
                set: { v in settings.editParams { $0[keyPath: keyPath] = v } })
    }

    private var tintColorBinding: Binding<Color> {
        Binding(get: {
            let t = settings.params.tint
            return Color(red: t.r, green: t.g, blue: t.b)
        }, set: { c in
            let ns = NSColor(c).usingColorSpace(.sRGB) ?? .white
            settings.editParams {
                $0.tint = RGB(Double(ns.redComponent),
                              Double(ns.greenComponent),
                              Double(ns.blueComponent))
            }
        })
    }

    private var launchBinding: Binding<Bool> {
        Binding(get: { settings.launchAtLoginEnabled },
                set: { settings.setLaunchAtLogin($0) })
    }

    @ViewBuilder
    private func slider(_ title: String, value: Binding<Double>, max: Double = 1) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue / max * 100))%")
                    .foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: value, in: 0...max)
        }
    }
}
