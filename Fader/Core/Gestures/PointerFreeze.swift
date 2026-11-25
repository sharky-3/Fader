import CoreGraphics
import Foundation

final class PointerFreeze {
    static var isActive = false
    static var deadline: CFAbsoluteTime = 0

    private static var tap: CFMachPort?
    private static var source: CFRunLoopSource?

    static func install() {
        guard tap == nil else { return }
        let types: [CGEventType] = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << CGEventMask($1.rawValue)) }
        let callback: CGEventTapCallBack = { _, type, event, _ in
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                PointerFreeze.reenable()
                return Unmanaged.passUnretained(event)
            }
            if PointerFreeze.isActive, CFAbsoluteTimeGetCurrent() < PointerFreeze.deadline {
                return nil
            }
            return Unmanaged.passUnretained(event)
        }
        guard let port = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: callback, userInfo: nil) else { return }
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        tap = port
        source = runLoopSource
    }

    static func activate() {
        install()
        deadline = CFAbsoluteTimeGetCurrent() + 30
        isActive = true
    }

    static func deactivate() {
        isActive = false
    }

    private static func reenable() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}
