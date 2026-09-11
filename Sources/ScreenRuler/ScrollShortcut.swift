import AppKit

/// Watches for a scroll of the wheel or the trackpad while the user holds a
/// set of modifier keys, and reports the movement in points.
///
/// A global NSEvent monitor is used, because it needs no permission. It can
/// only read the events, thus the app below also receives the scroll.
final class ScrollShortcut {
    private let modifiers: NSEvent.ModifierFlags
    private let onScroll: (Double) -> Void
    private var monitor: Any?

    /// Points of change for one line of a mouse wheel.
    private let lineStep = 6.0
    /// Points of change for one unit of a trackpad or a precise mouse.
    private let preciseStep = 0.5

    init(modifiers: NSEvent.ModifierFlags, onScroll: @escaping (Double) -> Void) {
        self.modifiers = modifiers
        self.onScroll = onScroll
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    deinit { stop() }

    private func handle(_ event: NSEvent) {
        let held = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard held == modifiers else { return }
        let delta = event.hasPreciseScrollingDeltas
            ? event.scrollingDeltaY * preciseStep
            : event.scrollingDeltaY * lineStep
        guard delta != 0 else { return }
        onScroll(delta)
    }
}
