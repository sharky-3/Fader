import AppKit

struct GestureActivity: Equatable {
    let symbol: String
    let title: String
}

@MainActor
final class GestureCoordinator: ObservableObject {
    @Published private(set) var activity: GestureActivity?

    private struct LevelSession {
        let action: GestureAction
        let placement: HUDPlacement
        let deviceID: UInt64
        let isAvailable: Bool
        var value: Double
    }

    private struct ScrubSession {
        let deviceID: UInt64
        let isEnabled: Bool
        let isTimeline: Bool
        let title: String?
        let startElapsed: Double
        let duration: Double
        let began: TimeInterval
        let needsPermission: Bool
        var offset: Double = 0
        var appliedOffset: Double = 0
        var lastApplied: TimeInterval = 0
        var sentArrows = 0
    }

    private let brightness: BrightnessController
    private let volume: VolumeController
    private let mute: MuteController
    private let media: MediaController
    private let hud: HUDPresenter
    private let haptics: HapticEngine
    private var levelSession: LevelSession?
    private var scrubSession: ScrubSession?

    init(brightness: BrightnessController, volume: VolumeController, mute: MuteController, media: MediaController, hud: HUDPresenter, haptics: HapticEngine) {
        self.brightness = brightness
        self.volume = volume
        self.mute = mute
        self.media = media
        self.hud = hud
        self.haptics = haptics
    }

    func handle(_ event: GestureEvent) {
        switch event {
        case let .began(action, zone, deviceID, origin):
            begin(action, zone: zone, deviceID: deviceID, origin: origin)
        case let .moved(action, delta, velocity):
            if action == .scrub {
                moveScrub(delta: delta, velocity: velocity)
            } else {
                moveLevel(delta: delta)
            }
        case let .ended(action):
            finish(action, commit: true)
        case let .cancelled(action):
            finish(action, commit: false)
        case let .flick(forward, deviceID):
            flick(forward: forward, deviceID: deviceID)
        case let .tap(deviceID):
            togglePlayback(deviceID: deviceID)
        case let .cornerDoubleTap(action, deviceID):
            switch action {
            case .mute:
                toggleMute(deviceID: deviceID)
            case .playPause:
                togglePlayback(deviceID: deviceID)
            case .none:
                break
            }
        }
    }

    func cancelAll() {
        levelSession = nil
        scrubSession = nil
        CursorLock.unlock()
    }

    private var defaults: UserDefaults { .standard }

    private var sensitivity: Double {
        defaults.double(forKey: PreferenceKey.sensitivity).clamped(to: PreferenceDefault.sensitivityRange)
    }

    private var isFineControl: Bool {
        let flags = CGEventSource.flagsState(.combinedSessionState)
        return flags.contains(.maskShift) && flags.contains(.maskAlternate)
    }

    private func begin(_ action: GestureAction, zone: EdgeZone, deviceID: UInt64, origin: CGPoint?) {
        CursorLock.lock(at: origin)
        switch action {
        case .brightness, .volume:
            let placement: HUDPlacement = zone == .left ? .left : .right
            let session: LevelSession
            if action == .brightness {
                brightness.refresh()
                session = LevelSession(action: action, placement: placement, deviceID: deviceID, isAvailable: brightness.isAvailable, value: brightness.value)
            } else {
                volume.refresh()
                session = LevelSession(action: action, placement: placement, deviceID: deviceID, isAvailable: volume.isAvailable, value: volume.isMuted ? 0 : volume.volume)
            }
            levelSession = session
            present(session)
        case .scrub:
            let snapshot = media.nowPlaying
            let isTimeline = media.canSeek
            let session = ScrubSession(deviceID: deviceID, isEnabled: defaults.bool(forKey: PreferenceKey.scrubEnabled), isTimeline: isTimeline, title: snapshot?.title, startElapsed: isTimeline ? snapshot?.elapsed(at: Date()) ?? 0 : 0, duration: snapshot?.duration ?? 0, began: ProcessInfo.processInfo.systemUptime, needsPermission: !isTimeline && !AXIsProcessTrusted())
            scrubSession = session
            if session.isEnabled {
                present(session)
            }
        }
    }

    private func moveLevel(delta: Double) {
        guard var session = levelSession, session.isAvailable else { return }
        let fine = isFineControl
        let gain = ControlTuning.levelGain * sensitivity / (fine ? ControlTuning.fineDivisor : 1)
        let previous = session.value
        let value = (previous + delta * gain).clamped(to: 0...1)
        guard value != previous else { return }
        session.value = value
        levelSession = session
        if session.action == .brightness {
            brightness.set(value)
        } else {
            volume.set(value)
        }
        let steps = ControlTuning.levelSteps * (fine ? ControlTuning.fineDivisor : 1)
        if crossed(previous, value, unit: 1 / steps) {
            haptics.tick(deviceID: session.deviceID)
        }
        present(session)
    }

