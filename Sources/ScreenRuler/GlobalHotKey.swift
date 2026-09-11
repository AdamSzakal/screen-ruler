import AppKit
import Carbon.HIToolbox

/// A system wide keyboard shortcut, made with the Carbon hot key API.
/// This API needs no accessibility permission, different from an event tap.
final class GlobalHotKey {
    private static var actions: [UInt32: () -> Void] = [:]
    private static var nextID: UInt32 = 1
    private static var handlerInstalled = false

    private var hotKeyRef: EventHotKeyRef?
    private let identifier: UInt32

    /// Returns nil if the shortcut is already in use by a different app.
    init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        GlobalHotKey.installHandlerIfNeeded()
        identifier = GlobalHotKey.nextID
        GlobalHotKey.nextID += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x5352_554C), id: identifier) // 'SRUL'
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return nil }
        hotKeyRef = ref
        GlobalHotKey.actions[identifier] = action
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        GlobalHotKey.actions[identifier] = nil
    }

    private static func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
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
            guard status == noErr else { return status }
            GlobalHotKey.actions[hotKeyID.id]?()
            return noErr
        }, 1, &spec, nil, nil)
    }
}
