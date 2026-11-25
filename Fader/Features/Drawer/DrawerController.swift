import AppKit
import SwiftUI

@MainActor
final class DrawerController: NSObject {
    static let shared = DrawerController()

    let model = DrawerModel()

    private var panel: DrawerPanel?
    private var clickMonitor: Any?
    private var contentWork: DispatchWorkItem?
    private var orderOutWork: DispatchWorkItem?
    private(set) var isShown = false

    func show() {
        orderOutWork?.cancel()
        orderOutWork = nil
        guard !isShown else { return }
        isShown = true
        AppEnvironment.shared.permission.refresh()
        layoutPanel()
        panel?.ignoresMouseEvents = false
        panel?.orderFrontRegardless()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.74)) {
            model.progress = 1
        }
        contentWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.isShown else { return }
            withAnimation(.easeOut(duration: 0.32)) {
                self.model.showsContent = true
            }
        }
        contentWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24, execute: work)
        installClickMonitor()
    }

    func hide() {
        guard isShown else { return }
        isShown = false
        contentWork?.cancel()
        contentWork = nil
        removeClickMonitor()
        panel?.ignoresMouseEvents = true
        withAnimation(.easeIn(duration: 0.14)) {
            model.showsContent = false
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 1).delay(0.1)) {
            model.progress = 0
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isShown else { return }
            self.panel?.orderOut(nil)
        }
        orderOutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: work)
    }

    func toggle() {
        if isShown {
            hide()
        } else {
            show()
        }
    }

    private func layoutPanel() {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
        model.edge = Self.freeEdge()
        let visible = screen.visibleFrame
        let probe = NSHostingView(rootView: SettingsView(environment: AppEnvironment.shared, onClose: {}))
        let fitting = probe.fittingSize
        let maxHeight = visible.height - model.fillet * 2 - 50
        model.contentSize = CGSize(width: fitting.width, height: min(fitting.height, maxHeight))
        let size = model.panelSize
        let y = min(max(visible.midY - size.height / 2, visible.minY), visible.maxY - size.height)
        let x = model.edge == .right ? screen.frame.maxX - size.width : screen.frame.minX
        let panel = self.panel ?? makePanel()
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        self.panel = panel
    }

    private func makePanel() -> DrawerPanel {
        let panel = DrawerPanel()
        let host = FirstMouseHostingView(rootView: DrawerView(model: model, environment: AppEnvironment.shared) {
            DrawerController.shared.hide()
        })
        host.wantsLayer = true
        host.layer?.backgroundColor = .clear
        panel.contentView = host
        return panel
    }

    private func installClickMonitor() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            Task { @MainActor in
                DrawerController.shared.hide()
            }
        }
    }

    private func removeClickMonitor() {
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
        }
        clickMonitor = nil
    }

    private static func freeEdge() -> DrawerEdge {
        let orientation = UserDefaults(suiteName: "com.apple.dock")?.string(forKey: "orientation") ?? "bottom"
        return orientation == "right" ? .left : .right
    }
}
