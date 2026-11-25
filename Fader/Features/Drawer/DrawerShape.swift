import SwiftUI

struct DrawerShape: Shape {
    var progress: Double
    let edge: DrawerEdge
    let size: CGSize
    let fillet: CGFloat
    let cornerRadius: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let travel = CGFloat(progress)
        guard travel > 0.002 else { return Path() }
        let grow = min(max(travel, 0), 1)
        let eased = grow * grow * (3 - 2 * grow)
        let width = size.width * travel
        let height = 96 + (size.height - 96) * eased
        let bulge = 24 * sin(.pi * grow)
        let ear = min(fillet, width * 0.4)
        let radius = min(cornerRadius, width * 0.5, height * 0.5)
        let top = rect.midY - height / 2
        let bottom = rect.midY + height / 2
        let wall = rect.maxX
        let outer = wall - width
        let span = bottom - top - radius * 2

        var path = Path()
        path.move(to: CGPoint(x: wall, y: top - ear))
        path.addQuadCurve(to: CGPoint(x: wall - ear, y: top), control: CGPoint(x: wall, y: top))
        path.addLine(to: CGPoint(x: outer + radius, y: top))
        path.addQuadCurve(to: CGPoint(x: outer, y: top + radius), control: CGPoint(x: outer, y: top))
        path.addCurve(to: CGPoint(x: outer, y: bottom - radius), control1: CGPoint(x: outer - bulge, y: top + radius + span * 0.25), control2: CGPoint(x: outer - bulge, y: bottom - radius - span * 0.25))
        path.addQuadCurve(to: CGPoint(x: outer + radius, y: bottom), control: CGPoint(x: outer, y: bottom))
        path.addLine(to: CGPoint(x: wall - ear, y: bottom))
        path.addQuadCurve(to: CGPoint(x: wall, y: bottom + ear), control: CGPoint(x: wall, y: bottom))
        path.closeSubpath()

        if edge == .left {
            return path.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.minX + rect.maxX, ty: 0))
        }
        return path
    }
}
