import AppKit

enum PreferenceKey {
    static let gesturesEnabled = "gesturesEnabled"
    static let brightnessEnabled = "brightnessEnabled"
    static let volumeEnabled = "volumeEnabled"
    static let scrubEnabled = "scrubEnabled"
    static let flickEnabled = "flickEnabled"
    static let tapEnabled = "tapEnabled"
    static let swapSides = "swapSides"
    static let activeArea = "activeArea"
    static let edgeWidth = "edgeWidth"
    static let bottomHeight = "bottomHeight"
    static let sensitivity = "sensitivity"
    static let hapticsEnabled = "hapticsEnabled"
    static let hapticStrength = "hapticStrength"
    static let hapticEngine = "hapticEngine"
    static let requiredModifier = "requiredModifier"
    static let hudStyle = "hudStyle"
    static let appearance = "appearance"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let leftEdgeAction = "leftEdgeAction"
    static let rightEdgeAction = "rightEdgeAction"
    static let bottomEdgeAction = "bottomEdgeAction"
    static let topLeftCornerAction = "topLeftCornerAction"
    static let topRightCornerAction = "topRightCornerAction"
    static let bottomLeftCornerAction = "bottomLeftCornerAction"
    static let bottomRightCornerAction = "bottomRightCornerAction"
}

enum PreferenceDefault {
    static let edgeWidth = 0.08
    static let bottomHeight = 0.10
    static let sensitivity = 1.0
    static let edgeWidthRange = 0.04...0.16
    static let bottomHeightRange = 0.06...0.20
    static let sensitivityRange = 0.5...2.0
}

enum Preferences {
    static func register() {
        UserDefaults.standard.register(defaults: [
            PreferenceKey.gesturesEnabled: true,
            PreferenceKey.brightnessEnabled: true,
            PreferenceKey.volumeEnabled: true,
            PreferenceKey.scrubEnabled: true,
            PreferenceKey.flickEnabled: true,
            PreferenceKey.tapEnabled: true,
            PreferenceKey.swapSides: false,
            PreferenceKey.activeArea: ActiveArea.full.rawValue,
            PreferenceKey.edgeWidth: PreferenceDefault.edgeWidth,
            PreferenceKey.bottomHeight: PreferenceDefault.bottomHeight,
            PreferenceKey.sensitivity: PreferenceDefault.sensitivity,
            PreferenceKey.hapticsEnabled: true,
            PreferenceKey.hapticStrength: HapticStrength.medium.rawValue,
            PreferenceKey.hapticEngine: HapticEngineKind.system.rawValue,
            PreferenceKey.requiredModifier: ModifierRequirement.none.rawValue,
            PreferenceKey.hudStyle: HUDStyle.fader.rawValue,
            PreferenceKey.appearance: AppearanceMode.system.rawValue,
            PreferenceKey.hasCompletedOnboarding: false,
            PreferenceKey.leftEdgeAction: EdgeAction.brightness.rawValue,
            PreferenceKey.rightEdgeAction: EdgeAction.volume.rawValue,
            PreferenceKey.bottomEdgeAction: EdgeAction.video.rawValue,
            PreferenceKey.topLeftCornerAction: CornerAction.none.rawValue,
            PreferenceKey.topRightCornerAction: CornerAction.mute.rawValue,
            PreferenceKey.bottomLeftCornerAction: CornerAction.none.rawValue,
            PreferenceKey.bottomRightCornerAction: CornerAction.none.rawValue
        ])
    }

    static func resetTrackpadGeometry() {
        let defaults = UserDefaults.standard
        [PreferenceKey.activeArea, PreferenceKey.edgeWidth, PreferenceKey.bottomHeight, PreferenceKey.sensitivity].forEach(defaults.removeObject)
    }
}

enum EdgeSlot: String, CaseIterable, Identifiable {
    case left
    case right
    case bottom

    var id: String { rawValue }

    var key: String {
        switch self {
        case .left: PreferenceKey.leftEdgeAction
        case .right: PreferenceKey.rightEdgeAction
        case .bottom: PreferenceKey.bottomEdgeAction
        }
    }

