// The overlay: transparent, click-through windows (one per screen) that
// render a look's tint + grain + vignette, scaled by the master intensity.

import AppKit

final class OverlayView: NSView {
    var params: LookParams = .neutral { didSet { needsDisplay = true } }
    var intensity: Double = 0        { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        guard intensity > 0 else { return }
        let i = CGFloat(intensity)

        // 1) Colour wash.
        if params.tintAlpha > 0 {
            NSColor(calibratedRed: CGFloat(params.tint.r),
                    green: CGFloat(params.tint.g),
                    blue: CGFloat(params.tint.b),
                    alpha: CGFloat(params.tintAlpha) * i).setFill()
            bounds.fill()
        }

        // 2) Paper grain.
        if params.grainAlpha > 0, let grain = Grain.shared, let ctx = NSGraphicsContext.current {
            ctx.saveGraphicsState()
            ctx.cgContext.setAlpha(CGFloat(params.grainAlpha) * i)
            NSColor(patternImage: grain).set()
            bounds.fill()
            ctx.restoreGraphicsState()
        }

        // 3) Vignette (radial darkening toward the edges).
        if params.vignette > 0 {
            let edge = NSColor.black.withAlphaComponent(CGFloat(params.vignette) * i)
            if let g = NSGradient(colors: [.clear, .clear, edge]) {
                g.draw(in: NSBezierPath(rect: bounds), relativeCenterPosition: .zero)
            }
        }
    }
}

final class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless,
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary,
                              .fullScreenAuxiliary, .ignoresCycle]
        setFrame(screen.frame, display: true)

        let view = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.autoresizingMask = [.width, .height]
        contentView = view
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Owns one window per screen, rebuilding when the display layout changes.
final class OverlayController {
    private var windows: [OverlayWindow] = []
    private var last: (LookParams, Double, Bool)?

    init() {
        rebuild()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func screensChanged() {
        rebuild()
        if let l = last { apply(params: l.0, intensity: l.1, visible: l.2) }
    }

    private func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { OverlayWindow(screen: $0) }
    }

    func apply(params: LookParams, intensity: Double, visible: Bool) {
        last = (params, intensity, visible)
        for w in windows {
            if let v = w.contentView as? OverlayView {
                v.params = params
                v.intensity = visible ? intensity : 0
            }
            if visible && intensity > 0 { w.orderFrontRegardless() } else { w.orderOut(nil) }
        }
    }
}
