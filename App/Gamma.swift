// Display-curve engine via CoreGraphics gamma tables.
//
// Builds a per-channel lookup table from a look's warmth / contrast /
// black-lift / white-drop and applies it system-wide. Warmth reduces the
// blue (and slightly green) channel like Night Shift; contrast steepens the
// mid-tones (S-curve); black-lift + white-drop compress the range for a
// softer, faded feel. System-wide, so we always restore on disable / quit.

import CoreGraphics

enum GammaController {
    private static var active = false
    private static let tableSize = 256

    /// Apply the gamma-relevant parts of `params`, scaled by `intensity`.
    static func apply(_ params: LookParams, intensity: Double) {
        let warmth    = params.warmth    * intensity
        let contrast  = params.contrast  * intensity
        let blackLift = params.blackLift * intensity * 0.12   // cap the lift
        let whiteDrop = params.whiteDrop * intensity * 0.10

        guard warmth > 0 || contrast > 0 || blackLift > 0 || whiteDrop > 0 else {
            restore(); return
        }

        let n = tableSize
        var red   = [CGGammaValue](repeating: 0, count: n)
        var green = [CGGammaValue](repeating: 0, count: n)
        var blue  = [CGGammaValue](repeating: 0, count: n)

        let blueScale  = 1.0 - 0.45 * warmth
        let greenScale = 1.0 - 0.12 * warmth
        let lo = blackLift
        let hi = 1.0 - whiteDrop

        for i in 0..<n {
            let x = Double(i) / Double(n - 1)

            // Contrast: blend the linear ramp toward a smoothstep S-curve.
            let s = x * x * (3 - 2 * x)
            var v = x * (1 - contrast) + s * contrast

            // Range compression (lift black, drop white).
            v = lo + v * (hi - lo)

            red[i]   = CGGammaValue(min(1, max(0, v)))
            green[i] = CGGammaValue(min(1, max(0, v * greenScale)))
            blue[i]  = CGGammaValue(min(1, max(0, v * blueScale)))
        }

        for id in activeDisplays() {
            _ = CGSetDisplayTransferByTable(id, UInt32(n), &red, &green, &blue)
        }
        active = true
    }

    static func restore() {
        guard active else { return }
        CGDisplayRestoreColorSyncSettings()
        active = false
    }

    private static func activeDisplays() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        guard count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        return ids
    }
}
