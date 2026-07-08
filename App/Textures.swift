// Texture styles + procedural grain generation.

import AppKit
import CoreImage

/// A named paper look: base tint + how strongly tint/grain are applied.
struct TextureStyle: Identifiable {
    let id: String
    let name: String
    let baseTint: NSColor
    let tintAlpha: Double     // max tint opacity at strength 1
    let grainAlpha: Double     // max grain opacity at strength 1
    let grain: NSImage?
}

enum TextureCatalog {
    static let classicMatte = TextureStyle(
        id: "matte", name: "Classic Matte",
        baseTint: NSColor(calibratedRed: 0.94, green: 0.94, blue: 0.92, alpha: 1),
        tintAlpha: 0.18, grainAlpha: 0.05,
        grain: GrainFactory.make(side: 160, contrast: 0.35, brightness: 0.0))

    static let sunbakedParchment = TextureStyle(
        id: "parchment", name: "Sunbaked Parchment",
        baseTint: NSColor(calibratedRed: 0.98, green: 0.90, blue: 0.76, alpha: 1),
        tintAlpha: 0.26, grainAlpha: 0.08,
        grain: GrainFactory.make(side: 200, contrast: 0.50, brightness: 0.02))

    static let all: [TextureStyle] = [classicMatte, sunbakedParchment]

    static func style(for id: String) -> TextureStyle {
        all.first { $0.id == id } ?? classicMatte
    }
}

/// Generates a small, tileable, desaturated noise image for paper grain.
enum GrainFactory {
    static func make(side: Int, contrast: Double, brightness: Double) -> NSImage? {
        let context = CIContext()
        guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return nil }
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        let grey = noise.cropped(to: rect).applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0,
            kCIInputContrastKey: contrast,
            kCIInputBrightnessKey: brightness,
        ])
        guard let cg = context.createCGImage(grey, from: rect) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: side, height: side))
    }
}

/// Shifts a colour warmer (>0.5) or cooler (<0.5) without touching green,
/// so text legibility stays roughly constant.
func warmedColor(_ c: NSColor, warmth: Double) -> NSColor {
    let base = c.usingColorSpace(.genericRGB) ?? c
    let d = CGFloat((warmth - 0.5) * 0.12)
    return NSColor(calibratedRed: min(1, max(0, base.redComponent + d)),
                   green: base.greenComponent,
                   blue: min(1, max(0, base.blueComponent - d)),
                   alpha: base.alphaComponent)
}
