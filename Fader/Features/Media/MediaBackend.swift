import Foundation

enum MediaCommand {
    case togglePlayPause
    case play
    case pause
    case next
    case previous

    var remoteCode: UInt32 {
        switch self {
        case .play: 0
        case .pause: 1
        case .togglePlayPause: 2
        case .next: 4
        case .previous: 5
        }
    }

    var bridgeName: String {
        switch self {
        case .play: "play"
        case .pause: "pause"
        case .togglePlayPause: "toggle"
        case .next: "next"
        case .previous: "previous"
        }
    }
}

protocol MediaBackend: AnyObject {
    var onUpdate: ((NowPlaying?) -> Void)? { get set }
    var isOperational: Bool { get }
    func start()
    func stop()
    func refresh()
    func send(_ command: MediaCommand)
    func seek(to seconds: Double)
}
