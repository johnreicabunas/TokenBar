import XCTest
@testable import TokenBarCore

final class SetupManagerTests: XCTestCase {
    func testPreviewIncludesAllThreeProviders() throws {
        let manager = SetupManager(rootDirectory: temporaryDirectory())

        let preview = manager.preview()

        XCTAssertTrue(preview.contains("Claude Code"))
        XCTAssertTrue(preview.contains("Cursor"))
        XCTAssertTrue(preview.contains("Codex (experimental)"))
    }

    func testInstallPreservesExistingSettingsAndCreatesBackups() throws {
        let root = temporaryDirectory()
        let claudeURL = root.appendingPathComponent(".claude/settings.json")
        let cursorURL = root.appendingPathComponent(".cursor/hooks.json")
        try FileManager.default.createDirectory(at: claudeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: cursorURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"theme":"dark"}"#.utf8).write(to: claudeURL)
        try Data(#"{"version":1,"other":"keep"}"#.utf8).write(to: cursorURL)

        let manager = SetupManager(rootDirectory: root)
        try manager.install()

        let claude = try json(at: claudeURL)
        let cursor = try json(at: cursorURL)
        XCTAssertEqual(claude["theme"] as? String, "dark")
        XCTAssertNotNil(claude["statusLine"])
        XCTAssertEqual(cursor["other"] as? String, "keep")
        XCTAssertNotNil(cursor["hooks"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: claudeURL.path + ".tokenbar-backup"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: cursorURL.path + ".tokenbar-backup"))
    }

    func testInstallDoesNotModifyCodexConfiguration() throws {
        let root = temporaryDirectory()
        let codexURL = root.appendingPathComponent(".codex/config.toml")
        try FileManager.default.createDirectory(at: codexURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let original = "notify = [\"existing-notifier\", \"turn-ended\"]\n\n[features]\nmemories = false\n"
        try Data(original.utf8).write(to: codexURL)

        try SetupManager(rootDirectory: root).install()

        XCTAssertEqual(try String(contentsOf: codexURL, encoding: .utf8), original)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    private func json(at url: URL) throws -> [String: Any] {
        try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
    }
}
