import AppKit

enum SystemOSD {
    private typealias ShowFunction = @convention(c) (AnyObject, Selector, Int64, UInt32, UInt32, UInt32, UInt32, UInt32, Bool) -> Void

    private static let selector = NSSelectorFromString("showImage:onDisplayID:priority:msecUntilFade:filledChiclets:totalChiclets:locked:")

    private static let manager: NSObject? = {
        _ = dlopen("/System/Library/PrivateFrameworks/OSD.framework/OSD", RTLD_LAZY)
        guard let managerClass = NSClassFromString("OSDManager") as? NSObject.Type else { return nil }
        let shared = NSSelectorFromString("sharedManager")
        guard managerClass.responds(to: shared), let instance = managerClass.perform(shared)?.takeUnretainedValue() as? NSObject, instance.responds(to: selector) else { return nil }
        return instance
    }()

    static var isAvailable: Bool { manager != nil }

    static func show(_ state: LevelState) -> Bool {
        guard let manager, state.isAvailable else { return false }
        let image: Int64
        switch state.kind {
        case .brightness: image = 1
        case .volume: image = state.isMuted || state.value == 0 ? 4 : 3
        }
        let display = NSScreen.underPointer?.displayID ?? CGMainDisplayID()
        let filled = state.isMuted ? 0 : UInt32((state.value * 100).rounded())
        let function = unsafeBitCast(manager.method(for: selector), to: ShowFunction.self)
        function(manager, selector, image, display, 0x1F4, 1000, filled, 100, false)
        return true
    }
}
