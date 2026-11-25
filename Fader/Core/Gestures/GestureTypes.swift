import CoreGraphics

enum GestureAction: Equatable {
    case brightness
    case volume
    case scrub
}

enum EdgeZone: Hashable {
    case left
    case right
    case bottom
    case corner
}

struct TouchSample: Identifiable, Equatable {
    let id: Int32
    let x: Double
    let y: Double
    let isContact: Bool
    let size: Double

    var point: CGPoint { CGPoint(x: x, y: y) }
}

enum GestureEvent {
    case began(GestureAction, zone: EdgeZone, deviceID: UInt64, cursorOrigin: CGPoint?)
    case moved(GestureAction, delta: Double, velocity: Double)
    case ended(GestureAction)
    case cancelled(GestureAction)
    case flick(forward: Bool, deviceID: UInt64)
    case tap(deviceID: UInt64)
    case cornerDoubleTap(CornerAction, deviceID: UInt64)
}
