import SwiftUI

@main
struct FaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        Preferences.register()
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
