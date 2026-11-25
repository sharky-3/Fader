import AppKit

final class MediaController: ObservableObject {
    @Published private(set) var nowPlaying: NowPlaying?

    private var backend: MediaBackend?

    func start() {
        if #available(macOS 15.4, *), let adapter = AdapterMediaBackend() {
            adapter.onFailure = { [weak self] in
                self?.use(DirectMediaBackend())
            }
            use(adapter)
            return
        }
        use(DirectMediaBackend())
    }

    func stop() {
        backend?.stop()
    }

    func refresh() {
        backend?.refresh()
    }

    var isPlaying: Bool { nowPlaying?.isPlaying ?? false }

    var canSeek: Bool {
        guard let backend, backend.isOperational, let nowPlaying else { return false }
        return nowPlaying.hasTimeline
    }

    private var canCommand: Bool {
        (backend?.isOperational ?? false) && nowPlaying != nil
    }

    func togglePlayPause() {
        if canCommand {
            backend?.send(.togglePlayPause)
        } else {
            SystemKeyEmitter.post(.playPause)
        }
        guard var current = nowPlaying else { return }
        current.freeze(at: Date())
        current.isPlaying.toggle()
        nowPlaying = current
    }

    func next() {
        canCommand ? backend?.send(.next) : SystemKeyEmitter.post(.next)
    }

    func previous() {
        canCommand ? backend?.send(.previous) : SystemKeyEmitter.post(.previous)
    }

    func seek(to seconds: Double) {
        guard var current = nowPlaying else { return }
        let target = current.hasTimeline ? seconds.clamped(to: 0...current.duration) : max(0, seconds)
        backend?.seek(to: target)
        current.elapsed = target
        current.timestamp = Date()
        nowPlaying = current
    }

    func stepWithArrows(count: Int, forward: Bool) {
        SystemKeyEmitter.postArrows(count: count, forward: forward)
    }

    private func use(_ newBackend: MediaBackend) {
        backend?.stop()
        backend = newBackend
        newBackend.onUpdate = { [weak self] update in
            guard let self, update != self.nowPlaying else { return }
            self.nowPlaying = update
        }
        newBackend.start()
    }
}
