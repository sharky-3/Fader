import AppKit

enum MediaKey: Int {
    case playPause = 16
    case next = 17
    case previous = 18
}

enum SystemKeyEmitter {
    private static let leftArrow: CGKeyCode = 0x7B
    private static let rightArrow: CGKeyCode = 0x7C

    static func post(_ key: MediaKey) {
        for isDown in [true, false] {
            let flags = NSEvent.ModifierFlags(rawValue: isDown ? 0xA00 : 0xB00)
            let data = (key.rawValue << 16) | ((isDown ? 0xA : 0xB) << 8)
            let event = NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil, subtype: 8, data1: data, data2: -1)
            event?.cgEvent?.post(tap: .cghidEventTap)
        }
    }

    static func postArrows(count: Int, forward: Bool) {
        guard count > 0 else { return }
        let keyCode = forward ? rightArrow : leftArrow
        let source = CGEventSource(stateID: .privateState)
        let target = NSWorkspace.shared.frontmostApplication?.processIdentifier
        for _ in 0..<count {
            for isDown in [true, false] {
                guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown) else { continue }
                event.flags = []
                if let target {
                    event.postToPid(target)
                } else {
                    event.post(tap: .cghidEventTap)
                }
            }
        }
    }
}
