import Foundation

final class DirectMediaBackend: MediaBackend {
    var onUpdate: ((NowPlaying?) -> Void)?
    private(set) var isOperational = false

    private var observers: [NSObjectProtocol] = []

    func start() {
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        let names = ["kMRMediaRemoteNowPlayingInfoDidChangeNotification", "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification", "kMRMediaRemoteNowPlayingApplicationDidChangeNotification"]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
            }
        }
        refresh()
    }

    func stop() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
    }

    func refresh() {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            let dictionary = (info as? [String: Any]) ?? [:]
            MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { playing in
                guard let self else { return }
                if !dictionary.isEmpty {
                    self.isOperational = true
                }
                self.onUpdate?(NowPlaying(mediaRemote: dictionary, isPlaying: playing))
            }
        }
    }

    func send(_ command: MediaCommand) {
        _ = MRMediaRemoteSendCommand(command.remoteCode, nil)
    }

    func seek(to seconds: Double) {
        MRMediaRemoteSetElapsedTime(seconds)
    }
}
