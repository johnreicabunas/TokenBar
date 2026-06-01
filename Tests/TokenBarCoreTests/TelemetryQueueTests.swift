import XCTest
@testable import TokenBarCore

final class TelemetryQueueTests: XCTestCase {
    func testDrainReturnsValidEventsAndClearsFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let queue = TelemetryQueue(fileURL: url)
        try queue.append(.fixture(id: "one", input: 12))
        try queue.append(.fixture(id: "two", output: 4))

        let events = try queue.drain()

        XCTAssertEqual(events.map(\.id), ["one", "two"])
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "")
    }

    func testDrainSkipsMalformedLines() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("not-json\n".utf8).write(to: url)
        let queue = TelemetryQueue(fileURL: url)

        XCTAssertEqual(try queue.drain(), [])
    }
}
