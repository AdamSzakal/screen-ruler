import AppKit

/// Keeps one overlay window for each screen and moves the slit to the pointer.
final class OverlayController {
    private var windows: [OverlayWindow] = []
    private var tracker: Timer?
    private var lastPointer: NSPoint = .zero

    private(set) var isActive = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
    }

    // MARK: - On and off

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        if active {
            buildWindows()
            startTracking()
        } else {
            stopTracking()
            removeWindows()
        }
    }

    /// Applies changed settings (slit height, dim, soft edge) at once.
    func refresh() {
        for window in windows { window.rulerView.layoutDimLayers() }
    }

    /// The overlay goes below the menus while the menu of the app is open,
    /// so that the user can read the menu without the dim on top of it.
    func setMenuOpen(_ open: Bool) {
        let level = open ? OverlayWindow.loweredLevel : OverlayWindow.topLevel
        for window in windows { window.level = level }
    }

    // MARK: - Windows

    private func buildWindows() {
        removeWindows()
        windows = NSScreen.screens.map { screen in
            let window = OverlayWindow(screen: screen)
            window.orderFrontRegardless()
            return window
        }
        updateSlit(force: true)
    }

    private func removeWindows() {
        for window in windows { window.orderOut(nil) }
        windows.removeAll()
    }

    @objc private func screensChanged() {
        guard isActive else { return }
        buildWindows()
    }

    // MARK: - Pointer tracking

    private func startTracking() {
        stopTracking()
        // A poll of the pointer needs no accessibility permission, and it also
        // follows the pointer when another app drags or animates it.
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateSlit(force: false)
        }
        RunLoop.main.add(timer, forMode: .common)
        tracker = timer
    }

    private func stopTracking() {
        tracker?.invalidate()
        tracker = nil
    }

    private func updateSlit(force: Bool) {
        let pointer = NSEvent.mouseLocation
        guard force || pointer.y != lastPointer.y || pointer.x != lastPointer.x else { return }
        lastPointer = pointer

        for window in windows {
            let frame = window.frame
            // Only the screen under the pointer gets a slit; the others stay dim.
            let onThisScreen = NSMouseInRect(pointer, frame, false)
            window.rulerView.slitCenterY = onThisScreen ? pointer.y - frame.minY : nil
        }
    }
}
