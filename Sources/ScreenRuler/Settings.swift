import AppKit

/// User settings, kept in UserDefaults so they survive a restart.
enum Settings {
    private enum Key {
        static let enabled = "enabled"
        static let slitHeight = "slitHeight"
        static let dimOpacity = "dimOpacity"
        static let feather = "feather"
        static let slitShortcut = "slitShortcut"
        static let tintHex = "tintHex"
        static let tintStrength = "tintStrength"
    }

    /// Limits used by the sliders and by the clamping below.
    static let slitHeightRange: ClosedRange<Double> = 12...300
    static let dimOpacityRange: ClosedRange<Double> = 0.1...0.95
    static let featherRange: ClosedRange<Double> = 0...80
    static let tintStrengthRange: ClosedRange<Double> = 0.04...0.45

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Key.enabled: true,
            Key.slitHeight: 64.0,
            Key.dimOpacity: 0.6,
            Key.feather: 16.0,
            Key.slitShortcut: SlitShortcut.commaPeriod.rawValue,
            Key.tintHex: "",                 // empty: no colour over the slit
            Key.tintStrength: 0.18,
        ])
    }

    static var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: Key.enabled) }
        set { UserDefaults.standard.set(newValue, forKey: Key.enabled) }
    }

    static var slitHeight: Double {
        get { clamp(UserDefaults.standard.double(forKey: Key.slitHeight), to: slitHeightRange) }
        set { UserDefaults.standard.set(clamp(newValue, to: slitHeightRange), forKey: Key.slitHeight) }
    }

    static var dimOpacity: Double {
        get { clamp(UserDefaults.standard.double(forKey: Key.dimOpacity), to: dimOpacityRange) }
        set { UserDefaults.standard.set(clamp(newValue, to: dimOpacityRange), forKey: Key.dimOpacity) }
    }

    static var feather: Double {
        get { clamp(UserDefaults.standard.double(forKey: Key.feather), to: featherRange) }
        set { UserDefaults.standard.set(clamp(newValue, to: featherRange), forKey: Key.feather) }
    }

    /// The colour over the slit, or nil for a clear slit.
    static var tintColor: NSColor? {
        get {
            let hex = UserDefaults.standard.string(forKey: Key.tintHex) ?? ""
            return hex.isEmpty ? nil : SlitTint.color(fromHex: hex)
        }
        set {
            let hex = newValue.flatMap(SlitTint.hex(from:)) ?? ""
            UserDefaults.standard.set(hex, forKey: Key.tintHex)
        }
    }

    /// "RRGGBB" of the colour over the slit, empty for a clear slit.
    static var tintHex: String {
        get { UserDefaults.standard.string(forKey: Key.tintHex) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Key.tintHex) }
    }

    /// How strong the colour is over the slit.
    static var tintStrength: Double {
        get { clamp(UserDefaults.standard.double(forKey: Key.tintStrength), to: tintStrengthRange) }
        set { UserDefaults.standard.set(clamp(newValue, to: tintStrengthRange), forKey: Key.tintStrength) }
    }

    /// The key pair that changes the slit height.
    static var slitShortcut: SlitShortcut {
        get {
            let raw = UserDefaults.standard.string(forKey: Key.slitShortcut) ?? ""
            return SlitShortcut(rawValue: raw) ?? .commaPeriod
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.slitShortcut) }
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
