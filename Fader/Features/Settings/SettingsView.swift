import SwiftUI

struct SettingsView: View {
    let environment: AppEnvironment
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsHeader(onClose: onClose)
            LayoutSection(haptics: environment.haptics)
            FeelSection()
            VideoSection()
            GeneralSection(permission: environment.permission)
            SettingsFooter()
        }
        .padding(22)
        .font(.system(size: 12.5, weight: .medium))
        .foregroundStyle(.white)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.colorScheme, .dark)
    }
}

private struct SettingsHeader: View {
    let onClose: () -> Void

    @AppStorage(PreferenceKey.gesturesEnabled) private var gesturesEnabled = true

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fader")
                    .font(.system(size: 18, weight: .semibold))
                Text("Trackpad edge controls")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            StatusButton(isOn: $gesturesEnabled)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.white.opacity(0.1)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Hide")
        }
    }
}

private struct LayoutSection: View {
    let haptics: HapticEngine

    @AppStorage(PreferenceKey.edgeWidth) private var edgeWidth = PreferenceDefault.edgeWidth
    @AppStorage(PreferenceKey.bottomHeight) private var bottomHeight = PreferenceDefault.bottomHeight
    @AppStorage(PreferenceKey.activeArea) private var activeArea = ActiveArea.full.rawValue

    var body: some View {
        SettingsGroup(title: "Layout") {
            EdgeLayoutEditor(haptics: haptics, width: 332)
                .padding(12)
            GroupDivider()
            GroupRow(symbol: "arrow.left.and.right", title: "Edge Width") {
                SliderAccessory(value: $edgeWidth, range: PreferenceDefault.edgeWidthRange, valueText: "\(edgeWidth.percentText)%")
            }
            GroupRow(symbol: "arrow.up.and.down", title: "Bottom Height") {
                SliderAccessory(value: $bottomHeight, range: PreferenceDefault.bottomHeightRange, valueText: "\(bottomHeight.percentText)%")
            }
            GroupRow(symbol: "rectangle.dashed", title: "Active Area", showsDivider: false) {
                CycleButton(options: ActiveArea.allCases, selection: areaSelection) { area in
                    area.title
                }
            }
        }
    }

    private var areaSelection: Binding<ActiveArea> {
        Binding {
            ActiveArea(rawValue: activeArea) ?? .full
        } set: { newValue in
            activeArea = newValue.rawValue
        }
    }
}

private struct FeelSection: View {
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PreferenceKey.hapticStrength) private var hapticStrength = HapticStrength.medium.rawValue
    @AppStorage(PreferenceKey.sensitivity) private var sensitivity = PreferenceDefault.sensitivity

    private let hapticOptions = ["off", HapticStrength.light.rawValue, HapticStrength.medium.rawValue, HapticStrength.strong.rawValue]

    var body: some View {
        SettingsGroup(title: "Feel") {
            GroupRow(symbol: "waveform", title: "Haptics") {
                SimpleSegments(options: hapticOptions, selection: hapticSelection) { option in
                    option == "off" ? "Off" : option.capitalized
                }
                .frame(width: 196)
            }
            GroupRow(symbol: "speedometer", title: "Sensitivity", showsDivider: false) {
                SliderAccessory(value: $sensitivity, range: PreferenceDefault.sensitivityRange, valueText: String(format: "%.1f×", sensitivity))
            }
        }
    }

    private var hapticSelection: Binding<String> {
        Binding {
            hapticsEnabled ? hapticStrength : "off"
        } set: { newValue in
            if newValue == "off" {
                hapticsEnabled = false
            } else {
                hapticsEnabled = true
                hapticStrength = newValue
            }
        }
    }
}

private struct VideoSection: View {
    @AppStorage(PreferenceKey.flickEnabled) private var flickEnabled = true

    var body: some View {
        SettingsGroup(title: "Video") {
            GroupRow(symbol: "forward.fill", title: "Quick Flick Skips Track", showsDivider: false) {
                SimpleSwitch(isOn: $flickEnabled)
            }
        }
    }
}

private struct GeneralSection: View {
    @ObservedObject var permission: AccessibilityPermission

    @AppStorage(PreferenceKey.requiredModifier) private var requiredModifier = ModifierRequirement.none.rawValue
    @AppStorage(PreferenceKey.hudStyle) private var hudStyle = HUDStyle.fader.rawValue

    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        SettingsGroup(title: "General") {
            GroupRow(symbol: "option", title: "Hold Key to Slide") {
                CycleButton(options: ModifierRequirement.allCases, selection: modifierSelection) { modifier in
                    modifier.title
                }
            }
            GroupRow(symbol: "rectangle.on.rectangle", title: "macOS Volume HUD") {
                SimpleSwitch(isOn: systemHUD)
            }
            GroupRow(symbol: "power", title: "Open at Login", showsDivider: !permission.isTrusted) {
                SimpleSwitch(isOn: loginBinding)
            }
            if !permission.isTrusted {
                GroupRow(symbol: "hand.raised.fill", title: "Accessibility", showsDivider: false) {
                    Button("Allow") {
                        permission.request()
                    }
                    .buttonStyle(PlainPillButtonStyle())
                }
            }
        }
        .onAppear {
            launchAtLogin = LaunchAtLogin.isEnabled
            permission.refresh()
        }
    }

    private var modifierSelection: Binding<ModifierRequirement> {
        Binding {
            ModifierRequirement(rawValue: requiredModifier) ?? ModifierRequirement.none
        } set: { newValue in
            requiredModifier = newValue.rawValue
        }
    }

    private var systemHUD: Binding<Bool> {
        Binding {
            hudStyle == HUDStyle.system.rawValue
        } set: { newValue in
            hudStyle = newValue ? HUDStyle.system.rawValue : HUDStyle.fader.rawValue
        }
    }

    private var loginBinding: Binding<Bool> {
        Binding {
            launchAtLogin
        } set: { newValue in
            launchAtLogin = LaunchAtLogin.set(newValue) ? newValue : LaunchAtLogin.isEnabled
        }
    }
}

private struct SettingsFooter: View {
    private var version: String {
        "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
    }

    var body: some View {
        HStack {
            Text(version)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
            Button("Quit Fader") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 4)
    }
}

struct StatusButton: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(.white.opacity(isOn ? 1 : 0.3))
                    .frame(width: 6, height: 6)
                Text(isOn ? "On" : "Paused")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(isOn ? 0.9 : 0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule(style: .continuous).fill(.white.opacity(0.08)))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .help(isOn ? "Pause edge gestures" : "Resume edge gestures")
    }
}
