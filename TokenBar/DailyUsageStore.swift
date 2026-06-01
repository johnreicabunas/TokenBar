import Foundation

struct AgentUsageSummary: Identifiable, Equatable, Sendable {
    var id: AgentProvider { provider }
    let provider: AgentProvider
    let inputTokens: Int
    let outputTokens: Int
    let cachedTokens: Int
    let projectNames: [String]
    let isEstimated: Bool

    var totalTokens: Int {
        inputTokens + outputTokens + cachedTokens
    }
}

final class DailyUsageStore {
    private let installationDate: Date
    private let calendar: Calendar
    private let fileURL: URL?
    private var events: [String: TelemetryEvent] = [:]

    init(installationDate: Date, calendar: Calendar = .current, fileURL: URL? = nil) {
        self.installationDate = installationDate
        self.calendar = calendar
        self.fileURL = fileURL
        load()
    }

    @discardableResult
    func record(_ event: TelemetryEvent) -> Bool {
        guard event.timestamp >= installationDate, events[event.id] == nil else {
            return false
        }

        events[event.id] = event
        persist()
        return true
    }

    func summaries(for date: Date = Date()) -> [AgentUsageSummary] {
        AgentProvider.allCases.compactMap { provider in
            let matching = events.values.filter {
                $0.provider == provider && calendar.isDate($0.timestamp, inSameDayAs: date)
            }
            guard !matching.isEmpty else { return nil }

            return AgentUsageSummary(
                provider: provider,
                inputTokens: matching.reduce(0) { $0 + $1.inputTokens },
                outputTokens: matching.reduce(0) { $0 + $1.outputTokens },
                cachedTokens: matching.reduce(0) { $0 + $1.cachedTokens },
                projectNames: Array(Set(matching.map(\.projectName).filter { !$0.isEmpty })).sorted(),
                isEstimated: matching.contains(where: \.estimated)
            )
        }
    }

    private func load() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let saved = try? decoder.decode([TelemetryEvent].self, from: data) else { return }
        events = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
    }

    private func persist() {
        guard let fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(Array(events.values)) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }
}
