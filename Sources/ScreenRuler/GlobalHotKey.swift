import AppKit
import Carbon.HIToolbox

/// A system wide keyboard shortcut, made with the Carbon hot key API.
/// This API needs no accessibility permission, different from an event tap.
/// It also holds the key combination back from the app below.
final class GlobalHotKey {
    private typealias Actions = (press: () -> Void, release: (() -> Void)?)

    private static var actions: [UInt32: Actions] = [:]
    private static var nextID: UInt32 = 1
    private static var handlerInstalled = false

    private var hotKeyRef: EventHotKeyRef?
    private let identifier: UInt32

    /// Returns nil if the shortcut is already in use by a different app.
    init?(keyCode: UInt32,
          modifiers: UInt32,
          onPress: @escaping () -> Void,
          onRelease: (() -> Void)? = nil) {
        GlobalHotKey.installHandlerIfNeeded()
        identifier = GlobalHotKey.nextID
        GlobalHotKey.nextID += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x5352_554C), id: identifier) // 'SRUL'
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return nil }
        hotKeyRef = ref
        GlobalHotKey.actions[identifier] = (onPress, onRelease)
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        GlobalHotKey.actions[identifier] = nil
    }

    private static func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var specs = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            guard let event else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil,
                                           MemoryLayout<EventHotKeyID>.size,
                                           nil,
                                           &hotKeyID)
            guard status == noErr, let actions = GlobalHotKey.actions[hotKeyID.id] else { return status }

            if GetEventKind(event) == UInt32(kEventHotKeyPressed) {
                actions.press()
            } else {
                actions.release?()
            }
            return noErr
        }, specs.count, &specs, nil, nil)
    }
}
