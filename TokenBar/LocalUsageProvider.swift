import Foundation

struct LocalUsageProvider: UsageProvider {
    func fetchTodayUsage() async throws -> [UsageSummary] {
        let indexed = Dictionary(uniqueKeysWithValues: TelemetryService.shared.summaries.map { ($0.provider, $0) })
        return AgentProvider.allCases.map { provider in
            let summary = indexed[provider]
            return UsageSummary(
                provider: provider,
                inputTokens: summary?.inputTokens ?? 0,
                outputTokens: summary?.outputTokens ?? 0,
                cachedTokens: summary?.cachedTokens ?? 0,
                projectNames: summary?.projectNames ?? [],
                isEstimated: summary?.isEstimated ?? (provider == .cursor),
                connectionStatus: provider == .codex ? "Experimental bridge" : "Listening locally"
            )
        }
    }
}
