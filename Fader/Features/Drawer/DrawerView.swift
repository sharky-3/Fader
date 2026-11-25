import SwiftUI

struct DrawerView: View {
    @ObservedObject var model: DrawerModel
    let environment: AppEnvironment
    let onClose: () -> Void

    private var direction: CGFloat {
        model.edge == .right ? 1 : -1
    }

    var body: some View {
        ZStack(alignment: model.edge == .right ? .trailing : .leading) {
            DrawerShape(progress: model.progress, edge: model.edge, size: model.contentSize, fillet: model.fillet, cornerRadius: model.cornerRadius)
                .fill(.black)
            ScrollView(.vertical, showsIndicators: false) {
                SettingsView(environment: environment, onClose: onClose)
            }
            .frame(width: model.contentSize.width, height: model.contentSize.height)
            .opacity(model.showsContent ? 1 : 0)
                .blur(radius: model.showsContent ? 0 : 4)
                .offset(x: model.showsContent ? 0 : 14 * direction)
                .allowsHitTesting(model.showsContent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
