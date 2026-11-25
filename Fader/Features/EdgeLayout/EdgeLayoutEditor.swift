import SwiftUI

struct LayoutDragState: Equatable {
    let item: LayoutItem
    let source: LayoutSlot?
    var location: CGPoint
}

struct EdgeLayoutEditor: View {
    let haptics: HapticEngine
    var width: CGFloat = 332

    @AppStorage(PreferenceKey.leftEdgeAction) private var left = EdgeAction.brightness.rawValue
    @AppStorage(PreferenceKey.rightEdgeAction) private var right = EdgeAction.volume.rawValue
    @AppStorage(PreferenceKey.bottomEdgeAction) private var bottom = EdgeAction.video.rawValue
    @AppStorage(PreferenceKey.topLeftCornerAction) private var topLeft = CornerAction.none.rawValue
    @AppStorage(PreferenceKey.topRightCornerAction) private var topRight = CornerAction.mute.rawValue
    @AppStorage(PreferenceKey.bottomLeftCornerAction) private var bottomLeft = CornerAction.none.rawValue
    @AppStorage(PreferenceKey.bottomRightCornerAction) private var bottomRight = CornerAction.none.rawValue
    @AppStorage(PreferenceKey.edgeWidth) private var edgeWidth = PreferenceDefault.edgeWidth
    @AppStorage(PreferenceKey.bottomHeight) private var bottomHeight = PreferenceDefault.bottomHeight
    @AppStorage(PreferenceKey.activeArea) private var activeArea = ActiveArea.full.rawValue

    @State private var drag: LayoutDragState?

    private static let space = "edgeLayout"

    private var layout: TrackpadLayout {
        TrackpadLayout(size: CGSize(width: width, height: width / TrackpadLayout.aspect), edgeWidth: edgeWidth, bottomHeight: bottomHeight, activeRange: (ActiveArea(rawValue: activeArea) ?? .full).range)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                trackpad
                measurements
            }
            palette
            Text("Only what is placed on the trackpad works. Corners need a double-tap. Drag to move, × to remove.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.35))
        }
        .coordinateSpace(name: Self.space)
        .overlay(alignment: .topLeading) {
            dragPreview
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: hoveredSlot)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: edgeWidth)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: bottomHeight)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: activeArea)
    }

    @ViewBuilder
    private var dragPreview: some View {
        if let drag {
            ItemChip(item: drag.item, isLifted: true)
                .position(drag.location)
                .allowsHitTesting(false)
        }
    }

    private var trackpad: some View {
        let layout = self.layout
        let order = [LayoutSlot.edge(.bottom), .edge(.left), .edge(.right)] + CornerSlot.allCases.map { LayoutSlot.corner($0) }
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.05))
            ForEach(order, id: \.self) { slot in
                slotView(slot, layout: layout)
            }
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private var measurements: some View {
        let range = (ActiveArea(rawValue: activeArea) ?? .full).range
        let activeText = range == 0...1 ? "full" : "\(Int((range.upperBound - range.lowerBound) * 100))%"
        return HStack(spacing: 14) {
            MeasureLabel(symbol: "arrow.left.and.right", text: "Sides \(edgeWidth.percentText)% wide · \(activeText) tall")
            MeasureLabel(symbol: "arrow.up.and.down", text: "Bottom \(bottomHeight.percentText)%")
            MeasureLabel(symbol: "square", text: "Corners \(GestureThresholds.cornerSize.percentText)%")
        }
    }

    private var palette: some View {
        VStack(alignment: .leading, spacing: 8) {
            paletteRow(title: "Edges", items: EdgeAction.assignable.map { LayoutItem.edge($0) })
            paletteRow(title: "Corners", items: CornerAction.assignable.map { LayoutItem.corner($0) })
        }
    }

    private func paletteRow(title: String, items: [LayoutItem]) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 54, alignment: .leading)
            ForEach(items, id: \.self) { item in
                ItemChip(item: item)
                    .opacity(chipOpacity(item))
                    .gesture(dragGesture(item, from: nil))
            }
        }
    }

    private var hoveredSlot: LayoutSlot? {
        guard let drag else { return nil }
        return layout.slot(at: drag.location, accepting: drag.item)
    }

    private func slotView(_ slot: LayoutSlot, layout: TrackpadLayout) -> some View {
        let rect = layout.rect(for: slot)
        let current = content(of: slot)
        return SlotView(item: current, slot: slot, isTarget: hoveredSlot == slot, isSource: drag?.source == slot) {
            remove(slot)
        }
        .frame(width: rect.width, height: rect.height)
        .contentShape(Rectangle())
        .gesture(dragGesture(current, from: slot))
        .position(x: rect.midX, y: rect.midY)
    }

    private func chipOpacity(_ item: LayoutItem) -> Double {
        if let drag, drag.source == nil, drag.item == item {
            return 0.2
        }
        let isPlaced = LayoutSlot.all.contains(where: { content(of: $0) == item })
        return isPlaced ? 0.4 : 1
    }

    private func dragGesture(_ item: LayoutItem, from source: LayoutSlot?) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(Self.space))
            .onChanged { value in
                guard !item.isEmpty else { return }
                if drag == nil {
                    haptics.tick(deviceID: nil)
                }
                drag = LayoutDragState(item: item, source: source, location: value.location)
            }
            .onEnded { value in
                guard !item.isEmpty else { return }
                drop(item, from: source, at: value.location)
            }
    }

    private func drop(_ item: LayoutItem, from source: LayoutSlot?, at location: CGPoint) {
        let layout = self.layout
        var changes: [(LayoutSlot, LayoutItem)] = []
        if let target = layout.slot(at: location, accepting: item) {
            let previous = content(of: target)
            changes.append((target, item))
            if let source, source != target {
                changes.append((source, previous))
            } else if source == nil, let other = LayoutSlot.all.first(where: { $0 != target && content(of: $0) == item }) {
                changes.append((other, previous))
            }
        } else if let source, !layout.bounds.insetBy(dx: -6, dy: -6).contains(location) {
            changes.append((source, item.empty))
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            drag = nil
            for change in changes {
                set(change.1, in: change.0)
            }
        }
        haptics.tick(deviceID: nil)
    }

    private func remove(_ slot: LayoutSlot) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            set(content(of: slot).empty, in: slot)
        }
        haptics.tick(deviceID: nil)
    }

    private func content(of slot: LayoutSlot) -> LayoutItem {
        switch slot {
        case .edge(let edge):
            return .edge(EdgeAction(rawValue: edgeValue(edge)) ?? EdgeAction.none)
        case .corner(let corner):
            return .corner(CornerAction(rawValue: cornerValue(corner)) ?? CornerAction.none)
        }
    }

    private func edgeValue(_ edge: EdgeSlot) -> String {
        switch edge {
        case .left:
            return left
        case .right:
            return right
        case .bottom:
            return bottom
        }
    }

    private func cornerValue(_ corner: CornerSlot) -> String {
        switch corner {
        case .topLeft:
            return topLeft
        case .topRight:
            return topRight
        case .bottomLeft:
            return bottomLeft
        case .bottomRight:
            return bottomRight
        }
    }

    private func set(_ item: LayoutItem, in slot: LayoutSlot) {
        switch (slot, item) {
        case let (.edge(edge), .edge(action)):
            switch edge {
            case .left:
                left = action.rawValue
            case .right:
                right = action.rawValue
            case .bottom:
                bottom = action.rawValue
            }
        case let (.corner(corner), .corner(action)):
            switch corner {
            case .topLeft:
                topLeft = action.rawValue
            case .topRight:
                topRight = action.rawValue
            case .bottomLeft:
                bottomLeft = action.rawValue
            case .bottomRight:
                bottomRight = action.rawValue
            }
        default:
            break
        }
    }
}

