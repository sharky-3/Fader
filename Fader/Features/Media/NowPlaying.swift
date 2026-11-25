import AppKit

struct NowPlaying: Equatable {
    var title: String?
    var artist: String?
    var album: String?
    var artwork: NSImage?
    var duration: Double = 0
    var elapsed: Double = 0
    var rate: Double = 0
    var timestamp = Date()
    var isPlaying = false

    var hasTimeline: Bool { duration > 0 }

    var isEmpty: Bool { title == nil && artist == nil && duration == 0 }

    var subtitle: String? {
        [artist, album].compactMap { $0 }.filter { !$0.isEmpty }.first
    }

    func elapsed(at date: Date) -> Double {
        guard isPlaying else { return clampedElapsed(elapsed) }
        let speed = rate == 0 ? 1 : rate
        return clampedElapsed(elapsed + date.timeIntervalSince(timestamp) * speed)
    }

    mutating func freeze(at date: Date) {
        elapsed = elapsed(at: date)
        timestamp = date
    }

    private func clampedElapsed(_ value: Double) -> Double {
        duration > 0 ? value.clamped(to: 0...duration) : max(0, value)
    }
}

extension NowPlaying {
    init?(mediaRemote info: [String: Any], isPlaying: Bool) {
        guard !info.isEmpty else { return nil }
        func value<T>(_ key: String) -> T? {
            info["kMRMediaRemoteNowPlayingInfo" + key] as? T
        }
        title = value("Title")
        artist = value("Artist")
        album = value("Album")
        duration = value("Duration") ?? 0
        elapsed = value("ElapsedTime") ?? 0
        rate = value("PlaybackRate") ?? (isPlaying ? 1 : 0)
        timestamp = value("Timestamp") ?? Date()
        self.isPlaying = isPlaying
        if let data: Data = value("ArtworkData") {
            artwork = NSImage(data: data)
        }
    }

    init?(bridge payload: [String: Any], previousArtwork: NSImage?) {
        guard payload["empty"] == nil else { return nil }
        title = payload["title"] as? String
        artist = payload["artist"] as? String
        album = payload["album"] as? String
        duration = payload["duration"] as? Double ?? 0
        elapsed = payload["elapsed"] as? Double ?? 0
        isPlaying = payload["playing"] as? Bool ?? false
        rate = payload["rate"] as? Double ?? (isPlaying ? 1 : 0)
        if let stamp = payload["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: stamp)
        }
        switch payload["artwork"] as? String {
        case "new":
            artwork = (payload["artworkData"] as? String).flatMap { Data(base64Encoded: $0) }.flatMap(NSImage.init(data:))
        case "same":
            artwork = previousArtwork
        default:
            artwork = nil
        }
    }
}
