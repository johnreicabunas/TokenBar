import XCTest
@testable import TokenBarCore

final class CodexRolloutReaderTests: XCTestCase {
    func testReadsLatestUsageDeltaAfterInstallationBoundary() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sessionURL = root.appendingPathComponent("sessions/2026/06/01/rollout-test.jsonl")
        try FileManager.default.createDirectory(at: sessionURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let lines = [
            #"{"timestamp":"2026-06-01T09:00:00Z","type":"session_meta","payload":{"id":"session-1","cwd":"/tmp/TokenBar","model_provider":"openai"}}"#,
            #"{"timestamp":"2026-06-01T09:30:00Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":100,"cached_input_tokens":60,"output_tokens":20}}}}"#,
            #"{"timestamp":"2026-06-01T10:30:00Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":180,"cached_input_tokens":90,"output_tokens":35}}}}"#
        ]
        try Data(lines.joined(separator: "\n").utf8).write(to: sessionURL)
        let boundary = ISO8601DateFormatter().date(from: "2026-06-01T10:00:00Z")!

        let events = CodexRolloutReader(codexHome: root).events(since: boundary)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].id, "codex-rollout-session-1")
        XCTAssertEqual(events[0].projectName, "TokenBar")
        XCTAssertEqual(events[0].inputTokens, 50)
        XCTAssertEqual(events[0].cachedTokens, 30)
        XCTAssertEqual(events[0].outputTokens, 15)
    }
}
