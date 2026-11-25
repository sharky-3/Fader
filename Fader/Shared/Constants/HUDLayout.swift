import CoreGraphics

enum HUDLayout {
    static let margin: CGFloat = 40
    static let edgeInset: CGFloat = 18
    static let bottomInset: CGFloat = 30
    static let levelSize = CGSize(width: 62, height: 236)
    static let scrubSize = CGSize(width: 440, height: 86)
    static let mediaSize = CGSize(width: 190, height: 54)

    static func windowSize(for placement: HUDPlacement) -> CGSize {
        let content = placement == .bottom ? scrubSize : levelSize
        return CGSize(width: content.width + margin * 2, height: content.height + margin * 2)
    }
}
