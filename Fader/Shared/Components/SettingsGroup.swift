import SwiftUI

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content
            }
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.06))
            }
        }
    }
}

struct GroupRow<Accessory: View>: View {
    let symbol: String
    let title: String
    var showsDivider = true
    @ViewBuilder let accessory: Accessory

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 18)
                Text(title)
                Spacer(minLength: 12)
                accessory
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 40)
            if showsDivider {
                GroupDivider()
                    .padding(.leading, 40)
            }
        }
    }
}

struct GroupDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.07))
            .frame(height: 1)
    }
}

struct SliderAccessory: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueText: String

    var body: some View {
        HStack(spacing: 10) {
            SimpleSlider(value: $value, range: range)
                .frame(width: 130)
            Text(valueText)
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 36, alignment: .trailing)
        }
    }
}
