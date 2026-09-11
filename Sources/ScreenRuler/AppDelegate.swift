import AppKit
import Carbon.HIToolbox
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let overlay = OverlayController()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var menu: NSMenu!
    private var statusLine: NSMenuItem!
    private var toggleItem: NSMenuItem!
    private var loginItem: NSMenuItem!
    private var sliders: [Slider: SliderMenuItemView] = [:]
    private var toggleKey: GlobalHotKey?
    private var arrowKeys: [GlobalHotKey] = []
    private var repeatTimer: Timer?

    /// The modifiers of all shortcuts: ⌃⌥⌘.
    private static let shortcutModifiers: NSEvent.ModifierFlags = [.control, .option, .command]
    private static let carbonModifiers = UInt32(controlKey | optionKey | cmdKey)

    /// Change of the slit height for one press of an arrow key.
    private static let slitStep = 10.0
    /// Wait before a held arrow key starts to repeat, like the system does.
    private static let repeatDelay = 0.3
    /// Time between two steps while the arrow key stays down.
    private static let repeatInterval = 1.0 / 30.0

    private enum Slider { case slitHeight, dimOpacity, feather }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Settings.registerDefaults()
        buildMenu()
        buildStatusItem()
        registerShortcuts()
        setRulerOn(Settings.enabled)
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlay.setActive(false)
    }

    // MARK: - Status item

    private func buildStatusItem() {
        statusItem.menu = menu          // a click with any button opens the menu
        guard let button = statusItem.button else { return }
        button.toolTip = "Screen Ruler"
        updateStatusIcon()
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        let name = overlay.isActive ? "ruler.fill" : "ruler"
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: "Screen Ruler")
        button.image?.isTemplate = true
        button.appearsDisabled = !overlay.isActive
    }

    // MARK: - Menu

    private func buildMenu() {
        menu = NSMenu()
        menu.delegate = self

        menu.addItem(header("Screen Ruler \(Self.version)"))
        statusLine = caption("")
        menu.addItem(statusLine)
        menu.addItem(.separator())

        toggleItem = NSMenuItem(title: "Switch Ruler Off", action: #selector(toggleRuler), keyEquivalent: "r")
        toggleItem.keyEquivalentModifierMask = Self.shortcutModifiers
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        sliders[.slitHeight] = addSlider(title: "Slit height",
                                         range: Settings.slitHeightRange,
                                         value: Settings.slitHeight,
                                         format: Self.pixels,
                                         onChange: { Settings.slitHeight = $0 })

        sliders[.dimOpacity] = addSlider(title: "Dim amount",
                                         range: Settings.dimOpacityRange,
                                         value: Settings.dimOpacity,
                                         format: Self.percent,
                                         onChange: { Settings.dimOpacity = $0 })

        sliders[.feather] = addSlider(title: "Edge softness",
                                      range: Settings.featherRange,
                                      value: Settings.feather,
                                      format: Self.pixels,
                                      onChange: { Settings.feather = $0 })

        menu.addItem(.separator())
        menu.addItem(caption("⌃⌥⌘R   switch the ruler on or off"))
        menu.addItem(caption("⌃⌥⌘↑ ⌃⌥⌘↓   change the slit height"))
        menu.addItem(.separator())

        loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem(title: "Quit Screen Ruler",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
    }

    @discardableResult
    private func addSlider(title: String,
                           range: ClosedRange<Double>,
                           value: Double,
                           format: @escaping (Double) -> String,
                           onChange: @escaping (Double) -> Void) -> SliderMenuItemView {
        let view = SliderMenuItemView(title: title, range: range, value: value, format: format) { [weak self] newValue in
            onChange(newValue)
            self?.overlay.refresh()
        }
        let item = NSMenuItem()
        item.view = view
        menu.addItem(item)
        return view
    }

    /// A bold, not selectable line at the top of the menu.
    private func header(_ text: String) -> NSMenuItem {
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.menuFont(ofSize: 13).bold,
        ])
        item.isEnabled = false
        return item
    }

    /// A small, grey, not selectable line: status or hint.
    private func caption(_ text: String) -> NSMenuItem {
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.menuFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor,
        ])
        item.isEnabled = false
        return item
    }

    func menuWillOpen(_ menu: NSMenu) {
        // The values can change without the menu, e.g. with the scroll shortcut.
        sliders[.slitHeight]?.value = Settings.slitHeight
        sliders[.dimOpacity]?.value = Settings.dimOpacity
        sliders[.feather]?.value = Settings.feather

        let screens = NSScreen.screens.count
        statusLine.attributedTitle = caption(overlay.isActive
            ? "On — \(screens) screen\(screens == 1 ? "" : "s") dimmed"
            : "Off").attributedTitle
        toggleItem.title = overlay.isActive ? "Switch Ruler Off" : "Switch Ruler On"
        loginItem.state = isOpenAtLogin ? .on : .off

        overlay.setMenuOpen(true)
    }

    func menuDidClose(_ menu: NSMenu) {
        overlay.setMenuOpen(false)
    }

    // MARK: - Actions

    @objc private func toggleRuler() {
        setRulerOn(!overlay.isActive)
    }

    private func setRulerOn(_ on: Bool) {
        overlay.setActive(on)
        Settings.enabled = on
        setArrowKeysActive(on)
        updateStatusIcon()
    }

    // MARK: - Shortcuts

    private func registerShortcuts() {
        toggleKey = GlobalHotKey(keyCode: UInt32(kVK_ANSI_R),
                                 modifiers: Self.carbonModifiers) { [weak self] in
            self?.toggleRuler()
        }
        if toggleKey == nil {
            // A different app holds the shortcut. The menu still works.
            toggleItem?.keyEquivalent = ""
        }
    }

    /// The arrow shortcuts exist only while the ruler is on, thus the key
    /// combination stays free for other apps while the ruler is off.
    private func setArrowKeysActive(_ active: Bool) {
        stopRepeat()
        guard active else {
            arrowKeys.removeAll()
            return
        }
        guard arrowKeys.isEmpty else { return }
        for (keyCode, step) in [(kVK_UpArrow, Self.slitStep), (kVK_DownArrow, -Self.slitStep)] {
            let key = GlobalHotKey(keyCode: UInt32(keyCode),
                                   modifiers: Self.carbonModifiers,
                                   onPress: { [weak self] in self?.beginAdjust(step: step) },
                                   onRelease: { [weak self] in self?.stopRepeat() })
            if let key { arrowKeys.append(key) }
        }
    }

    /// One step at once, then a repeat while the key stays down.
    private func beginAdjust(step: Double) {
        stopRepeat()
        adjustSlit(by: step)

        repeatTimer = Timer.scheduledTimer(withTimeInterval: Self.repeatDelay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.repeatTimer = Timer.scheduledTimer(withTimeInterval: Self.repeatInterval, repeats: true) { [weak self] _ in
                guard let self else { return }
                // Safety: stop also if the release of the key was not seen.
                guard NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask) == Self.shortcutModifiers else {
                    self.stopRepeat()
                    return
                }
                self.adjustSlit(by: step)
            }
        }
    }

    private func stopRepeat() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }

    /// The overlay eases to the new height, thus the change is a movement.
    private func adjustSlit(by step: Double) {
        Settings.slitHeight += step
        sliders[.slitHeight]?.value = Settings.slitHeight
    }

    // MARK: - Open at login

    private var isOpenAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @objc private func toggleOpenAtLogin() {
        do {
            if isOpenAtLogin {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSSound.beep()
            NSLog("Screen Ruler: could not change the login item: \(error.localizedDescription)")
        }
        loginItem.state = isOpenAtLogin ? .on : .off
    }

    // MARK: - Small helpers

    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    private static let pixels: (Double) -> String = { "\(Int($0.rounded())) px" }
    private static let percent: (Double) -> String = { "\(Int(($0 * 100).rounded())) %" }
}

private extension NSFont {
    var bold: NSFont {
        NSFont(descriptor: fontDescriptor.withSymbolicTraits(.bold), size: pointSize) ?? self
    }
}
