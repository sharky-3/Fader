import AppKit
import CoreServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        signal(SIGPIPE, SIG_IGN)
        let launchedAtLogin = Self.isLoginLaunch
        AppEnvironment.shared.start()
        if !UserDefaults.standard.bool(forKey: PreferenceKey.hasCompletedOnboarding) {
            WindowManager.shared.showOnboarding()
        } else if !launchedAtLogin {
            DrawerController.shared.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppEnvironment.shared.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        DrawerController.shared.show()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private static var isLoginLaunch: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent, event.eventID == AEEventID(kAEOpenApplication) else { return false }
        let value = event.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?.enumCodeValue
        return value == OSType(keyAELaunchedAsLogInItem)
    }
}
