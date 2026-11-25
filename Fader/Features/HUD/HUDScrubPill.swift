import SwiftUI

struct HUDScrubPill: View {
    let state: ScrubState

    private var size: CGSize { HUDLayout.scrubSize }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: state.offset < 0 ? "gobackward" : "goforward")
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 30)
                .rotationEffect(.degrees(state.offset.clamped(to: -30...30)))
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(state.title ?? "Now Playing")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    Text(state.offset.signedTimecode)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
                if let duration = state.duration, state.isTimeline {
                    TimelineBar(progress: state.target / duration, origin: state.startElapsed / duration)
                        .frame(height: 6)
                    HStack {
                        Text(state.target.timecode)
                        Spacer()
                        Text("−" + (duration - state.target).timecode)
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                } else {
                    Text(state.needsPermission ? "Allow Accessibility in Settings to seek" : "Seeking the frontmost player")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .frame(width: size.width, height: size.height)
        .background(GlassSurface(cornerRadius: size.height / 2))
    }
}

private struct TimelineBar: View {
    let progress: Double
    let origin: Double

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.primary.opacity(0.12))
                Capsule(style: .continuous)
                    .fill(.primary)
                    .frame(width: width * progress.clamped(to: 0...1))
                Capsule(style: .continuous)
                    .fill(.primary.opacity(0.45))
                    .frame(width: 2, height: 12)
                    .offset(x: width * origin.clamped(to: 0...1) - 1)
            }
        }
        .animation(.interactiveSpring(response: 0.16, dampingFraction: 0.88), value: progress)
    }
}
