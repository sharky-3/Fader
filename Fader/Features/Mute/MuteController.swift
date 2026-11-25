import Foundation

final class MuteController {
    private let volume: VolumeController

    init(volume: VolumeController) {
        self.volume = volume
    }

    var isMuted: Bool { volume.isMuted }

    @discardableResult
    func toggle() -> Bool {
        volume.refresh()
        guard volume.canMute else { return false }
        volume.toggleMute()
        return true
    }
}
