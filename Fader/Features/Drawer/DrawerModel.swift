import SwiftUI

enum DrawerEdge {
    case left
    case right
}

@MainActor
final class DrawerModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var showsContent = false
    @Published var edge = DrawerEdge.right
    @Published var contentSize = CGSize(width: 380, height: 640)

    let fillet: CGFloat = 28
    let cornerRadius: CGFloat = 30
    let overshootRoom: CGFloat = 50

    var panelSize: CGSize {
        CGSize(width: contentSize.width + overshootRoom, height: contentSize.height + fillet * 2 + 30)
    }
}
