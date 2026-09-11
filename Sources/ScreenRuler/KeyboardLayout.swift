import AppKit
import Carbon.HIToolbox

/// Finds the key that makes a given character on the keyboard layout that the
/// user has now.
///
/// A Carbon hot key uses a physical key code. The same code makes a different
/// character on each layout: the code of "-" on a US keyboard is the key of
/// "+" on a Swedish keyboard. Therefore the app asks the layout which key
/// makes the character, and registers that key.
enum KeyboardLayout {
    /// A key and the shift state that together make one character.
    struct Stroke: Equatable {
        let code: UInt32
        let shift: Bool
    }

    /// Highest key code that a keyboard layout describes.
    private static let maxKeyCode: UInt32 = 127

    /// Keys of the numeric keypad. They are not used, because the key of the
    /// main keyboard must win: on a US keyboard "+" is ⇧= there, but the
    /// keypad also makes "+" and has a lower key code.
    private static let keypadCodes: Set<UInt32> = [
        kVK_ANSI_Keypad0, kVK_ANSI_Keypad1, kVK_ANSI_Keypad2, kVK_ANSI_Keypad3,
        kVK_ANSI_Keypad4, kVK_ANSI_Keypad5, kVK_ANSI_Keypad6, kVK_ANSI_Keypad7,
        kVK_ANSI_Keypad8, kVK_ANSI_Keypad9, kVK_ANSI_KeypadDecimal,
        kVK_ANSI_KeypadMultiply, kVK_ANSI_KeypadPlus, kVK_ANSI_KeypadClear,
        kVK_ANSI_KeypadDivide, kVK_ANSI_KeypadEnter, kVK_ANSI_KeypadMinus,
        kVK_ANSI_KeypadEquals,
    ].map(UInt32.init).reduce(into: Set<UInt32>()) { $0.insert($1) }

    /// Returns the stroke for the character, or nil if the layout cannot make
    /// the character without more modifier keys (for example "[" on a Swedish
    /// keyboard, which needs ⌥8).
    static func stroke(for character: String) -> Stroke? {
        guard let layout = currentLayoutData() else { return nil }
        // Without shift first, so that the simple key wins.
        for shift in [false, true] {
            for code in 0...maxKeyCode where !keypadCodes.contains(code)
                && character == text(from: code, shift: shift, layout: layout) {
                return Stroke(code: code, shift: shift)
            }
        }
        return nil
    }

    /// The notification that macOS sends when the user selects a different
    /// keyboard layout.
    static let didChangeNotification = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)

    private static func currentLayoutData() -> Data? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let property = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        return Unmanaged<CFData>.fromOpaque(property).takeUnretainedValue() as Data
    }

    private static func text(from code: UInt32, shift: Bool, layout: Data) -> String? {
        var deadKeyState: UInt32 = 0
        var characters = [UniChar](repeating: 0, count: 4)
        var length = 0
        // UCKeyTranslate wants the modifiers in the form of the old Event Manager.
        let modifierState = UInt32(shift ? (shiftKey >> 8) : 0)

        let status = layout.withUnsafeBytes { buffer -> OSStatus in
            guard let base = buffer.baseAddress else { return OSStatus(paramErr) }
            return UCKeyTranslate(base.assumingMemoryBound(to: UCKeyboardLayout.self),
                                  UInt16(code),
                                  UInt16(kUCKeyActionDown),
                                  modifierState,
                                  UInt32(LMGetKbdType()),
                                  OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                  &deadKeyState,
                                  characters.count,
                                  &length,
                                  &characters)
        }
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: characters, count: length)
    }
}
