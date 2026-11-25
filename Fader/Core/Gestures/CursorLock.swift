import CoreGraphics

@MainActor
enum CursorLock {
    private(set) static var isLocked = false

    static func lock(at origin: CGPoint?) {
        guard !isLocked else { return }
        PointerFreeze.activate()
        if let origin {
            CGWarpMouseCursorPosition(origin)
        }
        CGAssociateMouseAndMouseCursorPosition(0)
        isLocked = true
    }

    static func unlock() {
        guard isLocked else { return }
        PointerFreeze.deactivate()
        CGAssociateMouseAndMouseCursorPosition(1)
        isLocked = false
    }
}
