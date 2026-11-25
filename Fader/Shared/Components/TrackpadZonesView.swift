import SwiftUI

struct TrackpadZonesView: View {
    var edgeWidth = PreferenceDefault.edgeWidth
    var bottomHeight = PreferenceDefault.bottomHeight
    var activeRange: ClosedRange<Double> = 0...1
    var swapSides = false
    var highlighted: Set<EdgeZone> = []
    var touches: [TouchSample] = []
    var showsSymbols = true

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let corner = GestureThresholds.cornerSize
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.primary.opacity(0.05))
                zone(.left, color: swapSides ? Palette.volume : Palette.brightness, symbol: swapSides ? "speaker.wave.2.fill" : "sun.max.fill")
                    .frame(width: width * edgeWidth, height: height * (activeRange.upperBound - activeRange.lowerBound))
                    .offset(y: height * (1 - activeRange.upperBound))
                zone(.right, color: swapSides ? Palette.brightness : Palette.volume, symbol: swapSides ? "sun.max.fill" : "speaker.wave.2.fill")
                    .frame(width: width * edgeWidth, height: height * (activeRange.upperBound - activeRange.lowerBound))
                    .offset(x: width * (1 - edgeWidth), y: height * (1 - activeRange.upperBound))
                zone(.bottom, color: Palette.media, symbol: "playpause.fill")
                    .frame(width: width, height: height * bottomHeight)
                    .offset(y: height * (1 - bottomHeight))
                zone(.corner, color: Palette.mute, symbol: "speaker.slash.fill")
                    .frame(width: width * corner, height: height * corner)
                    .offset(x: width * (1 - corner))
                ForEach(touches) { touch in
                    Circle()
                        .fill(touch.isContact ? AnyShapeStyle(.white) : AnyShapeStyle(.white.opacity(0.35)))
                        .overlay(Circle().strokeBorder(.black.opacity(0.12), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                        .frame(width: 22, height: 22)
                        .offset(x: width * touch.x - 11, y: height * (1 - touch.y) - 11)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.primary.opacity(0.14), lineWidth: 1)
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: highlighted)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: edgeWidth)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: bottomHeight)
    }

    private func zone(_ zone: EdgeZone, color: Color, symbol: String) -> some View {
        let isLit = highlighted.contains(zone)
        return Rectangle()
            .fill(color.opacity(isLit ? 0.55 : 0.2))
            .overlay {
                if showsSymbols {
                    Image(systemName: symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(color)
                        .opacity(isLit ? 1 : 0.8)
                }
            }
    }
}
