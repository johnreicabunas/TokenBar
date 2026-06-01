import Foundation
import Combine

@MainActor
final class TelemetryService: ObservableObject {
    static let shared = TelemetryService()

    @Published private(set) var summaries: [AgentUsageSummary] = []
    @Published private(set) var lastError: String?

    private let store: DailyUsageStore
    private let queue: TelemetryQueue
    private var server: LocalTelemetryServer?
    private var reconciliationTask: Task<Void, Never>?

    private init() {
        let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".tokenbar")
        let defaults = UserDefaults.standard
        let key = "TokenBar.installationDate"
        let installationDate = defaults.object(forKey: key) as? Date ?? Date()
        defaults.set(installationDate, forKey: key)
        store = DailyUsageStore(
            installationDate: installationDate,
            fileURL: root.appendingPathComponent("events.json")
        )
        queue = TelemetryQueue(fileURL: root.appendingPathComponent("events.jsonl"))
        refresh()
    }

    func start() {
        guard server == nil else { return }
        server = LocalTelemetryServer { [weak self] event in
            Task { @MainActor in self?.record(event) }
        }
        server?.start()
        drainQueue()
        reconciliationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                self?.drainQueue()
            }
        }
    }

    func record(_ event: TelemetryEvent) {
        if store.record(event) {
            refresh()
        }
    }

    func drainQueue() {
        do {
            try queue.drain().forEach(record)
            refresh()
            lastError = nil
        } catch {
            lastError = "Could not read queued telemetry: \(error.localizedDescription)"
        }
    }

    func refresh() {
        summaries = store.summaries()
    }
}
