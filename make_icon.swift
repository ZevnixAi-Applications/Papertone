// Renders an emoji onto a cream rounded-rect app icon and writes a full
// .iconset. Usage: swift make_icon.swift "📜" AppIcon.iconset

import AppKit

let emoji = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "📜"
let outDir = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "AppIcon.iconset"

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: px, height: px)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let f = CGFloat(px)
    let inset = f * 0.08
    let rect = NSRect(x: inset, y: inset, width: f - 2 * inset, height: f - 2 * inset)
    let radius = f * 0.2237                                  // macOS squircle-ish corner
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSColor(calibratedRed: 0.957, green: 0.925, blue: 0.847, alpha: 1).setFill()   // cream
    path.fill()

    let fontSize = f * 0.56
    let str = NSAttributedString(string: emoji,
                                 attributes: [.font: NSFont.systemFont(ofSize: fontSize)])
    let s = str.size()
    str.draw(at: NSPoint(x: (f - s.width) / 2, y: (f - s.height) / 2))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let specs: [(Int, String)] = [
    (16, "icon_16x16.png"),   (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),   (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png"),
]
for (px, name) in specs {
    try! render(px).write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}
print("wrote \(specs.count) images to \(outDir)")
