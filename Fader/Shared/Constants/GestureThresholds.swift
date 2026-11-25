import Foundation

enum GestureThresholds {
    static let engageDistance = 0.025
    static let abandonDistance = 0.07
    static let directionRatio = 1.4
    static let tapMaxDuration = 0.25
    static let tapMaxDistance = 0.025
    static let flickMaxDuration = 0.28
    static let flickMinDistance = 0.12
    static let doubleTapInterval = 0.4
    static let cornerSize = 0.14
    static let smoothing = 0.55
}

enum ControlTuning {
    static let levelGain = 1.3
    static let levelSteps = 16.0
    static let fineDivisor = 4.0
    static let scrubSecondsPerWidth = 60.0
    static let scrubTickSeconds = 5.0
    static let scrubFineTickSeconds = 1.0
    static let scrubAccelerationThreshold = 0.4
    static let scrubAccelerationGain = 3.5
    static let scrubMaxAcceleration = 6.0
    static let liveSeekInterval = 0.18
    static let arrowSeekSeconds = 5.0
    static let hudHideDelay = 1.0
}
