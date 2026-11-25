import AudioToolbox
import CoreAudio
import Foundation

final class VolumeController: ObservableObject {
    @Published private(set) var volume: Double = 0
    @Published private(set) var isMuted = false
    @Published private(set) var isAvailable = false

    private var deviceID = AudioObjectID(kAudioObjectUnknown)
    private var volumeAddress: AudioObjectPropertyAddress?
    private var muteAddress: AudioObjectPropertyAddress?
    private var listeners: [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
    private var emulatedMuteVolume: Double?

    init() {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.bindDefaultDevice()
        }
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, block)
        bindDefaultDevice()
    }

    var canMute: Bool { isAvailable || muteAddress != nil }

    func refresh() {
        let currentVolume = readVolume()
        let currentMute = readMute()
        if let currentVolume, abs(currentVolume - volume) > 0.0005 {
            volume = currentVolume
        }
        if currentMute != isMuted {
            isMuted = currentMute
        }
        let available = volumeAddress != nil
        if available != isAvailable {
            isAvailable = available
        }
    }

    func set(_ newValue: Double) {
        guard var address = volumeAddress else { return }
        let clamped = newValue.clamped(to: 0...1)
        var scalar = Float32(clamped)
        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &scalar)
        guard status == noErr else { return }
        volume = clamped
        if clamped > 0, isMuted {
            setMuted(false)
        }
    }

    func toggleMute() {
        setMuted(!isMuted)
    }

    func setMuted(_ muted: Bool) {
        if var address = muteAddress {
            var flag: UInt32 = muted ? 1 : 0
            if AudioObjectSetPropertyData(deviceID, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &flag) == noErr {
                isMuted = muted
            }
            return
        }
        guard volumeAddress != nil else { return }
        if muted {
            emulatedMuteVolume = volume
            set(0)
            isMuted = true
        } else {
            isMuted = false
            set(emulatedMuteVolume ?? 0.5)
            emulatedMuteVolume = nil
        }
    }

    private func bindDefaultDevice() {
        removeDeviceListeners()
        deviceID = Self.defaultOutputDevice()
        volumeAddress = settableAddress(selectors: [kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioDevicePropertyVolumeScalar])
        muteAddress = settableAddress(selectors: [kAudioDevicePropertyMute])
        emulatedMuteVolume = nil
        for address in [volumeAddress, muteAddress].compactMap({ $0 }) {
            addDeviceListener(address)
        }
        refresh()
    }

    private func settableAddress(selectors: [AudioObjectPropertySelector]) -> AudioObjectPropertyAddress? {
        guard deviceID != kAudioObjectUnknown else { return nil }
        for selector in selectors {
            var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMain)
            guard AudioObjectHasProperty(deviceID, &address) else { continue }
            var settable: DarwinBoolean = false
            if AudioObjectIsPropertySettable(deviceID, &address, &settable) == noErr, settable.boolValue {
                return address
            }
        }
        return nil
    }

    private func addDeviceListener(_ address: AudioObjectPropertyAddress) {
        var mutableAddress = address
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.refresh()
        }
        if AudioObjectAddPropertyListenerBlock(deviceID, &mutableAddress, .main, block) == noErr {
            listeners.append((deviceID, address, block))
        }
    }

    private func removeDeviceListeners() {
        for (device, address, block) in listeners {
            var mutableAddress = address
            AudioObjectRemovePropertyListenerBlock(device, &mutableAddress, .main, block)
        }
        listeners.removeAll()
    }

    private func readVolume() -> Double? {
        guard var address = volumeAddress else { return nil }
        var scalar: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &scalar) == noErr else { return nil }
        return Double(scalar).clamped(to: 0...1)
    }

    private func readMute() -> Bool {
        guard var address = muteAddress else { return emulatedMuteVolume != nil }
        var flag: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &flag) == noErr else { return false }
        return flag != 0
    }

    private static func defaultOutputDevice() -> AudioObjectID {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        return status == noErr ? device : AudioObjectID(kAudioObjectUnknown)
    }
}
