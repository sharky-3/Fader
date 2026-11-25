import Foundation

extension Double {
    var timecode: String {
        let total = Int(max(0, self).rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var signedTimecode: String {
        let sign = self < 0 ? "−" : "+"
        return sign + abs(self).timecode
    }

    var percentText: String {
        "\(Int((self * 100).rounded()))"
    }
}
