// Procedural paper-grain generation (a single shared, tileable noise image).

import AppKit
import CoreImage

enum Grain {
    /// One shared grain tile; overlay opacity is controlled per-look at draw time.
    static let shared: NSImage? = make(side: 180, contrast: 0.4, brightness: 0.0)

    private static func make(side: Int, contrast: Double, brightness: Double) -> NSImage? {
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
