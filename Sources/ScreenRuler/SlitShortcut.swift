import AppKit
import Carbon.HIToolbox

/// The key pair that changes the slit height. The user can select a different
/// pair, because an other app can already use one. Rectangle, for example,
/// uses ⌃⌥⌘ with the arrow keys to move a window to the next display.
///
/// A pair is written as characters, not as key codes, thus the app finds the
/// correct keys on every keyboard layout.
enum SlitShortcut: String, CaseIterable {
    case plusMinus
    case brackets
    case letters
    case arrows

    /// One registered key: a key code plus the shift state.
    typealias Key = KeyboardLayout.Stroke

    /// Name in the menu.
    var title: String {
        switch self {
        case .plusMinus: return "⌃⌥⌘ −  and  ⌃⌥⌘ +"
        case .brackets:  return "⌃⌥⌘ [  and  ⌃⌥⌘ ]"
        case .letters:   return "⌃⌥⌘ J  and  ⌃⌥⌘ K"
        case .arrows:    return "⌃⌥⌘ ↓  and  ⌃⌥⌘ ↑"
        }
    }

    /// Short form for the hint line.
    var hint: String {
        switch self {
        case .plusMinus: return "⌃⌥⌘−  ⌃⌥⌘+"
        case .brackets:  return "⌃⌥⌘[  ⌃⌥⌘]"
        case .letters:   return "⌃⌥⌘J  ⌃⌥⌘K"
        case .arrows:    return "⌃⌥⌘↓  ⌃⌥⌘↑"
        }
    }

    /// A note about a known conflict, or nil.
    var warning: String? {
        self == .arrows ? "Rectangle and other window tools often use this pair." : nil
    }

    /// The keys for the current keyboard layout, or nil if the layout cannot
    /// make the characters of the pair with ⇧ only.
    var keys: (smaller: [Key], bigger: [Key])? {
        if self == .arrows {
            return (smaller: [Key(code: UInt32(kVK_DownArrow), shift: false)],
                    bigger: [Key(code: UInt32(kVK_UpArrow), shift: false)])
        }
        guard let smaller = resolve(characters: smallerCharacters),
              let bigger = resolve(characters: biggerCharacters) else { return nil }
        return (smaller, bigger)
    }

    /// The first character is the one of the name of the pair. A character
    /// after it is an alternative that is welcome but not necessary.
    private var smallerCharacters: [String] {
        switch self {
        case .plusMinus: return ["-"]
        case .brackets:  return ["["]
        case .letters:   return ["j"]
        case .arrows:    return []
        }
    }

    private var biggerCharacters: [String] {
        switch self {
        case .plusMinus: return ["+", "="]   // "=" sits next to "+" on many layouts
        case .brackets:  return ["]"]
        case .letters:   return ["k"]
        case .arrows:    return []
        }
    }

    /// Finds the keys of the characters. The first character must exist, an
    /// alternative is used only when it needs no ⇧, so that the app does not
    /// hold back a shifted key combination that the user did not ask for.
    private func resolve(characters: [String]) -> [Key]? {
        guard let first = characters.first, let primary = KeyboardLayout.stroke(for: first) else { return nil }
        var keys = [primary]
        for alternative in characters.dropFirst() {
            guard let key = KeyboardLayout.stroke(for: alternative), !key.shift, !keys.contains(key) else { continue }
            keys.append(key)
        }
        return keys
    }
}

extension KeyboardLayout.Stroke {
    /// The modifiers for RegisterEventHotKey: ⌃⌥⌘, plus ⇧ if the character
    /// needs it.
    var carbonModifiers: UInt32 {
        UInt32(controlKey | optionKey | cmdKey) | (shift ? UInt32(shiftKey) : 0)
    }
}
