import Combine

final class TouchFeed: ObservableObject {
    @Published private(set) var touches: [TouchSample] = []

    func attach() {
        MultitouchManager.shared.setTouchObserver { [weak self] samples in
            guard let self, samples != self.touches else { return }
            self.touches = samples
        }
    }

    func detach() {
        MultitouchManager.shared.setTouchObserver(nil)
        touches = []
    }
}
