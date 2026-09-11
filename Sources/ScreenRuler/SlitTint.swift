import AppKit

/// A colour wash over the slit. A reading ruler on paper is a transparent
/// coloured strip, and many readers find one colour more comfortable than the
/// others. The app therefore keeps the known overlay colours ready and lets
/// the user select any other colour.
struct SlitTint {
    let name: String
    let hex: String

    /// The light overlay colours that reading rulers use.
    static let presets: [SlitTint] = [
        SlitTint(name: "Butter", hex: "FFF2B2"),
        SlitTint(name: "Peach", hex: "FFDDB8"),
        SlitTint(name: "Rose", hex: "FFCBD8"),
        SlitTint(name: "Lilac", hex: "DCC9F7"),
        SlitTint(name: "Sky", hex: "BFE0F7"),
        SlitTint(name: "Aqua", hex: "B3EDE4"),
        SlitTint(name: "Mint", hex: "C9EFC7"),
        SlitTint(name: "Grey", hex: "DCDCDC"),
    ]

    var color: NSColor { SlitTint.color(fromHex: hex) ?? .white }

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
