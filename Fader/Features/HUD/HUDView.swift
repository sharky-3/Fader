import SwiftUI

struct HUDView: View {
    @ObservedObject var model: HUDModel

    var body: some View {
        ZStack(alignment: model.content?.placement == .bottom ? .bottom : .center) {
            Color.clear
            if let content = model.content {
                pill(for: content)
                    .padding(.bottom, content.placement == .bottom ? HUDLayout.margin : 0)
            }
        }
        .opacity(model.isVisible ? 1 : 0)
        .scaleEffect(model.isVisible ? 1 : 0.88, anchor: anchor)
        .blur(radius: model.isVisible ? 0 : 4)
    }

    private var anchor: UnitPoint {
        switch model.content?.placement {
        case .left: .leading
        case .right: .trailing
        default: .bottom
        }
    }

    @ViewBuilder
    private func pill(for content: HUDContent) -> some View {
        switch content {
        case .level(let state):
            HUDLevelPill(state: state)
        case .scrub(let state):
            HUDScrubPill(state: state)
        case .media(let glyph):
            HUDMediaPill(glyph: glyph)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}
