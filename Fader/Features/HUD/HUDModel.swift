import Combine

enum HUDPlacement: Equatable {
    case left
    case right
    case bottom
}

enum LevelKind: Equatable {
    case brightness
    case volume
}

struct LevelState: Equatable {
    var kind: LevelKind
    var value: Double
    var isMuted = false
    var isAvailable = true
    var placement: HUDPlacement
}

struct ScrubState: Equatable {
    var title: String?
    var startElapsed: Double
    var duration: Double?
    var offset: Double
    var needsPermission = false

    var isTimeline: Bool { (duration ?? 0) > 0 }
    var target: Double { startElapsed + offset }
}

enum MediaGlyph: Hashable {
    case play
    case pause
    case next
    case previous
}

enum HUDContent: Equatable {
    case level(LevelState)
    case scrub(ScrubState)
    case media(MediaGlyph)

    var placement: HUDPlacement {
        switch self {
        case .level(let state): state.placement
        case .scrub, .media: .bottom
        }
    }
}

final class HUDModel: ObservableObject {
    @Published var content: HUDContent?
    @Published var isVisible = false
}
