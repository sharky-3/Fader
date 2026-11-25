import AppKit

@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let brightness = BrightnessController()
    let volume = VolumeController()
    let media = MediaController()
    let permission = AccessibilityPermission()
    let haptics = HapticEngine()
    let hud = HUDPresenter()
    let touchFeed = TouchFeed()
    let coordinator: GestureCoordinator

    private var defaultsObserver: NSObjectProtocol?
    private var appliedAppearance: AppearanceMode?

    private init() {
        coordinator = GestureCoordinator(brightness: brightness, volume: volume, mute: MuteController(volume: volume), media: media, hud: hud, haptics: haptics)
    }

    func start() {
        applyAppearance()
        PointerFreeze.install()
        media.start()
        let coordinator = coordinator
        MultitouchManager.shared.onEvent = { event in
            coordinator.handle(event)
        }
        MultitouchManager.shared.start(configuration: .load())
        defaultsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in
                AppEnvironment.shared.preferencesChanged()
            }
        }
    }

    func stop() {
        coordinator.cancelAll()
        MultitouchManager.shared.stop()
        media.stop()
        haptics.reset()
    }

    private func preferencesChanged() {
        MultitouchManager.shared.update(.load())
        applyAppearance()
    }

    private func applyAppearance() {
        let mode = AppearanceMode(rawValue: UserDefaults.standard.string(forKey: PreferenceKey.appearance) ?? "") ?? .system
        guard mode != appliedAppearance else { return }
        appliedAppearance = mode
        NSApp.appearance = mode.appearance
        hud.applyAppearance(mode.appearance)
    }
}
