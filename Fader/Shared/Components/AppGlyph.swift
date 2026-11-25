import SwiftUI

struct AppGlyph: View {
    var size: CGFloat = 32
    var level: CGFloat = 1

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
            .fill(.white)
            .overlay {
                HStack(spacing: size * 0.2) {
                    bar(Palette.brightness)
                    bar(Palette.volume)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 0.5)
            }
            .frame(width: size, height: size)
    }

    private func bar(_ tint: Color) -> some View {
        Capsule(style: .continuous)
            .fill(tint)
            .frame(width: size * 0.13, height: size * 0.52 * max(level, 0.15))
    }
}
