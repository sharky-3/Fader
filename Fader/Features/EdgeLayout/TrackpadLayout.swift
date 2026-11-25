import SwiftUI

enum LayoutSlot: Hashable {
    case edge(EdgeSlot)
    case corner(CornerSlot)

    var isCorner: Bool {
        if case .corner = self {
            return true
        }
        return false
    }

    var isVertical: Bool {
        self == .edge(.left) || self == .edge(.right)
    }

    static let all: [LayoutSlot] = EdgeSlot.allCases.map { LayoutSlot.edge($0) } + CornerSlot.allCases.map { LayoutSlot.corner($0) }
}

enum LayoutItem: Hashable {
    case edge(EdgeAction)
    case corner(CornerAction)

    var title: String {
        switch self {
        case .edge(let action):
            return action.title
        case .corner(let action):
            return action.title
        }
    }

    var symbol: String {
        switch self {
        case .edge(let action):
            return action.symbol
        case .corner(let action):
            return action.symbol
        }
    }

    var isCorner: Bool {
        if case .corner = self {
            return true
        }
        return false
    }

    var isEmpty: Bool {
        switch self {
        case .edge(let action):
            return action == EdgeAction.none
        case .corner(let action):
            return action == CornerAction.none
        }
    }

    var empty: LayoutItem {
        isCorner ? .corner(CornerAction.none) : .edge(EdgeAction.none)
    }
}

struct TrackpadLayout {
    let size: CGSize
    let edgeWidth: Double
    let bottomHeight: Double
    let activeRange: ClosedRange<Double>

    static let aspect: CGFloat = 1.6
    static let cornerSize = CGFloat(GestureThresholds.cornerSize)

    var bounds: CGRect {
        CGRect(origin: .zero, size: size)
    }

    func rect(for slot: LayoutSlot) -> CGRect {
        let width = size.width
        let height = size.height
        switch slot {
        case .edge(.left), .edge(.right):
            let zoneWidth = width * CGFloat(edgeWidth)
            let top = height * CGFloat(1 - activeRange.upperBound)
            let zoneHeight = height * CGFloat(activeRange.upperBound - activeRange.lowerBound)
            let x = slot == .edge(.left) ? 0 : width - zoneWidth
            return CGRect(x: x, y: top, width: zoneWidth, height: zoneHeight)
        case .edge(.bottom):
            let zoneHeight = height * CGFloat(bottomHeight)
            return CGRect(x: 0, y: height - zoneHeight, width: width, height: zoneHeight)
        case .corner(let cornerSlot):
            let cornerWidth = width * Self.cornerSize
            let cornerHeight = height * Self.cornerSize
            let x = cornerSlot.isLeft ? 0 : width - cornerWidth
            let y = cornerSlot.isTop ? 0 : height - cornerHeight
            return CGRect(x: x, y: y, width: cornerWidth, height: cornerHeight)
        }
    }

    func slot(at point: CGPoint, accepting item: LayoutItem) -> LayoutSlot? {
        let candidates = LayoutSlot.all.filter { $0.isCorner == item.isCorner && rect(for: $0).insetBy(dx: -8, dy: -8).contains(point) }
        return candidates.min { first, second in
            let firstRect = rect(for: first)
            let secondRect = rect(for: second)
            let firstInside = firstRect.contains(point)
            let secondInside = secondRect.contains(point)
            if firstInside != secondInside {
                return firstInside
            }
            return firstRect.width * firstRect.height < secondRect.width * secondRect.height
        }
    }
}
