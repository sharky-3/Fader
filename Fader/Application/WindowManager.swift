import AppKit
import SwiftUI

@MainActor
final class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()

    private var onboardingWindow: NSWindow?

    func showOnboarding() {
        let window = onboardingWindow ?? makeOnboardingWindow()
        onboardingWindow = window
        present(window)
    }

    func closeOnboarding() {
        onboardingWindow?.close()
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === onboardingWindow {
            AppEnvironment.shared.touchFeed.detach()
            onboardingWindow = nil
        }
    }

    private func present(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        if !window.isVisible {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
    }

    private func makeOnboardingWindow() -> NSWindow {
        let environment = AppEnvironment.shared
        let view = OnboardingView(permission: environment.permission, coordinator: environment.coordinator, touchFeed: environment.touchFeed) {
            UserDefaults.standard.set(true, forKey: PreferenceKey.hasCompletedOnboarding)
            WindowManager.shared.closeOnboarding()
            DrawerController.shared.show()
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 660, height: 600), styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.contentViewController = NSHostingController(rootView: view)
        window.title = "Welcome to Fader"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        return window
    }
}
