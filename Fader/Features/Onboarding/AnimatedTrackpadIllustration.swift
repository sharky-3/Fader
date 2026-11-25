import SwiftUI

struct AnimatedTrackpadIllustration: View {
    private struct Frame {
        let zone: EdgeZone
        let point: CGPoint
        let isTouching: Bool
        let caption: String
    }

    private let segment = 2.2

    var body: some View {
        TimelineView(.animation) { context in
            let frame = frame(at: context.date.timeIntervalSinceReferenceDate)
            VStack(spacing: 14) {
                TrackpadZonesView(highlighted: [frame.zone], touches: frame.isTouching ? [TouchSample(id: 1, x: frame.point.x, y: frame.point.y, isContact: true, size: 1)] : [])
                Text(frame.caption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .id(frame.caption)
                    .transition(.opacity)
            }
        }
    }

    private func frame(at time: TimeInterval) -> Frame {
        let cycle = time.truncatingRemainder(dividingBy: segment * 4)
        let index = Int(cycle / segment)
        let progress = (cycle - Double(index) * segment) / segment
        let eased = ease(((progress - 0.12) / 0.7).clamped(to: 0...1))
        let isTouching = progress > 0.08 && progress < 0.9
        switch index {
        case 0:
            return Frame(zone: .left, point: CGPoint(x: 0.04, y: 0.25 + 0.55 * eased), isTouching: isTouching, caption: "Left edge · Brightness")
        case 1:
            return Frame(zone: .right, point: CGPoint(x: 0.96, y: 0.8 - 0.5 * eased), isTouching: isTouching, caption: "Right edge · Volume")
        case 2:
            return Frame(zone: .bottom, point: CGPoint(x: 0.25 + 0.5 * eased, y: 0.05), isTouching: isTouching, caption: "Bottom edge · Scrub")
        default:
            let tapping = (progress > 0.2 && progress < 0.32) || (progress > 0.42 && progress < 0.54)
            return Frame(zone: .corner, point: CGPoint(x: 0.93, y: 0.9), isTouching: tapping, caption: "Top-right corner · Double-tap to mute")
        }
    }

    private func ease(_ value: Double) -> Double {
        value < 0.5 ? 4 * value * value * value : 1 - pow(-2 * value + 2, 3) / 2
    }
}
