import AppKit

@MainActor
final class HapticEngine {
    private let actuators = ActuatorHaptics()
    private var lastDeviceID: UInt64?

    func tick(deviceID: UInt64?) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: PreferenceKey.hapticsEnabled) else { return }
        let strength = HapticStrength(rawValue: defaults.string(forKey: PreferenceKey.hapticStrength) ?? "") ?? .medium
        let engine = HapticEngineKind(rawValue: defaults.string(forKey: PreferenceKey.hapticEngine) ?? "") ?? .system
        if let deviceID {
            lastDeviceID = deviceID
        }
        if engine == .precise, let target = deviceID ?? lastDeviceID, actuators.actuate(deviceID: target, actuationID: strength.actuationID) {
            return
        }
        NSHapticFeedbackManager.defaultPerformer.perform(strength.pattern, performanceTime: .now)
    }

    func reset() {
        actuators.reset()
    }
}
