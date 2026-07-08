// The look/preset model, shared between the app and (later) the Control
// Center extension. Pure data — no AppKit — so both targets can use it.

import Foundation

/// A plain RGB triple (0...1), Codable for persistence.
struct RGB: Codable, Equatable {
    var r, g, b: Double
    init(_ r: Double, _ g: Double, _ b: Double) { self.r = r; self.g = g; self.b = b }
}

/// The full description of a "look": an overlay layer + a display curve.
/// Everything here is scaled at runtime by the master Intensity.
struct LookParams: Codable, Equatable {
    // Overlay (composited on top of the screen)
    var tint: RGB          // wash colour
    var tintAlpha: Double  // wash opacity
    var grainAlpha: Double // paper grain opacity
    var vignette: Double   // darkened-edge amount

    // Display curve (system gamma tables)
    var warmth: Double     // reduce blue → warmer (Night-Shift-like)
    var contrast: Double   // S-curve "punch"
    var blackLift: Double  // raise the black point (faded look)
    var whiteDrop: Double  // lower the white point (softer highlights)

    static let neutral = LookParams(
        tint: RGB(1, 1, 1), tintAlpha: 0, grainAlpha: 0, vignette: 0,
        warmth: 0, contrast: 0, blackLift: 0, whiteDrop: 0)

    /// True when this look touches the display gamma (needs the non-sandbox build).
    var usesGamma: Bool { warmth > 0 || contrast > 0 || blackLift > 0 || whiteDrop > 0 }
}

struct Preset: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var builtIn: Bool
    var params: LookParams
}

enum PresetCatalog {
    static let builtIn: [Preset] = [
        Preset(id: "matte", name: "Classic Matte", builtIn: true,
               params: LookParams(tint: RGB(0.94, 0.94, 0.92), tintAlpha: 0.18,
                                   grainAlpha: 0.05, vignette: 0,
                                   warmth: 0, contrast: 0, blackLift: 0, whiteDrop: 0)),
        Preset(id: "parchment", name: "Sunbaked Parchment", builtIn: true,
               params: LookParams(tint: RGB(0.98, 0.90, 0.76), tintAlpha: 0.26,
                                   grainAlpha: 0.09, vignette: 0.05,
                                   warmth: 0.15, contrast: 0, blackLift: 0, whiteDrop: 0)),
        Preset(id: "sepia", name: "Sepia", builtIn: true,
               params: LookParams(tint: RGB(0.76, 0.60, 0.42), tintAlpha: 0.30,
                                   grainAlpha: 0.05, vignette: 0.08,
                                   warmth: 0.20, contrast: 0, blackLift: 0.03, whiteDrop: 0)),
        Preset(id: "nightwarm", name: "Night Warm", builtIn: true,
               params: LookParams(tint: RGB(1.0, 0.85, 0.60), tintAlpha: 0.05,
                                   grainAlpha: 0, vignette: 0,
                                   warmth: 0.70, contrast: 0, blackLift: 0, whiteDrop: 0.05)),
        Preset(id: "fadedfilm", name: "Faded Film", builtIn: true,
               params: LookParams(tint: RGB(0.95, 0.94, 0.90), tintAlpha: 0.08,
                                   grainAlpha: 0.10, vignette: 0.12,
                                   warmth: 0.12, contrast: 0, blackLift: 0.10, whiteDrop: 0.06)),
        Preset(id: "vivid", name: "Vivid Punch", builtIn: true,
               params: LookParams(tint: RGB(1, 1, 1), tintAlpha: 0,
                                   grainAlpha: 0, vignette: 0,
                                   warmth: 0, contrast: 0.50, blackLift: 0, whiteDrop: 0)),
    ]

    static func preset(id: String) -> Preset? { builtIn.first { $0.id == id } }
    static let defaultID = "matte"
}
