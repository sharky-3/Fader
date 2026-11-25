import CoreGraphics
import Foundation

struct GestureConfiguration {
    var isEnabled = true
    var edgeWidth = PreferenceDefault.edgeWidth
    var bottomHeight = PreferenceDefault.bottomHeight
    var cornerSize = GestureThresholds.cornerSize
    var activeRange: ClosedRange<Double> = 0...1
    var leftAction: GestureAction? = .brightness
    var rightAction: GestureAction? = .volume
    var bottomAction: GestureAction? = .scrub
    var brightnessEnabled = true
    var volumeEnabled = true
    var scrubEnabled = true
    var flickEnabled = true
    var tapEnabled = true
    var cornerActions: [CornerSlot: CornerAction] = [.topRight: .mute]
    var requiredModifier = ModifierRequirement.none

    static func load(from defaults: UserDefaults = .standard) -> GestureConfiguration {
        var configuration = GestureConfiguration()
        configuration.isEnabled = defaults.bool(forKey: PreferenceKey.gesturesEnabled)
        configuration.edgeWidth = defaults.double(forKey: PreferenceKey.edgeWidth).clamped(to: PreferenceDefault.edgeWidthRange)
        configuration.bottomHeight = defaults.double(forKey: PreferenceKey.bottomHeight).clamped(to: PreferenceDefault.bottomHeightRange)
        configuration.activeRange = (ActiveArea(rawValue: defaults.string(forKey: PreferenceKey.activeArea) ?? "") ?? .full).range
        configuration.leftAction = EdgeAction.assigned(to: .left, in: defaults).gestureAction
        configuration.rightAction = EdgeAction.assigned(to: .right, in: defaults).gestureAction
        configuration.bottomAction = EdgeAction.assigned(to: .bottom, in: defaults).gestureAction
        configuration.brightnessEnabled = defaults.bool(forKey: PreferenceKey.brightnessEnabled)
        configuration.volumeEnabled = defaults.bool(forKey: PreferenceKey.volumeEnabled)
        configuration.scrubEnabled = defaults.bool(forKey: PreferenceKey.scrubEnabled)
        configuration.flickEnabled = defaults.bool(forKey: PreferenceKey.flickEnabled)
        configuration.tapEnabled = defaults.bool(forKey: PreferenceKey.tapEnabled)
        configuration.cornerActions = Dictionary(uniqueKeysWithValues: CornerSlot.allCases.map { ($0, CornerAction.assigned(to: $0, in: defaults)) })
        configuration.requiredModifier = ModifierRequirement(rawValue: defaults.string(forKey: PreferenceKey.requiredModifier) ?? "") ?? .none
        return configuration
    }

    func action(for zone: EdgeZone) -> GestureAction? {
        switch zone {
        case .left: leftAction.flatMap { isEnabled($0) ? $0 : nil }
        case .right: rightAction.flatMap { isEnabled($0) ? $0 : nil }
        case .bottom: bottomAction.flatMap { isEnabled($0) ? $0 : nil }
        case .corner: nil
        }
    }

    func isEnabled(_ action: GestureAction) -> Bool {
        switch action {
        case .brightness: brightnessEnabled
        case .volume: volumeEnabled
        case .scrub: scrubEnabled || flickEnabled
        }
    }

    func cornerAction(for slot: CornerSlot) -> CornerAction {
        cornerActions[slot] ?? CornerAction.none
    }

    func cornerSlot(at point: CGPoint) -> CornerSlot? {
        let x = Double(point.x)
        let y = Double(point.y)
        let isLeft = x < cornerSize
        let isRight = x > 1 - cornerSize
        let isTop = y > 1 - cornerSize
        let isBottom = y < cornerSize
        let slot: CornerSlot
        if isTop && isLeft {
            slot = .topLeft
        } else if isTop && isRight {
            slot = .topRight
        } else if isBottom && isLeft {
            slot = .bottomLeft
        } else if isBottom && isRight {
            slot = .bottomRight
        } else {
            return nil
        }
        return cornerAction(for: slot) == CornerAction.none ? nil : slot
    }

    func zones(at point: CGPoint) -> Set<EdgeZone> {
        let x = Double(point.x)
        let y = Double(point.y)
        if cornerSlot(at: point) != nil {
            return [.corner]
        }
        var zones = Set<EdgeZone>()
        let inActiveRange = activeRange.contains(y)
        if x < edgeWidth, inActiveRange, action(for: .left) != nil {
            zones.insert(.left)
        }
        if x > 1 - edgeWidth, inActiveRange, action(for: .right) != nil {
            zones.insert(.right)
        }
        if y < bottomHeight, action(for: .bottom) != nil {
            zones.insert(.bottom)
        }
        return zones
    }
}
