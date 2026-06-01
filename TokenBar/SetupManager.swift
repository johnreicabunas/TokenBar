import Foundation

struct SetupStatus: Equatable {
    let isInstalled: Bool
    let message: String
}

final class SetupManager {
    private let rootDirectory: URL
    private let fileManager: FileManager

    init(
        rootDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
    }

    var tokenBarDirectory: URL {
        rootDirectory.appendingPathComponent(".tokenbar", isDirectory: true)
    }

    var queueURL: URL {
        tokenBarDirectory.appendingPathComponent("events.jsonl")
    }

    var bridgeURL: URL {
        tokenBarDirectory.appendingPathComponent("bin/tokenbar-bridge.py")
    }

    func preview() -> String {
        """
        TokenBar installs one local bridge script at:
        \(bridgeURL.path)

        Claude Code
        - Adds a statusLine command in ~/.claude/settings.json.

        Cursor
        - Adds session and tool activity hooks in ~/.cursor/hooks.json.
        - Cursor token totals are marked Estimated when exact values are unavailable.

        Codex (experimental)
        - Adds a notify command in ~/.codex/config.toml.
        - Compatibility depends on the installed Codex version.

        Events are sent to http://127.0.0.1:47831/events or queued locally when TokenBar is closed.
        """
    }

    func manualInstructions() -> String {
        """
        1. Review the guided preview.
        2. Install \(bridgeURL.path) as an executable script.
        3. Configure Claude Code statusLine to run: \(bridgeURL.path) claude
        4. Configure Cursor hooks to run: \(bridgeURL.path) cursor
        5. Configure Codex notify to run: \(bridgeURL.path) codex
        6. Start TokenBar and use Refresh to drain queued events.
        """
    }

    func install() throws {
        try fileManager.createDirectory(at: bridgeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(Self.bridgeScript.utf8).write(to: bridgeURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: bridgeURL.path)
        try mergeClaudeSettings()
        try mergeCursorSettings()
        try mergeCodexSettings()
    }

    func uninstall() throws {
        try restoreBackupIfPresent(for: claudeSettingsURL)
        try restoreBackupIfPresent(for: cursorSettingsURL)
        let codexURL = codexSettingsURL
        guard fileManager.fileExists(atPath: codexURL.path) else { return }
        let text = try String(contentsOf: codexURL, encoding: .utf8)
        let cleaned = text.replacingOccurrences(
            of: "\n# TokenBar experimental bridge\nnotify = [\"\(bridgeURL.path)\", \"codex\"]\n",
            with: ""
        )
        try Data(cleaned.utf8).write(to: codexURL, options: .atomic)
    }

    func status() -> SetupStatus {
        SetupStatus(
            isInstalled: fileManager.fileExists(atPath: bridgeURL.path),
            message: fileManager.fileExists(atPath: bridgeURL.path)
                ? "Local bridge installed"
                : "Setup required"
        )
    }

    private var claudeSettingsURL: URL {
        rootDirectory.appendingPathComponent(".claude/settings.json")
    }

    private var cursorSettingsURL: URL {
        rootDirectory.appendingPathComponent(".cursor/hooks.json")
    }

    private var codexSettingsURL: URL {
        rootDirectory.appendingPathComponent(".codex/config.toml")
    }

    private func mergeClaudeSettings() throws {
        var settings = try jsonObject(at: claudeSettingsURL)
        try backupIfPresent(claudeSettingsURL)
        settings["statusLine"] = [
            "type": "command",
            "command": "\(bridgeURL.path) claude"
        ]
        try write(settings, to: claudeSettingsURL)
    }

    private func mergeCursorSettings() throws {
        var settings = try jsonObject(at: cursorSettingsURL)
        try backupIfPresent(cursorSettingsURL)
        settings["version"] = settings["version"] ?? 1
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        let command = [["command": "\(bridgeURL.path) cursor"]]
        hooks["sessionStart"] = command
        hooks["sessionEnd"] = command
        hooks["postToolUse"] = command
        settings["hooks"] = hooks
        try write(settings, to: cursorSettingsURL)
    }

    private func mergeCodexSettings() throws {
        try fileManager.createDirectory(at: codexSettingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let marker = "# TokenBar experimental bridge"
        let existing = (try? String(contentsOf: codexSettingsURL, encoding: .utf8)) ?? ""
        guard !existing.contains(marker) else { return }
        try backupIfPresent(codexSettingsURL)
        let addition = "\n\(marker)\nnotify = [\"\(bridgeURL.path)\", \"codex\"]\n"
        try Data((existing + addition).utf8).write(to: codexSettingsURL, options: .atomic)
    }

    private func jsonObject(at url: URL) throws -> [String: Any] {
        guard fileManager.fileExists(atPath: url.path) else { return [:] }
        return try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] ?? [:]
    }

    private func write(_ object: [String: Any], to url: URL) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: .atomic)
    }

    private func backupIfPresent(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        let backup = URL(fileURLWithPath: url.path + ".tokenbar-backup")
        if fileManager.fileExists(atPath: backup.path) {
            try fileManager.removeItem(at: backup)
        }
        try fileManager.copyItem(at: url, to: backup)
    }

    private func restoreBackupIfPresent(for url: URL) throws {
        let backup = URL(fileURLWithPath: url.path + ".tokenbar-backup")
        guard fileManager.fileExists(atPath: backup.path) else { return }
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.moveItem(at: backup, to: url)
    }

    private static let bridgeScript = #"""
#!/usr/bin/python3
import datetime, hashlib, json, os, sys, urllib.request

provider = sys.argv[1] if len(sys.argv) > 1 else "unknown"
raw = sys.stdin.read() or (sys.argv[2] if len(sys.argv) > 2 else "{}")
try:
    source = json.loads(raw)
except Exception:
    source = {}
session = str(source.get("session_id") or source.get("conversation_id") or source.get("sessionId") or "unknown")
project = source.get("cwd") or source.get("workspace", {}).get("current_dir") or (source.get("workspace_roots") or [""])[0]
usage = source.get("context_window", {}).get("current_usage", source.get("usage", {}))
stamp = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")
event = {
    "event_id": hashlib.sha256((provider + session + stamp + raw).encode()).hexdigest(),
    "provider": provider,
    "session_id": session,
    "project_path": project,
    "model": source.get("model", {}).get("id") if isinstance(source.get("model"), dict) else source.get("model"),
    "timestamp": stamp,
    "input_tokens": int(usage.get("input_tokens", 0) or 0),
    "output_tokens": int(usage.get("output_tokens", 0) or 0),
    "cached_tokens": int((usage.get("cache_read_input_tokens", 0) or 0) + (usage.get("cache_creation_input_tokens", 0) or 0)),
    "estimated": provider == "cursor",
}
data = json.dumps(event).encode()
try:
    request = urllib.request.Request("http://127.0.0.1:47831/events", data=data, headers={"Content-Type": "application/json"}, method="POST")
    urllib.request.urlopen(request, timeout=0.25).read()
except Exception:
    queue = os.path.expanduser("~/.tokenbar/events.jsonl")
    os.makedirs(os.path.dirname(queue), exist_ok=True)
    with open(queue, "a", encoding="utf-8") as handle:
        handle.write(json.dumps(event) + "\n")
"""#
}
