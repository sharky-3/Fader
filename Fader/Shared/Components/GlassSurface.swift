import SwiftUI

struct GlassSurface: View {
    let cornerRadius: CGFloat
    var material: NSVisualEffectView.Material = .hudWindow

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            shape
                .fill(.black.opacity(colorScheme == .dark ? 0.35 : 0.16))
                .blur(radius: 16)
                .offset(y: 8)
                .padding(4)
            VisualEffectBlur(material: material, cornerRadius: cornerRadius)
            shape.fill(colorScheme == .dark ? .white.opacity(0.04) : .white.opacity(0.35))
            shape.strokeBorder(colorScheme == .dark ? .white.opacity(0.14) : .black.opacity(0.07), lineWidth: 0.5)
        }
    }
}
