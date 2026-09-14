import AppKit

/// Which side of the slit gets the dark part. A paper reading ruler covers
/// one side only, therefore the user can do the same here.
enum DimSides: String, CaseIterable {
    case both, above, below

    /// The name of the choice in the menu.
    var title: String {
        switch self {
        case .both: return "Above and Below"
        case .above: return "Above Only"
        case .below: return "Below Only"
        }
    }
}

/// User settings, kept in UserDefaults so they survive a restart.
enum Settings {
    private enum Key {
        static let enabled = "enabled"
        static let slitHeight = "slitHeight"
        static let dimOpacity = "dimOpacity"
        static let feather = "feather"
        static let tintHex = "tintHex"
        static let dimSides = "dimSides"
    }

    /// Limits used by the sliders and by the clamping below.
    static let slitHeightRange: ClosedRange<Double> = 12...300
    static let dimOpacityRange: ClosedRange<Double> = 0.1...0.95
    static let featherRange: ClosedRange<Double> = 0...80

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Key.enabled: true,
            Key.slitHeight: 64.0,
            Key.dimOpacity: 0.6,
            Key.feather: 16.0,
            Key.tintHex: "",                 // empty: plain black
            Key.dimSides: DimSides.both.rawValue,
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

    /// The side or sides of the slit that go dark.
    static var dimSides: DimSides {
        get { DimSides(rawValue: UserDefaults.standard.string(forKey: Key.dimSides) ?? "") ?? .both }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.dimSides) }
    }

    /// The colour that is mixed into the dark part, or nil for plain black.
    static var tintColor: NSColor? {
        get {
            let hex = UserDefaults.standard.string(forKey: Key.tintHex) ?? ""
            return hex.isEmpty ? nil : OverlayTint.color(fromHex: hex)
        }
        set {
            let hex = newValue.flatMap(OverlayTint.hex(from:)) ?? ""
            UserDefaults.standard.set(hex, forKey: Key.tintHex)
        }
    }

    /// "RRGGBB" of the colour of the dark part, empty for plain black.
    static var tintHex: String {
        get { UserDefaults.standard.string(forKey: Key.tintHex) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Key.tintHex) }
    }

    /// The colour of the dark part, ready to draw.
    static var dimColor: NSColor {
        OverlayTint.dimColor(tint: tintColor, opacity: dimOpacity)
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
