// Gamma "glare softening" via CoreGraphics.
//
// Lifts the black point and lowers the white point equally across R/G/B so
// harsh contrast is compressed WITHOUT tinting colours. System-wide, so we
// always restore on disable / quit.

import CoreGraphics

enum GammaController {
    private static var active = false

    static func apply(softness: Double) {
        let blackLift = Float(0.06 * softness)     // raise darkest output
        let whiteDrop = Float(0.05 * softness)     // lower brightest output
        let minV = blackLift
        let maxV = 1.0 - whiteDrop
        let gamma: Float = 1.0
        for id in activeDisplays() {
            _ = CGSetDisplayTransferByFormula(id,
                minV, maxV, gamma,
                minV, maxV, gamma,
                minV, maxV, gamma)
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
