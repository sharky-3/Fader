import SwiftUI

struct SimpleSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack {
                Capsule(style: .continuous)
                    .fill(.white.opacity(isOn ? 1 : 0.18))
                Circle()
                    .fill(isOn ? Color.black : Color.white)
                    .frame(width: 14, height: 14)
                    .offset(x: isOn ? 7 : -7)
            }
            .frame(width: 34, height: 20)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isOn)
    }
}

struct SimpleSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fraction = ((value - range.lowerBound) / (range.upperBound - range.lowerBound)).clamped(to: 0...1)
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.18))
                    .frame(height: 3)
                Capsule(style: .continuous)
                    .fill(.white)
                    .frame(width: width * fraction, height: 3)
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .offset(x: (width - 12) * fraction)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                let position = ((gesture.location.x - 6) / max(width - 12, 1)).clamped(to: 0...1)
                value = range.lowerBound + position * (range.upperBound - range.lowerBound)
            })
        }
        .frame(height: 16)
    }
}

struct PlainPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule(style: .continuous).fill(.white.opacity(configuration.isPressed ? 0.25 : 0.14)))
    }
}

struct SimpleSegments<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = option
                    }
                } label: {
                    Text(title(option))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background {
                            if isSelected {
                                Capsule(style: .continuous)
                                    .fill(.white)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Capsule(style: .continuous).fill(.white.opacity(0.12)))
    }
}

struct CycleButton<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    var body: some View {
        Button {
            let index = options.firstIndex(of: selection) ?? -1
            selection = options[(index + 1) % options.count]
        } label: {
            HStack(spacing: 5) {
                Text(title(selection))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .font(.system(size: 11.5, weight: .medium))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule(style: .continuous).fill(.white.opacity(0.12)))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

