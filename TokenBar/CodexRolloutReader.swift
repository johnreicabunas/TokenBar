import Foundation

final class CodexRolloutReader {
    private let sessionsDirectory: URL
    private let fileManager: FileManager

    init(codexHome: URL, fileManager: FileManager = .default) {
        sessionsDirectory = codexHome.appendingPathComponent("sessions", isDirectory: true)
        self.fileManager = fileManager
    }

    func events(since boundary: Date, now: Date = Date()) -> [TelemetryEvent] {
        rolloutFiles(from: boundary, through: now).compactMap { event(in: $0, since: boundary) }
    }

    private func rolloutFiles(from boundary: Date, through now: Date) -> [URL] {
        var urls: [URL] = []
        var date = Calendar.current.startOfDay(for: boundary)
        let end = Calendar.current.startOfDay(for: now)

        while date <= end {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            let directory = sessionsDirectory
                .appendingPathComponent(String(format: "%04d", components.year ?? 0))
                .appendingPathComponent(String(format: "%02d", components.month ?? 0))
                .appendingPathComponent(String(format: "%02d", components.day ?? 0))
            if let contents = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ) {
                urls.append(contentsOf: contents.filter { $0.pathExtension == "jsonl" })
            }
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }

        return urls
    }

    private func event(in fileURL: URL, since boundary: Date) -> TelemetryEvent? {
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }
        var sessionID: String?
        var projectPath = ""
        var baseline = Usage.zero
        var latest: (usage: Usage, timestamp: Date)?

        for line in text.split(separator: "\n") {
            guard
                let data = line.data(using: .utf8),
                let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let timestampText = object["timestamp"] as? String,
                let timestamp = Self.date(from: timestampText),
                let type = object["type"] as? String,
                let payload = object["payload"] as? [String: Any]
            else {
                continue
            }

            if type == "session_meta" {
                sessionID = payload["id"] as? String
                projectPath = payload["cwd"] as? String ?? ""
                continue
            }

            guard
                type == "event_msg",
                payload["type"] as? String == "token_count",
                let info = payload["info"] as? [String: Any],
                let totals = info["total_token_usage"] as? [String: Any]
            else {
                continue
            }

            let usage = Usage(
                input: totals["input_tokens"] as? Int ?? 0,
                cached: totals["cached_input_tokens"] as? Int ?? 0,
                output: totals["output_tokens"] as? Int ?? 0
            )
            if timestamp < boundary {
                baseline = usage
            } else {
                latest = (usage, timestamp)
            }
        }

        guard let sessionID, let latest else { return nil }
        let delta = latest.usage.subtracting(baseline)
        return TelemetryEvent(
            id: "codex-rollout-\(sessionID)",
            provider: .codex,
            sessionID: sessionID,
            projectName: URL(fileURLWithPath: projectPath).lastPathComponent,
            model: nil,
            timestamp: latest.timestamp,
            inputTokens: max(delta.input - delta.cached, 0),
            outputTokens: delta.output,
            cachedTokens: delta.cached,
            estimated: false
        )
    }

    private static func date(from string: String) -> Date? {
        let precise = ISO8601DateFormatter()
        precise.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return precise.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }

    private struct Usage {
        static let zero = Usage(input: 0, cached: 0, output: 0)
        let input: Int
        let cached: Int
        let output: Int

        func subtracting(_ other: Usage) -> Usage {
            Usage(
                input: max(input - other.input, 0),
                cached: max(cached - other.cached, 0),
                output: max(output - other.output, 0)
            )
        }
    }
}
