import AppKit

final class BrightnessController: ObservableObject {
    @Published private(set) var value: Double = 0.5
    @Published private(set) var isAvailable = false

    private var displayID: CGDirectDisplayID?
    private var observer: NSObjectProtocol?

    init() {
        refresh()
        observer = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        displayID = Self.controllableDisplay()
        guard let displayID else {
            isAvailable = false
            return
        }
        var brightness: Float = 0
        guard DisplayServicesGetBrightness(displayID, &brightness) == 0 else {
            isAvailable = false
            return
        }
        isAvailable = true
        let current = Double(brightness).clamped(to: 0...1)
        if abs(current - value) > 0.0005 {
            value = current
        }
    }

    func set(_ newValue: Double) {
        guard let displayID else { return }
        let clamped = newValue.clamped(to: 0...1)
        if DisplayServicesSetBrightness(displayID, Float(clamped)) == 0 {
            value = clamped
        }
    }

    private static func controllableDisplay() -> CGDirectDisplayID? {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else { return nil }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &displays, &count) == .success else { return nil }
        let candidates = displays.prefix(Int(count)).filter { DisplayServicesCanChangeBrightness($0) }
        return candidates.first { CGDisplayIsBuiltin($0) != 0 } ?? candidates.first
    }
}
