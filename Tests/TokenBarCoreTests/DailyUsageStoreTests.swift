import XCTest
@testable import TokenBarCore

final class DailyUsageStoreTests: XCTestCase {
    func testIgnoresDuplicateAndPreInstallEvents() throws {
        let installationDate = Date(timeIntervalSince1970: 100)
        let store = DailyUsageStore(installationDate: installationDate)
        let accepted = TelemetryEvent.fixture(id: "accepted", timestamp: Date(timeIntervalSince1970: 110), input: 10)
        let old = TelemetryEvent.fixture(id: "old", timestamp: Date(timeIntervalSince1970: 90), input: 99)

        XCTAssertTrue(store.record(accepted))
        XCTAssertFalse(store.record(accepted))
        XCTAssertFalse(store.record(old))
        XCTAssertEqual(store.summaries(for: accepted.timestamp).first?.inputTokens, 10)
    }

    func testAggregatesProviderProjectsAndEstimatedState() {
        let store = DailyUsageStore(installationDate: .distantPast)
        store.record(.fixture(id: "1", provider: .cursor, projectName: "TokenBar", input: 10, estimated: true))
        store.record(.fixture(id: "2", provider: .cursor, projectName: "Notes", output: 4, estimated: true))

        let summary = store.summaries(for: Date(timeIntervalSince1970: 110)).first

        XCTAssertEqual(summary?.provider, .cursor)
        XCTAssertEqual(summary?.totalTokens, 14)
        XCTAssertEqual(summary?.projectNames, ["Notes", "TokenBar"])
        XCTAssertEqual(summary?.isEstimated, true)
    }

    func testReplaceUpdatesSnapshotWithoutDoubleCounting() {
        let store = DailyUsageStore(installationDate: .distantPast)
        store.replace(.fixture(id: "codex-session", provider: .codex, input: 10))
        store.replace(.fixture(id: "codex-session", provider: .codex, input: 25))

        let summary = store.summaries(for: Date(timeIntervalSince1970: 110)).first

        XCTAssertEqual(summary?.inputTokens, 25)
    }
}
