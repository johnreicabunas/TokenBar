import Foundation

final class TelemetryQueue {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func append(_ event: TelemetryEvent) throws {
        try ensureParentDirectory()
        let line = try encoder.encode(event) + Data([0x0A])
        if !fileManager.fileExists(atPath: fileURL.path) {
            try line.write(to: fileURL, options: .atomic)
            return
        }

        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }

    func drain() throws -> [TelemetryEvent] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        try Data().write(to: fileURL, options: .atomic)
        return data.split(separator: 0x0A).compactMap {
            try? decoder.decode(TelemetryEvent.self, from: Data($0))
        }
    }

    private func ensureParentDirectory() throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }
}
