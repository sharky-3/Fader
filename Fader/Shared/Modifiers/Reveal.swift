import SwiftUI

struct Reveal: ViewModifier {
    let isVisible: Bool
    let order: Int

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .scaleEffect(isVisible ? 1 : 0.98, anchor: .top)
            .blur(radius: isVisible ? 0 : 8)
            .animation(.spring(response: 0.8, dampingFraction: 0.9).delay(isVisible ? Double(order) * 0.07 : 0), value: isVisible)
    }
}

extension View {
    func reveal(_ isVisible: Bool, order: Int) -> some View {
        modifier(Reveal(isVisible: isVisible, order: order))
    }
}