struct ItemChip: View {
    let item: LayoutItem
    var isLifted = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: item.symbol)
                .font(.system(size: 10, weight: .semibold))
            Text(item.title)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule(style: .continuous).fill(Color(white: isLifted ? 0.28 : 0.15)))
        .scaleEffect(isLifted ? 1.08 : 1)
        .contentShape(Capsule(style: .continuous))
    }
}

private struct SlotView: View {
    let item: LayoutItem
    let slot: LayoutSlot
    let isTarget: Bool
    let isSource: Bool
    let onRemove: () -> Void

    private var radius: CGFloat {
        4
    }

    private var fillOpacity: Double {
        if isTarget {
            return 0.3
        }
        return item.isEmpty ? 0.02 : 0.16
    }

    private var borderOpacity: Double {
        item.isEmpty || isTarget ? 0.3 : 0.22
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.white.opacity(fillOpacity))
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(.white.opacity(borderOpacity), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            if item.isEmpty {
                Circle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 4, height: 4)
            } else {
                SlotLabel(item: item, slot: slot)
                    .opacity(isSource ? 0.2 : 1)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .overlay(alignment: .topTrailing) {
            if !item.isEmpty && !isSource {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 15, height: 15)
                        .background(Circle().fill(Color(white: 0.3)))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(3)
                .help("Remove")
                .transition(.opacity)
            }
        }
    }
}

private struct MeasureLabel: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 8.5, weight: .semibold))
            Text(text)
                .font(.system(size: 10.5, weight: .medium))
                .monospacedDigit()
        }
        .foregroundStyle(.white.opacity(0.4))
        .lineLimit(1)
    }
}

private struct SlotLabel: View {
    let item: LayoutItem
    let slot: LayoutSlot

    var body: some View {
        Group {
            if slot.isCorner {
                Image(systemName: item.symbol)
                    .font(.system(size: 12, weight: .semibold))
            } else if slot.isVertical {
                VStack(spacing: 6) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "arrow.up.and.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            } else {
                HStack(spacing: 5) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 10, weight: .semibold))
                    Text(item.title)
                        .font(.system(size: 10.5, weight: .medium))
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .foregroundStyle(.white)
        .help(item.title)
    }
}
