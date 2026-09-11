import Foundation

/// User settings, kept in UserDefaults so they survive a restart.
enum Settings {
    private enum Key {
        static let enabled = "enabled"
        static let slitHeight = "slitHeight"
        static let dimOpacity = "dimOpacity"
        static let feather = "feather"
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

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