    private func moveScrub(delta: Double, velocity: Double) {
        guard var session = scrubSession, session.isEnabled else { return }
        let fine = isFineControl
        let acceleration = 1 + ((abs(velocity) - ControlTuning.scrubAccelerationThreshold) * ControlTuning.scrubAccelerationGain).clamped(to: 0...(ControlTuning.scrubMaxAcceleration - 1))
        let seconds = delta * ControlTuning.scrubSecondsPerWidth * sensitivity * acceleration / (fine ? ControlTuning.fineDivisor : 1)
        let previous = session.offset
        var offset = previous + seconds
        if session.isTimeline {
            offset = offset.clamped(to: -session.startElapsed...max(0, session.duration - session.startElapsed))
        }
        guard offset != previous else { return }
        session.offset = offset
        let unit = fine ? ControlTuning.scrubFineTickSeconds : ControlTuning.scrubTickSeconds
        if crossed(previous, offset, unit: unit) {
            haptics.tick(deviceID: session.deviceID)
        }
        let now = ProcessInfo.processInfo.systemUptime
        if now - session.began > GestureThresholds.flickMaxDuration {
            apply(&session, now: now, force: false)
        }
        scrubSession = session
        present(session)
    }

    private func apply(_ session: inout ScrubSession, now: TimeInterval, force: Bool) {
        if session.isTimeline {
            guard session.offset != session.appliedOffset, force || now - session.lastApplied >= ControlTuning.liveSeekInterval else { return }
            media.seek(to: session.startElapsed + session.offset)
            session.appliedOffset = session.offset
            session.lastApplied = now
        } else {
            let target = Int((session.offset / ControlTuning.arrowSeekSeconds).rounded(.towardZero))
            let difference = target - session.sentArrows
            guard difference != 0 else { return }
            media.stepWithArrows(count: abs(difference), forward: difference > 0)
            session.sentArrows = target
        }
    }

    private func finish(_ action: GestureAction, commit: Bool) {
        CursorLock.unlock()
        if action == .scrub {
            if commit, var session = scrubSession, session.isEnabled {
                apply(&session, now: ProcessInfo.processInfo.systemUptime, force: true)
                if session.offset != 0 {
                    activity = GestureActivity(symbol: session.offset < 0 ? "gobackward" : "goforward", title: "Scrubbed \(session.offset.signedTimecode)")
                }
            }
            scrubSession = nil
        } else {
            levelSession = nil
        }
        hud.scheduleHide()
    }

    private func flick(forward: Bool, deviceID: UInt64) {
        scrubSession = nil
        CursorLock.unlock()
        if forward {
            media.next()
        } else {
            media.previous()
        }
        haptics.tick(deviceID: deviceID)
        hud.show(.media(forward ? .next : .previous))
        hud.scheduleHide()
        activity = GestureActivity(symbol: forward ? "forward.fill" : "backward.fill", title: forward ? "Next Track" : "Previous Track")
    }

    private func togglePlayback(deviceID: UInt64) {
        let willPlay = !media.isPlaying
        media.togglePlayPause()
        haptics.tick(deviceID: deviceID)
        hud.show(.media(willPlay ? .play : .pause))
        hud.scheduleHide()
        activity = GestureActivity(symbol: willPlay ? "play.fill" : "pause.fill", title: willPlay ? "Play" : "Pause")
    }

    private func toggleMute(deviceID: UInt64) {
        guard mute.toggle() else { return }
        haptics.tick(deviceID: deviceID)
        hud.show(.level(LevelState(kind: .volume, value: volume.volume, isMuted: mute.isMuted, isAvailable: volume.isAvailable, placement: .right)))
        hud.scheduleHide()
        activity = GestureActivity(symbol: mute.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill", title: mute.isMuted ? "Muted" : "Unmuted")
    }

    private func present(_ session: LevelSession) {
        let kind: LevelKind = session.action == .brightness ? .brightness : .volume
        let isMuted = kind == .volume && volume.isMuted
        hud.show(.level(LevelState(kind: kind, value: session.value, isMuted: isMuted, isAvailable: session.isAvailable, placement: session.placement)))
        let name = kind == .brightness ? "Brightness" : "Volume"
        activity = GestureActivity(symbol: kind == .brightness ? "sun.max.fill" : "speaker.wave.3.fill", title: session.isAvailable ? "\(name) \(session.value.percentText)%" : "\(name) unavailable")
    }

    private func present(_ session: ScrubSession) {
        let offset = session.isTimeline ? session.offset : Double(Int((session.offset / ControlTuning.arrowSeekSeconds).rounded(.towardZero))) * ControlTuning.arrowSeekSeconds
        hud.show(.scrub(ScrubState(title: session.title, startElapsed: session.startElapsed, duration: session.isTimeline ? session.duration : nil, offset: offset, needsPermission: session.needsPermission)))
        activity = GestureActivity(symbol: offset < 0 ? "gobackward" : "goforward", title: "Scrub \(offset.signedTimecode)")
    }

    private func crossed(_ previous: Double, _ current: Double, unit: Double) -> Bool {
        (previous / unit).rounded(.down) != (current / unit).rounded(.down)
    }
}
