import CoreGraphics
import Foundation

final class GestureRecognizer {
    private struct Candidate {
        let touchID: Int32
        let zones: Set<EdgeZone>
        let start: CGPoint
        let startTime: TimeInterval
        let cursorOrigin: CGPoint?
        var last: CGPoint
    }

    private struct Engagement {
        let action: GestureAction
        let zone: EdgeZone
        let touchID: Int32
        let startTime: TimeInterval
        let rawStart: Double
        var rawLast: Double
        var position: Double
        var time: TimeInterval
    }

    private enum Phase {
        case idle
        case blocked
        case tracking(Candidate)
        case engaged(Engagement)
    }

    let deviceID: UInt64
    private var phase = Phase.idle
    private var lastCornerTap: (slot: CornerSlot, time: TimeInterval)?

    init(deviceID: UInt64) {
        self.deviceID = deviceID
    }

    var isEngaged: Bool {
        if case .engaged = phase {
            return true
        }
        return false
    }

    func process(_ touches: [TouchSample], at time: TimeInterval, configuration: GestureConfiguration, canEngage: Bool) -> [GestureEvent] {
        let contacts = touches.filter(\.isContact)
        switch phase {
        case .idle:
            return begin(with: contacts, at: time, configuration: configuration)
        case .blocked:
            if contacts.isEmpty {
                phase = .idle
            }
            return []
        case .tracking(let candidate):
            return track(candidate, contacts: contacts, at: time, configuration: configuration, canEngage: canEngage)
        case .engaged(let engagement):
            return follow(engagement, contacts: contacts, at: time, configuration: configuration)
        }
    }

    func reset() -> [GestureEvent] {
        defer { phase = .idle }
        if case .engaged(let engagement) = phase {
            return [.cancelled(engagement.action)]
        }
        return []
    }

    private func begin(with contacts: [TouchSample], at time: TimeInterval, configuration: GestureConfiguration) -> [GestureEvent] {
        guard !contacts.isEmpty else { return [] }
        guard contacts.count == 1, configuration.isEnabled, configuration.requiredModifier.isSatisfied(by: CGEventSource.flagsState(.combinedSessionState)) else {
            phase = .blocked
            return []
        }
        let touch = contacts[0]
        let zones = configuration.zones(at: touch.point)
        guard !zones.isEmpty else {
            phase = .blocked
            return []
        }
        phase = .tracking(Candidate(touchID: touch.id, zones: zones, start: touch.point, startTime: time, cursorOrigin: CGEvent(source: nil)?.location, last: touch.point))
        return []
    }

    private func track(_ candidate: Candidate, contacts: [TouchSample], at time: TimeInterval, configuration: GestureConfiguration, canEngage: Bool) -> [GestureEvent] {
        if contacts.isEmpty {
            phase = .idle
            return finishTap(candidate, at: time, configuration: configuration)
        }
        guard contacts.count == 1, let touch = contacts.first(where: { $0.id == candidate.touchID }) else {
            phase = .blocked
            return []
        }
        var updated = candidate
        updated.last = touch.point
        phase = .tracking(updated)

        let horizontal = abs(touch.x - Double(candidate.start.x))
        let vertical = abs(touch.y - Double(candidate.start.y))
        let distance = max(horizontal, vertical)
        guard distance >= GestureThresholds.engageDistance else { return [] }

        if vertical >= horizontal * GestureThresholds.directionRatio, canEngage {
            let sideZone = candidate.zones.first { $0 == .left || $0 == .right }
            if let sideZone, let action = configuration.action(for: sideZone) {
                return engage(action, zone: sideZone, candidate: candidate, position: touch.y, at: time)
            }
        }
        if horizontal >= vertical * GestureThresholds.directionRatio, canEngage, candidate.zones.contains(.bottom), let action = configuration.action(for: .bottom) {
            return engage(action, zone: .bottom, candidate: candidate, position: touch.x, at: time)
        }
        if distance >= GestureThresholds.abandonDistance {
            phase = .blocked
        }
        return []
    }

    private func engage(_ action: GestureAction, zone: EdgeZone, candidate: Candidate, position: Double, at time: TimeInterval) -> [GestureEvent] {
        let rawStart = zone == .bottom ? Double(candidate.start.x) : Double(candidate.start.y)
        phase = .engaged(Engagement(action: action, zone: zone, touchID: candidate.touchID, startTime: candidate.startTime, rawStart: rawStart, rawLast: position, position: position, time: time))
        return [.began(action, zone: zone, deviceID: deviceID, cursorOrigin: candidate.cursorOrigin)]
    }

    private func follow(_ engagement: Engagement, contacts: [TouchSample], at time: TimeInterval, configuration: GestureConfiguration) -> [GestureEvent] {
        if contacts.isEmpty {
            phase = .idle
            return finish(engagement, at: time, configuration: configuration)
        }
        guard contacts.count == 1, let touch = contacts.first(where: { $0.id == engagement.touchID }) else {
            phase = .blocked
            return [.cancelled(engagement.action)]
        }
        let raw = engagement.zone == .bottom ? touch.x : touch.y
        let smoothed = engagement.position + (raw - engagement.position) * GestureThresholds.smoothing
        let delta = smoothed - engagement.position
        let elapsed = max(time - engagement.time, 0.001)
        var updated = engagement
        updated.rawLast = raw
        updated.position = smoothed
        updated.time = time
        phase = .engaged(updated)
        guard abs(delta) > 0.00001 else { return [] }
        return [.moved(engagement.action, delta: delta, velocity: delta / elapsed)]
    }

    private func finish(_ engagement: Engagement, at time: TimeInterval, configuration: GestureConfiguration) -> [GestureEvent] {
        let travel = engagement.rawLast - engagement.rawStart
        let isFlick = engagement.action == .scrub && configuration.flickEnabled && time - engagement.startTime <= GestureThresholds.flickMaxDuration && abs(travel) >= GestureThresholds.flickMinDistance
        if isFlick {
            return [.cancelled(engagement.action), .flick(forward: travel > 0, deviceID: deviceID)]
        }
        return [.ended(engagement.action)]
    }

    private func finishTap(_ candidate: Candidate, at time: TimeInterval, configuration: GestureConfiguration) -> [GestureEvent] {
        let moved = max(abs(candidate.last.x - candidate.start.x), abs(candidate.last.y - candidate.start.y))
        guard time - candidate.startTime <= GestureThresholds.tapMaxDuration, Double(moved) <= GestureThresholds.tapMaxDistance else { return [] }
        if candidate.zones.contains(.corner), let slot = configuration.cornerSlot(at: candidate.start) {
            if let last = lastCornerTap, last.slot == slot, time - last.time <= GestureThresholds.doubleTapInterval {
                lastCornerTap = nil
                return [.cornerDoubleTap(configuration.cornerAction(for: slot), deviceID: deviceID)]
            }
            lastCornerTap = (slot, time)
            return []
        }
        return []
    }
}
