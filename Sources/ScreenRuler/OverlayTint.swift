import AppKit

/// A colour for the dark part of the screen. Pure black is correct but hard
/// for some readers; a colour cast over the dark part is calmer, and it keeps
/// the line under the slit fully clear.
///
/// The colour is mixed into black, it does not replace it. A light colour on
/// its own would make the screen brighter, not darker.
struct OverlayTint {
    let name: String
    let hex: String

    /// The colour casts to select from.
    static let presets: [OverlayTint] = [
        OverlayTint(name: "Sepia", hex: "C08A45"),
        OverlayTint(name: "Butter", hex: "FFF2B2"),
        OverlayTint(name: "Peach", hex: "FFDDB8"),
        OverlayTint(name: "Rose", hex: "FFCBD8"),
        OverlayTint(name: "Lilac", hex: "DCC9F7"),
        OverlayTint(name: "Sky", hex: "BFE0F7"),
        OverlayTint(name: "Aqua", hex: "B3EDE4"),
        OverlayTint(name: "Mint", hex: "C9EFC7"),
    ]

    var color: NSColor { OverlayTint.color(fromHex: hex) ?? .black }

    /// The colour of the dark part: black with a part of the tint in it, and
    /// the alpha of the dim setting.
    static func dimColor(tint: NSColor?, strength: Double, opacity: Double) -> NSColor {
        let black = NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        guard let tint, let mixed = black.blended(withFraction: CGFloat(strength), of: tint) else {
            return black.withAlphaComponent(CGFloat(opacity))
        }
        return mixed.withAlphaComponent(CGFloat(opacity))
    }

    /// "RRGGBB" to a colour in the sRGB space.
    static func color(fromHex hex: String) -> NSColor? {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
                       green: CGFloat((value >> 8) & 0xFF) / 255,
                       blue: CGFloat(value & 0xFF) / 255,
                       alpha: 1)
    }

    /// A colour to "RRGGBB". The colour goes to sRGB first, because a colour
    /// from the colour panel can be in a different space.
    static func hex(from color: NSColor) -> String? {
        guard let srgb = color.usingColorSpace(.sRGB) else { return nil }
        let value = (Int(srgb.redComponent * 255) << 16)
            | (Int(srgb.greenComponent * 255) << 8)
            | Int(srgb.blueComponent * 255)
        return String(format: "%06X", value)
    }

    /// The name of the preset with this colour, or nil for an own colour.
    static func presetName(forHex hex: String) -> String? {
        presets.first { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }?.name
    }
}
