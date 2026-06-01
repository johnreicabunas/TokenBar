import Foundation
import Combine

@MainActor
final class UsageViewModel: ObservableObject {
    @Published var summaries: [UsageSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let provider: UsageProvider = LocalUsageProvider()

    var totalTokens: Int {
        summaries.reduce(0) { $0 + $1.totalTokens }
    }

    var menuBarTitle: String {
        if totalTokens >= 1_000_000 {
            return "\(String(format: "%.1fM", Double(totalTokens) / 1_000_000))"
        }

        if totalTokens >= 1_000 {
            return "\(String(format: "%.0fK", Double(totalTokens) / 1_000))"
        }

        return "\(totalTokens)"
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            summaries = try await provider.fetchTodayUsage()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func startMonitoring() {
        TelemetryService.shared.start()
    }
}
