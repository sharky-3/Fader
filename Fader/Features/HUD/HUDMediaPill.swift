import SwiftUI

struct HUDMediaPill: View {
    let glyph: MediaGlyph

    private var size: CGSize { HUDLayout.mediaSize }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 24)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
        .frame(width: size.width, height: size.height)
        .background(GlassSurface(cornerRadius: size.height / 2))
        .id(glyph)
    }

    private var symbol: String {
        switch glyph {
        case .play: "play.fill"
        case .pause: "pause.fill"
        case .next: "forward.fill"
        case .previous: "backward.fill"
        }
    }

    private var title: String {
        switch glyph {
        case .play: "Playing"
        case .pause: "Paused"
        case .next: "Next Track"
        case .previous: "Previous Track"
        }
    }
}
