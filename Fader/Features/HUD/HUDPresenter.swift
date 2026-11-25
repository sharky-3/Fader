import AppKit
import SwiftUI

@MainActor
final class HUDPresenter {
    private let model = HUDModel()
    private var hideWork: DispatchWorkItem?
    private var placement: HUDPlacement?

    private lazy var panel: HUDPanel = {
        let panel = HUDPanel()
        let host = NSHostingView(rootView: HUDView(model: model))
        host.wantsLayer = true
        host.layer?.backgroundColor = .clear
        panel.contentView = host
        return panel
    }()

    var style: HUDStyle {
        HUDStyle(rawValue: UserDefaults.standard.string(forKey: PreferenceKey.hudStyle) ?? "") ?? .fader
    }

    func show(_ content: HUDContent) {
        hideWork?.cancel()
        hideWork = nil
        if style == .system, case .level(let state) = content, SystemOSD.show(state) {
            if model.isVisible {
                hide(animated: false)
            }
            return
        }
        if placement != content.placement || !panel.isVisible {
            position(for: content.placement)
        }
        model.content = content
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
        if !model.isVisible {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                model.isVisible = true
            }
        }
    }

    func scheduleHide(after delay: TimeInterval = ControlTuning.hudHideDelay) {
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.hide(animated: true)
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func applyAppearance(_ appearance: NSAppearance?) {
        panel.appearance = appearance
    }

    private func hide(animated: Bool) {
        guard model.isVisible else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.32)) {
                model.isVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) { [weak self] in
                guard let self, !self.model.isVisible else { return }
                self.panel.orderOut(nil)
            }
        } else {
            model.isVisible = false
            panel.orderOut(nil)
        }
    }

    private func position(for placement: HUDPlacement) {
        self.placement = placement
        guard let screen = NSScreen.underPointer else { return }
        let frame = screen.visibleFrame
        let size = HUDLayout.windowSize(for: placement)
        let margin = HUDLayout.margin
        let origin: CGPoint
        switch placement {
        case .left:
            origin = CGPoint(x: frame.minX + HUDLayout.edgeInset - margin, y: frame.midY - size.height / 2)
        case .right:
            origin = CGPoint(x: frame.maxX - HUDLayout.edgeInset - size.width + margin, y: frame.midY - size.height / 2)
        case .bottom:
            origin = CGPoint(x: frame.midX - size.width / 2, y: frame.minY + HUDLayout.bottomInset - margin)
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: false)
    }
}
