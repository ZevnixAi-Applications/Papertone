// The overlay: transparent, click-through windows (one per screen) that
// render the paper tint + grain.

import AppKit

final class OverlayView: NSView {
    var style: TextureStyle = TextureCatalog.classicMatte { didSet { needsDisplay = true } }
    var strength: Double = 0    { didSet { needsDisplay = true } }
    var warmth: Double = 0.5    { didSet { needsDisplay = true } }
    var grainAmount: Double = 0.5 { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        guard strength > 0 else { return }

        // Warm matte wash.
        let tint = warmedColor(style.baseTint, warmth: warmth)
        tint.withAlphaComponent(CGFloat(style.tintAlpha * strength)).setFill()
        bounds.fill()

        // Paper grain, scaled by the grain slider.
        if let grain = style.grain, let ctx = NSGraphicsContext.current {
            ctx.saveGraphicsState()
            ctx.cgContext.setAlpha(CGFloat(style.grainAlpha * strength * grainAmount * 2))
            NSColor(patternImage: grain).set()
            bounds.fill()
            ctx.restoreGraphicsState()
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
        ignoresMouseEvents = true                 // click-through
        level = .screenSaver                       // above normal windows & menu bar
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
    private var last: (TextureStyle, Double, Double, Double, Bool)?

    init() {
        rebuild()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func screensChanged() {
        rebuild()
        if let l = last {
            apply(style: l.0, strength: l.1, warmth: l.2, grain: l.3, visible: l.4)
        }
    }

    private func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { OverlayWindow(screen: $0) }
    }

    func apply(style: TextureStyle, strength: Double, warmth: Double,
               grain: Double, visible: Bool) {
        last = (style, strength, warmth, grain, visible)
        for w in windows {
            if let v = w.contentView as? OverlayView {
                v.style = style
                v.warmth = warmth
                v.grainAmount = grain
                v.strength = visible ? strength : 0
            }
            if visible && strength > 0 { w.orderFrontRegardless() } else { w.orderOut(nil) }
        }
    }
}
