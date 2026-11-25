import SwiftUI

struct HUDLevelPill: View {
    let state: LevelState

    private var size: CGSize { HUDLayout.levelSize }

    var body: some View {
        VStack(spacing: 14) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .frame(height: 16)
            LevelTrack(value: state.isAvailable ? displayValue : 0)
                .frame(width: 8)
                .opacity(state.isAvailable ? 1 : 0.35)
            Image(systemName: symbol, variableValue: state.isAvailable ? displayValue : nil)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 24)
        }
        .padding(.vertical, 22)
        .frame(width: size.width, height: size.height)
        .background(GlassSurface(cornerRadius: size.width / 2))
    }

    private var displayValue: Double {
        state.kind == .volume && state.isMuted ? 0 : state.value
    }

    private var label: String {
        guard state.isAvailable else { return "—" }
        if state.kind == .volume, state.isMuted {
            return "Mute"
        }
        return state.value.percentText
    }

    private var symbol: String {
        switch state.kind {
        case .brightness:
            return "sun.max.fill"
        case .volume:
            return state.isMuted || state.value == 0 ? "speaker.slash.fill" : "speaker.wave.3.fill"
        }
    }
}

private struct LevelTrack: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Capsule(style: .continuous)
                    .fill(.primary.opacity(0.12))
                Capsule(style: .continuous)
                    .fill(.primary)
                    .frame(height: proxy.size.height * value)
            }
        }
        .animation(.interactiveSpring(response: 0.16, dampingFraction: 0.88), value: value)
    }
}
