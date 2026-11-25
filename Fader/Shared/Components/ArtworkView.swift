import SwiftUI

struct ArtworkView: View {
    let image: NSImage?
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(colors: [Palette.media.opacity(0.8), Palette.mute.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
    }
}
