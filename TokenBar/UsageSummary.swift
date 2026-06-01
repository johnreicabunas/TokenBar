import Foundation

struct UsageSummary: Identifiable {
    var id: AgentProvider { provider }
    let provider: AgentProvider
    let inputTokens: Int
    let outputTokens: Int
    let cachedTokens: Int
    let projectNames: [String]
    let isEstimated: Bool
    let connectionStatus: String

    var totalTokens: Int {
        inputTokens + outputTokens + cachedTokens
    }
}

extension AgentProvider {
    var displayName: String {
        switch self {
        case .claude: return "Claude Code"
        case .codex: return "Codex"
        case .cursor: return "Cursor"
        }
    }
    var iconName: String {
        switch self {
        case .claude:
            return "sparkles"
        case .codex:
            return "chevron.left.forwardslash.chevron.right"
        case .cursor:
            return "cursorarrow.rays"
        }
    }
}
