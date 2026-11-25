import Foundation

final class ActuatorHaptics {
    private var actuators: [UInt64: MTActuatorRef] = [:]
    private var failed: Set<UInt64> = []

    func actuate(deviceID: UInt64, actuationID: Int32) -> Bool {
        guard let actuator = actuator(for: deviceID) else { return false }
        if MTActuatorActuate(actuator, actuationID, 0, 0, 0) == 0 {
            return true
        }
        MTActuatorClose(actuator)
        actuators[deviceID] = nil
        return false
    }

    func reset() {
        actuators.values.forEach { MTActuatorClose($0) }
        actuators.removeAll()
        failed.removeAll()
    }

    private func actuator(for deviceID: UInt64) -> MTActuatorRef? {
        if let actuator = actuators[deviceID] {
            return actuator
        }
        guard deviceID != 0, !failed.contains(deviceID), let actuator = MTActuatorCreateFromDeviceID(deviceID) else { return nil }
        guard MTActuatorOpen(actuator) == 0 else {
            failed.insert(deviceID)
            return nil
        }
        actuators[deviceID] = actuator
        return actuator
    }
}
