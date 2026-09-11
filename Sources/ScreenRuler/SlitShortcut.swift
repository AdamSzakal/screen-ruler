import AppKit
import Carbon.HIToolbox

/// The key pair that changes the slit height. The user can select a different
/// pair, because an other app can already use one. Rectangle, for example,
/// uses ⌃⌥⌘ with the arrow keys to move a window to the next display.
enum SlitShortcut: String, CaseIterable {
    case plusMinus
    case brackets
    case letters
    case arrows

    /// A key of the pair. The same key can be listed two times, with ⇧ and
    /// without it, so that ⌃⌥⌘= and ⌃⌥⌘+ both work.
    struct Key {
        let code: UInt32
        let shift: Bool

        var carbonModifiers: UInt32 {
            UInt32(controlKey | optionKey | cmdKey) | (shift ? UInt32(shiftKey) : 0)
        }
    }

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

    /// Keys that make the slit lower.
    var smaller: [Key] {
        switch self {
        case .plusMinus: return [Key(code: UInt32(kVK_ANSI_Minus), shift: false),
                                 Key(code: UInt32(kVK_ANSI_Minus), shift: true)]
        case .brackets:  return [Key(code: UInt32(kVK_ANSI_LeftBracket), shift: false)]
        case .letters:   return [Key(code: UInt32(kVK_ANSI_J), shift: false)]
        case .arrows:    return [Key(code: UInt32(kVK_DownArrow), shift: false)]
        }
    }

    /// Keys that make the slit higher.
    var bigger: [Key] {
        switch self {
        case .plusMinus: return [Key(code: UInt32(kVK_ANSI_Equal), shift: false),
                                 Key(code: UInt32(kVK_ANSI_Equal), shift: true)]
        case .brackets:  return [Key(code: UInt32(kVK_ANSI_RightBracket), shift: false)]
        case .letters:   return [Key(code: UInt32(kVK_ANSI_K), shift: false)]
        case .arrows:    return [Key(code: UInt32(kVK_UpArrow), shift: false)]
        }
    }
}
