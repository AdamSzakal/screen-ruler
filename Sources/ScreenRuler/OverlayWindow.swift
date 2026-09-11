import AppKit

/// A borderless, click-through window that covers one screen fully.
final class OverlayWindow: NSWindow {
    let rulerView = RulerView(frame: .zero)

    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true          // all clicks go to the windows below
        isReleasedWhenClosed = false
        displaysWhenScreenProfileChanges = true
        // Show on every space, also over a full screen app, and do not
        // disturb the window cycle of the user.
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        level = OverlayWindow.topLevel
        contentView = rulerView
        setFrame(screen.frame, display: true)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Above the menu bar, the Dock and full screen apps.
    static let topLevel = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
    /// Used while the menu of the app is open, so that the menu stays readable.
    static let loweredLevel = NSWindow.Level.floating
}
