import AppKit

final class AdapterMediaBackend: MediaBackend {
    private static let script = "use strict; use DynaLoader; my $handle = DynaLoader::dl_load_file($ARGV[0], 0) or die; my $symbol = DynaLoader::dl_find_symbol($handle, 'fader_bridge_run') or die; DynaLoader::dl_install_xsub('main::fader_bridge_run', $symbol); main::fader_bridge_run();"
    private static let maximumRestarts = 3

    var onUpdate: ((NowPlaying?) -> Void)?
    var onFailure: (() -> Void)?
    private(set) var isOperational = false

    private let libraryURL: URL
    private var process: Process?
    private var input: FileHandle?
    private var buffer = Data()
    private var artwork: NSImage?
    private var restarts = 0
    private var isStopping = false

    init?() {
        guard let url = Bundle.main.privateFrameworksURL?.appendingPathComponent("libFaderMediaBridge.dylib"), FileManager.default.fileExists(atPath: url.path) else { return nil }
        libraryURL = url
    }

    func start() {
        isStopping = false
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = ["-e", Self.script, libraryURL.path]
        let output = Pipe()
        let input = Pipe()
        process.standardOutput = output
        process.standardInput = input
        process.standardError = FileHandle.nullDevice
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            DispatchQueue.main.async {
                self?.consume(data)
            }
        }
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleTermination()
            }
        }
        do {
            try process.run()
        } catch {
            output.fileHandleForReading.readabilityHandler = nil
            onFailure?()
            return
        }
        self.process = process
        self.input = input.fileHandleForWriting
    }

    func stop() {
        isStopping = true
        try? input?.close()
        process?.terminate()
        process = nil
        input = nil
    }

    func refresh() {
        write("refresh")
    }

    func send(_ command: MediaCommand) {
        write(command.bridgeName)
    }

    func seek(to seconds: Double) {
        write(String(format: "seek %.3f", max(0, seconds)))
    }

    private func write(_ line: String) {
        guard let input, let data = (line + "\n").data(using: .utf8) else { return }
        try? input.write(contentsOf: data)
    }

    private func consume(_ data: Data) {
        guard !data.isEmpty else { return }
        buffer.append(data)
        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = buffer[buffer.startIndex..<newline]
            buffer = Data(buffer[buffer.index(after: newline)...])
            handle(line: Data(line))
        }
    }

    private func handle(line: Data) {
        guard let payload = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] else { return }
        if payload["error"] != nil {
            isOperational = false
            return
        }
        if payload["ready"] != nil {
            isOperational = true
            restarts = 0
            return
        }
        isOperational = true
        let nowPlaying = NowPlaying(bridge: payload, previousArtwork: artwork)
        artwork = nowPlaying?.artwork
        onUpdate?(nowPlaying)
    }

    private func handleTermination() {
        process?.standardOutput.flatMap { $0 as? Pipe }?.fileHandleForReading.readabilityHandler = nil
        process = nil
        input = nil
        buffer.removeAll()
        guard !isStopping else { return }
        let wasOperational = isOperational
        isOperational = false
        guard restarts < Self.maximumRestarts else {
            onFailure?()
            return
        }
        restarts += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + (wasOperational ? 1 : 3)) { [weak self] in
            guard let self, !self.isStopping else { return }
            self.start()
        }
    }
}
