import Foundation

enum AgentProvider: String, Codable, CaseIterable, Sendable {
    case claude
    case codex
    case cursor
}

enum TelemetryValidationError: Error {
    case invalidPayload
}

struct TelemetryEvent: Codable, Equatable, Sendable {
    let id: String
    let provider: AgentProvider
    let sessionID: String
    let projectName: String
    let model: String?
    let timestamp: Date
    let inputTokens: Int
    let outputTokens: Int
    let cachedTokens: Int
    let estimated: Bool

    var totalTokens: Int {
        inputTokens + outputTokens + cachedTokens
    }

    static func decode(_ data: Data) throws -> TelemetryEvent {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(Payload.self, from: data)
        guard
            !payload.eventID.isEmpty,
            !payload.sessionID.isEmpty,
            payload.inputTokens >= 0,
            payload.outputTokens >= 0,
            payload.cachedTokens >= 0
        else {
            throw TelemetryValidationError.invalidPayload
        }

        return TelemetryEvent(
            id: payload.eventID,
            provider: payload.provider,
            sessionID: payload.sessionID,
            projectName: URL(fileURLWithPath: payload.projectPath).lastPathComponent,
            model: payload.model,
            timestamp: payload.timestamp,
            inputTokens: payload.inputTokens,
            outputTokens: payload.outputTokens,
            cachedTokens: payload.cachedTokens,
            estimated: payload.estimated
        )
    }

    private struct Payload: Decodable {
        let eventID: String
        let provider: AgentProvider
        let sessionID: String
        let projectPath: String
        let model: String?
        let timestamp: Date
        let inputTokens: Int
        let outputTokens: Int
        let cachedTokens: Int
        let estimated: Bool

        enum CodingKeys: String, CodingKey {
            case eventID = "event_id"
            case provider
            case sessionID = "session_id"
            case projectPath = "project_path"
            case model
            case timestamp
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cachedTokens = "cached_tokens"
            case estimated
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            eventID = try container.decode(String.self, forKey: .eventID)
            provider = try container.decode(AgentProvider.self, forKey: .provider)
            sessionID = try container.decode(String.self, forKey: .sessionID)
            projectPath = try container.decodeIfPresent(String.self, forKey: .projectPath) ?? ""
            model = try container.decodeIfPresent(String.self, forKey: .model)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
            inputTokens = try container.decodeIfPresent(Int.self, forKey: .inputTokens) ?? 0
            outputTokens = try container.decodeIfPresent(Int.self, forKey: .outputTokens) ?? 0
            cachedTokens = try container.decodeIfPresent(Int.self, forKey: .cachedTokens) ?? 0
            estimated = try container.decodeIfPresent(Bool.self, forKey: .estimated) ?? false
        }
    }
}

extension TelemetryEvent {
    static func fixture(
        id: String,
        provider: AgentProvider = .claude,
        projectName: String = "TokenBar",
        timestamp: Date = Date(timeIntervalSince1970: 110),
        input: Int = 0,
        output: Int = 0,
        cached: Int = 0,
        estimated: Bool = false
    ) -> TelemetryEvent {
        TelemetryEvent(
            id: id,
            provider: provider,
            sessionID: "session-\(id)",
            projectName: projectName,
            model: nil,
            timestamp: timestamp,
            inputTokens: input,
            outputTokens: output,
            cachedTokens: cached,
            estimated: estimated
        )
    }
}
