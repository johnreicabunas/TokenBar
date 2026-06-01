import Foundation

protocol UsageProvider {
    func fetchTodayUsage() async throws -> [UsageSummary]
}
