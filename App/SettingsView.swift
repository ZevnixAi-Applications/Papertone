// The GUI control panel (SwiftUI), hosted in an AppKit window.

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: PaperSettings

    var body: some View {
        Form {
            Section("Effect") {
                Toggle("Enable paper effect", isOn: $settings.enabled)

                Picker("Texture", selection: $settings.textureID) {
                    ForEach(TextureCatalog.all) { style in
                        Text(style.name).tag(style.id)
                    }
                }

                slider("Strength", value: $settings.strength)
                slider("Warmth", value: $settings.warmth)
                slider("Grain", value: $settings.grain)
            }

            Section("Glare softening") {
                slider("Softness", value: $settings.softness)
                Text("Compresses harsh contrast by lifting black & lowering white — no colour tint. Applies to the whole display.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Per-app exceptions") {
                if settings.exceptions.isEmpty {
                    Text("No exceptions. Add apps that need true colour (e.g. Figma, Photoshop) — the effect turns off while they're in front.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(settings.exceptions) { app in
                        HStack {
                            Text(app.name)
                            Spacer()
                            Button {
                                settings.removeException(app)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                Button("Add app…") { settings.addExceptionViaPanel() }
            }

            Section("General") {
                Toggle("Launch at login", isOn: launchBinding)
                Text("Available when running the built Papertone.app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 560)
    }

    private var launchBinding: Binding<Bool> {
        Binding(get: { settings.launchAtLoginEnabled },
                set: { settings.setLaunchAtLogin($0) })
    }

    @ViewBuilder
    private func slider(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: 0...1)
        }
    }
}
