import XCTest
@testable import TokenBarCore

final class TelemetryEventTests: XCTestCase {
    func testDecodesMinimalEventAndStoresProjectNameOnly() throws {
        let data = Data("""
        {
          "event_id": "evt-1",
          "provider": "claude",
          "session_id": "session-1",
          "project_path": "/Users/example/Code/TokenBar",
          "model": "claude-opus",
          "timestamp": "2026-06-01T10:00:00Z",
          "input_tokens": 120,
          "output_tokens": 30,
          "cached_tokens": 50,
          "estimated": false
        }
        """.utf8)

        let event = try TelemetryEvent.decode(data)

        XCTAssertEqual(event.projectName, "TokenBar")
        XCTAssertEqual(event.totalTokens, 200)
        XCTAssertFalse(event.estimated)
    }

    func testRejectsMissingEventIdentifier() {
        let data = Data("""
        {"provider":"cursor","session_id":"session-1","timestamp":"2026-06-01T10:00:00Z"}
        """.utf8)

        XCTAssertThrowsError(try TelemetryEvent.decode(data))
    }
}
