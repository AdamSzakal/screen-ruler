import AppKit
import Carbon.HIToolbox
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let overlay = OverlayController()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var menu: NSMenu!
    private var toggleItem: NSMenuItem!
    private var loginItem: NSMenuItem!
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Settings.registerDefaults()
        buildStatusItem()
        buildMenu()
        registerHotKey()
        setRulerOn(Settings.enabled)
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlay.setActive(false)
    }

    // MARK: - Status item

    private func buildStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "Screen Ruler — click to switch on or off, right click for settings"
        updateStatusIcon()
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        let name = overlay.isActive ? "ruler.fill" : "ruler"
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: "Screen Ruler")
        button.image?.isTemplate = true
        button.appearsDisabled = !overlay.isActive
    }

    @objc private func statusItemClicked() {
        // Left click switches the ruler; right click opens the settings menu.
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            toggleRuler()
        }
    }

    private func showMenu() {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil   // keep the left click free for the switch
    }

    // MARK: - Menu

    private func buildMenu() {
        menu = NSMenu()
        menu.delegate = self

        toggleItem = NSMenuItem(title: "Enable Ruler", action: #selector(toggleRuler), keyEquivalent: "r")
        toggleItem.keyEquivalentModifierMask = [.control, .option, .command]
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        addSlider(title: "Slit height",
                  range: Settings.slitHeightRange,
                  value: Settings.slitHeight,
                  format: { "\(Int($0.rounded())) px" },
                  onChange: { Settings.slitHeight = $0 })

        addSlider(title: "Dim amount",
                  range: Settings.dimOpacityRange,
                  value: Settings.dimOpacity,
                  format: { "\(Int(($0 * 100).rounded())) %" },
                  onChange: { Settings.dimOpacity = $0 })

        addSlider(title: "Edge softness",
                  range: Settings.featherRange,
                  value: Settings.feather,
                  format: { "\(Int($0.rounded())) px" },
                  onChange: { Settings.feather = $0 })

        menu.addItem(.separator())
        loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)

        let quit = NSMenuItem(title: "Quit Screen Ruler", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    private func addSlider(title: String,
                           range: ClosedRange<Double>,
                           value: Double,
                           format: @escaping (Double) -> String,
                           onChange: @escaping (Double) -> Void) {
        let item = NSMenuItem()
        item.view = SliderMenuItemView(title: title, range: range, value: value, format: format) { [weak self] newValue in
            onChange(newValue)
            self?.overlay.refresh()
        }
        menu.addItem(item)
    }

    func menuWillOpen(_ menu: NSMenu) {
        toggleItem.state = overlay.isActive ? .on : .off
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
        updateStatusIcon()
    }

    private func registerHotKey() {
        hotKey = GlobalHotKey(keyCode: UInt32(kVK_ANSI_R),
                              modifiers: UInt32(controlKey | optionKey | cmdKey)) { [weak self] in
            self?.toggleRuler()
        }
        if hotKey == nil {
            // A different app holds the shortcut. The menu still works.
            toggleItem?.keyEquivalent = ""
        }
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
}