    var isVertical: Bool { self != .bottom }
}

enum EdgeAction: String, CaseIterable, Identifiable {
    case brightness
    case volume
    case video
    case none

    var id: String { rawValue }

    static let assignable: [EdgeAction] = [.brightness, .volume, .video]

    var title: String {
        switch self {
        case .brightness: "Brightness"
        case .volume: "Volume"
        case .video: "Video"
        case .none: "Empty"
        }
    }

    var symbol: String {
        switch self {
        case .brightness: "sun.max.fill"
        case .volume: "speaker.wave.2.fill"
        case .video: "play.fill"
        case .none: "plus"
        }
    }

    var gestureAction: GestureAction? {
        switch self {
        case .brightness: .brightness
        case .volume: .volume
        case .video: .scrub
        case .none: nil
        }
    }

    static func assigned(to slot: EdgeSlot, in defaults: UserDefaults = .standard) -> EdgeAction {
        EdgeAction(rawValue: defaults.string(forKey: slot.key) ?? "") ?? EdgeAction.none
    }
}

enum CornerSlot: String, CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    var key: String {
        switch self {
        case .topLeft: PreferenceKey.topLeftCornerAction
        case .topRight: PreferenceKey.topRightCornerAction
        case .bottomLeft: PreferenceKey.bottomLeftCornerAction
        case .bottomRight: PreferenceKey.bottomRightCornerAction
        }
    }

    var isLeft: Bool { self == .topLeft || self == .bottomLeft }
    var isTop: Bool { self == .topLeft || self == .topRight }
}

enum CornerAction: String, CaseIterable, Identifiable {
    case mute
    case playPause
    case none

    var id: String { rawValue }

    static let assignable: [CornerAction] = [.mute, .playPause]

    var title: String {
        switch self {
        case .mute: "Mute"
        case .playPause: "Play / Pause"
        case .none: "Empty"
        }
    }

    var symbol: String {
        switch self {
        case .mute: "speaker.slash.fill"
        case .playPause: "playpause.fill"
        case .none: "plus"
        }
    }

    static func assigned(to slot: CornerSlot, in defaults: UserDefaults = .standard) -> CornerAction {
        CornerAction(rawValue: defaults.string(forKey: slot.key) ?? "") ?? CornerAction.none
    }
}

enum ActiveArea: String, CaseIterable, Identifiable {
    case full
    case topHalf
    case bottomHalf
    case middle
    case bottomQuarter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .full: "Full Edge"
        case .topHalf: "Top Half"
        case .bottomHalf: "Bottom Half"
        case .middle: "Middle"
        case .bottomQuarter: "Bottom Quarter"
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .full: 0...1
        case .topHalf: 0.5...1
        case .bottomHalf: 0...0.5
        case .middle: 0.25...0.75
        case .bottomQuarter: 0...0.25
        }
    }
}

enum HapticStrength: String, CaseIterable, Identifiable {
    case light
    case medium
    case strong

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var actuationID: Int32 {
        switch self {
        case .light: 3
        case .medium: 4
        case .strong: 6
        }
    }

    var pattern: NSHapticFeedbackManager.FeedbackPattern {
        switch self {
        case .light: .alignment
        case .medium: .generic
        case .strong: .levelChange
        }
    }
}

enum HapticEngineKind: String, CaseIterable, Identifiable {
    case system
    case precise

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .precise: "Precise"
        }
    }
}

enum ModifierRequirement: String, CaseIterable, Identifiable {
    case none
    case function
    case control
    case option
    case command

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "None"
        case .function: "fn"
        case .control: "⌃ Control"
        case .option: "⌥ Option"
        case .command: "⌘ Command"
        }
    }

    func isSatisfied(by flags: CGEventFlags) -> Bool {
        switch self {
        case .none: true
        case .function: flags.contains(.maskSecondaryFn)
        case .control: flags.contains(.maskControl)
        case .option: flags.contains(.maskAlternate)
        case .command: flags.contains(.maskCommand)
        }
    }
}

enum HUDStyle: String, CaseIterable, Identifiable {
    case fader
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fader: "Fader"
        case .system: "System"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}
