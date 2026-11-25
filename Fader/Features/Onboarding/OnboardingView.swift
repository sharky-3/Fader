import SwiftUI

struct OnboardingView: View {
    @ObservedObject var permission: AccessibilityPermission
    @ObservedObject var coordinator: GestureCoordinator
    let touchFeed: TouchFeed
    let onFinish: () -> Void

    @State private var step = 0
    @State private var isForward = true

    private let stepCount = 4

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .underWindowBackground)
                .ignoresSafeArea()
            backdrop
            VStack(spacing: 0) {
                ZStack {
                    page
                        .id(step)
                        .transition(.asymmetric(insertion: .move(edge: isForward ? .trailing : .leading).combined(with: .opacity), removal: .move(edge: isForward ? .leading : .trailing).combined(with: .opacity)))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                footer
            }
            .padding(.top, 28)
        }
        .frame(width: 660, height: 600)
    }

    private var backdrop: some View {
        ZStack {
            Circle()
                .fill(Palette.volume.opacity(0.18))
                .frame(width: 420)
                .blur(radius: 90)
                .offset(x: -200, y: -200)
            Circle()
                .fill(Palette.mute.opacity(0.18))
                .frame(width: 380)
                .blur(radius: 90)
                .offset(x: 220, y: 160)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var page: some View {
        switch step {
        case 0: WelcomePage()
        case 1: GesturesPage()
        case 2: PermissionPage(permission: permission)
        default: TryItPage(coordinator: coordinator, touchFeed: touchFeed)
        }
    }

    private var footer: some View {
        HStack {
            Button("Back") {
                move(by: -1)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(step == 0 ? 0 : 1)
            .disabled(step == 0)
            Spacer()
            HStack(spacing: 7) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == step ? AnyShapeStyle(.primary) : AnyShapeStyle(.primary.opacity(0.2)))
                        .frame(width: index == step ? 18 : 7, height: 7)
                }
            }
            Spacer()
            Button {
                if step == stepCount - 1 {
                    onFinish()
                } else {
                    move(by: 1)
                }
            } label: {
                Text(step == stepCount - 1 ? "Done" : "Continue")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 9)
                    .background(Capsule(style: .continuous).fill(Palette.glyphGradient))
                    .shadow(color: Palette.mute.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(PressScaleStyle())
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 26)
        .padding(.top, 12)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
    }

    private func move(by delta: Int) {
        isForward = delta > 0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            step = (step + delta).clamped(to: 0...(stepCount - 1))
        }
    }
}

private struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
        }
    }
}

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 26) {
            AppGlyph(size: 64)
            PageHeader(title: "Your trackpad, with faders.", subtitle: "Slide along the edges to set brightness and volume, and scrub through whatever's playing. No keys, no menus.")
            AnimatedTrackpadIllustration()
                .frame(width: 380)
        }
        .padding(.horizontal, 40)
    }
}

private struct GesturesPage: View {
    private let rows: [(String, Color, String, String)] = [
        ("sun.max.fill", Palette.brightness, "Left edge", "Slide up or down to change display brightness."),
        ("speaker.wave.3.fill", Palette.volume, "Right edge", "Slide up or down to change volume."),
        ("arrow.left.and.right", Palette.media, "Bottom edge", "Slide to scrub, flick to skip, tap to play or pause."),
        ("speaker.slash.fill", Palette.mute, "Top-right corner", "Double-tap to mute or unmute.")
    ]

    var body: some View {
        VStack(spacing: 26) {
            PageHeader(title: "Four edges, one finger.", subtitle: "Gestures start only when a single finger lands inside an edge, so pointing and system gestures work just like before.")
            VStack(spacing: 10) {
                ForEach(rows, id: \.2) { row in
                    HStack(spacing: 14) {
                        Image(systemName: row.0)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(row.1)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(.primary.opacity(0.07)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.2)
                                .font(.system(size: 14, weight: .semibold))
                            Text(row.3)
                                .font(.system(size: 12.5))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.primary.opacity(0.05)))
                }
            }
            .frame(maxWidth: 460)
            Text("Hold ⇧⌥ while sliding for fine control.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 40)
    }
}

private struct PermissionPage: View {
    @ObservedObject var permission: AccessibilityPermission

    var body: some View {
        VStack(spacing: 26) {
            ZStack {
                Circle()
                    .fill(permission.isTrusted ? AnyShapeStyle(.green.opacity(0.15)) : AnyShapeStyle(.orange.opacity(0.15)))
                    .frame(width: 96, height: 96)
                Image(systemName: permission.isTrusted ? "checkmark.shield.fill" : "hand.raised.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(permission.isTrusted ? .green : .orange)
                    .contentTransition(.opacity)
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: permission.isTrusted)
            PageHeader(title: permission.isTrusted ? "You're all set." : "One permission.", subtitle: "Fader needs Accessibility access to send play/pause and track keys, and to seek players that don't share their timeline, like some browser videos.")
            if permission.isTrusted {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.green)
            } else {
                VStack(spacing: 10) {
                    Button {
                        permission.request()
                    } label: {
                        Text("Open Accessibility Settings")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    Text("Turn on Fader in the list, then come back here.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 40)
        .onAppear {
            permission.refresh()
        }
    }
}

private struct TryItPage: View {
    @ObservedObject var coordinator: GestureCoordinator
    @ObservedObject var touchFeed: TouchFeed

    @AppStorage(PreferenceKey.edgeWidth) private var edgeWidth = PreferenceDefault.edgeWidth
    @AppStorage(PreferenceKey.bottomHeight) private var bottomHeight = PreferenceDefault.bottomHeight
    @AppStorage(PreferenceKey.activeArea) private var activeArea = ActiveArea.full.rawValue
    @AppStorage(PreferenceKey.swapSides) private var swapSides = false

    init(coordinator: GestureCoordinator, touchFeed: TouchFeed) {
        self.coordinator = coordinator
        self.touchFeed = touchFeed
    }

    var body: some View {
        VStack(spacing: 24) {
            PageHeader(title: "Try it.", subtitle: "Put a finger on an edge of your trackpad and slide. Your touches appear below.")
            TrackpadZonesView(edgeWidth: edgeWidth, bottomHeight: bottomHeight, activeRange: (ActiveArea(rawValue: activeArea) ?? .full).range, swapSides: swapSides, highlighted: highlighted, touches: touchFeed.touches)
                .frame(width: 400)
            HStack(spacing: 10) {
                Image(systemName: coordinator.activity?.symbol ?? "hand.point.up.left.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)
                Text(coordinator.activity?.title ?? "Waiting for a gesture…")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule(style: .continuous).fill(.primary.opacity(0.06)))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.activity)
        }
        .padding(.horizontal, 40)
        .onAppear {
            touchFeed.attach()
        }
        .onDisappear {
            touchFeed.detach()
        }
    }

    private var highlighted: Set<EdgeZone> {
        let configuration = GestureConfiguration.load()
        let contacts = touchFeed.touches.filter(\.isContact)
        guard contacts.count == 1, let touch = contacts.first else { return [] }
        return configuration.zones(at: touch.point)
    }
}
