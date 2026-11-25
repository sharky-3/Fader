import AppKit
import IOKit

private let contactFrameCallback: MTContactCallbackFunction = { device, touches, count, _, _ in
    guard let device else { return 0 }
    MultitouchManager.shared.handleFrame(device: device, touches: touches, count: Int(count))
    return 0
}

private let hardwareCallback: IOServiceMatchingCallback = { _, iterator in
    MultitouchManager.drain(iterator)
    DispatchQueue.main.async {
        MultitouchManager.shared.scheduleRestart()
    }
}

final class MultitouchManager {
    static let shared = MultitouchManager()

    private static let excludedFamilies: Set<Int32> = [112, 113]
    private static let contactStates: Set<Int32> = [3, 4]

    var onEvent: (@MainActor (GestureEvent) -> Void)?

    private let lock = NSLock()
    private var deviceList: CFArray?
    private var devices: [MTDeviceRef] = []
    private var recognizers: [Int: GestureRecognizer] = [:]
    private var configuration = GestureConfiguration()
    private var touchObserver: (@MainActor ([TouchSample]) -> Void)?
    private var notificationPort: IONotificationPortRef?
    private var iterators: [io_iterator_t] = []
    private var powerObservers: [NSObjectProtocol] = []
    private var pendingRestart: DispatchWorkItem?

    private init() {}

    var deviceCount: Int {
        devices.count
    }

    func start(configuration: GestureConfiguration) {
        update(configuration)
        startDevices()
        observeHardware()
        observePower()
    }

    func stop() {
        pendingRestart?.cancel()
        stopDevices()
    }

    func update(_ configuration: GestureConfiguration) {
        lock.lock()
        self.configuration = configuration
        lock.unlock()
    }

    func setTouchObserver(_ observer: (@MainActor ([TouchSample]) -> Void)?) {
        lock.lock()
        touchObserver = observer
        lock.unlock()
    }

    func scheduleRestart(after delay: TimeInterval = 0.6) {
        pendingRestart?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.restart()
        }
        pendingRestart = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func restart() {
        stopDevices()
        startDevices()
    }

    static func drain(_ iterator: io_iterator_t) {
        var object = IOIteratorNext(iterator)
        while object != 0 {
            IOObjectRelease(object)
            object = IOIteratorNext(iterator)
        }
    }

    fileprivate func handleFrame(device: MTDeviceRef, touches: UnsafeMutablePointer<MTTouch>?, count: Int) {
        var samples: [TouchSample] = []
        if let touches, count > 0 {
            samples.reserveCapacity(count)
            for index in 0..<count {
                let touch = touches[index]
                samples.append(TouchSample(id: touch.pathIndex, x: Double(touch.normalizedVector.position.x), y: Double(touch.normalizedVector.position.y), isContact: Self.contactStates.contains(touch.state), size: Double(touch.zTotal)))
            }
        }
        let now = ProcessInfo.processInfo.systemUptime
        let key = Int(bitPattern: device)

        lock.lock()
        guard let recognizer = recognizers[key] else {
            lock.unlock()
            return
        }
        let canEngage = !recognizers.contains { $0.key != key && $0.value.isEngaged }
        let events = recognizer.process(samples, at: now, configuration: configuration, canEngage: canEngage)
        let observer = touchObserver
        lock.unlock()

        if !events.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let handler = self?.onEvent else { return }
                events.forEach(handler)
            }
        }
        if let observer {
            DispatchQueue.main.async {
                observer(samples)
            }
        }
    }

    private func startDevices() {
        guard devices.isEmpty, let list = MTDeviceCreateList() else { return }
        var started: [MTDeviceRef] = []
        var created: [Int: GestureRecognizer] = [:]
        for index in 0..<CFArrayGetCount(list) {
            guard let value = CFArrayGetValueAtIndex(list, index) else { continue }
            let device = UnsafeMutableRawPointer(mutating: value)
            var family: Int32 = 0
            MTDeviceGetFamilyID(device, &family)
            guard !Self.excludedFamilies.contains(family) else { continue }
            var identifier: UInt64 = 0
            MTDeviceGetDeviceID(device, &identifier)
            created[Int(bitPattern: device)] = GestureRecognizer(deviceID: identifier)
            started.append(device)
        }
        lock.lock()
        recognizers = created
        lock.unlock()
        for device in started {
            MTRegisterContactFrameCallback(device, contactFrameCallback)
            MTDeviceStart(device, 0)
        }
        deviceList = list
        devices = started
    }

    private func stopDevices() {
        for device in devices {
            MTUnregisterContactFrameCallback(device, contactFrameCallback)
            MTDeviceStop(device)
        }
        lock.lock()
        let events = recognizers.values.flatMap { $0.reset() }
        recognizers.removeAll()
        lock.unlock()
        devices.removeAll()
        deviceList = nil
        if !events.isEmpty, let handler = onEvent {
            DispatchQueue.main.async {
                events.forEach(handler)
            }
        }
    }

    private func observeHardware() {
        guard notificationPort == nil, let port = IONotificationPortCreate(kIOMainPortDefault) else { return }
        notificationPort = port
        IONotificationPortSetDispatchQueue(port, DispatchQueue.main)
        for type in [kIOFirstMatchNotification, kIOTerminatedNotification] {
            var iterator: io_iterator_t = 0
            let result = IOServiceAddMatchingNotification(port, type, IOServiceMatching("AppleMultitouchDevice"), hardwareCallback, nil, &iterator)
            if result == KERN_SUCCESS {
                Self.drain(iterator)
                iterators.append(iterator)
            }
        }
    }

    private func observePower() {
        guard powerObservers.isEmpty else { return }
        let center = NSWorkspace.shared.notificationCenter
        let names = [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification]
        powerObservers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MultitouchManager.shared.scheduleRestart(after: 1.2)
            }
        }
    }
}
