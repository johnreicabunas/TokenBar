# TokenBar

TokenBar is a native macOS menu-bar app for local-only coding-agent token monitoring. It listens for live activity from Claude Code, Cursor, and Codex, then shows today's combined token total without uploading prompts, source code, or telemetry.

## Provider Support

| Provider | Status | Notes |
| --- | --- | --- |
| Claude Code | Supported | Uses status-line JSON for exact token values when available. |
| Cursor | Supported | Uses local hooks. Token values are labeled `Estimated` when Cursor does not expose exact accounting. |
| Codex | Experimental | Uses a local notify bridge. Compatibility depends on the installed Codex version while the upstream app-server surface remains experimental. |

## Privacy

TokenBar stores data under `~/.tokenbar/` on your Mac. It keeps provider name, opaque session ID, project name, model when available, timestamps, token totals, and estimation state. It does not persist prompts, transcript contents, source code, email addresses, or full project paths.

The local receiver listens on `127.0.0.1:47831`. When TokenBar is closed, bridge scripts append normalized events to `~/.tokenbar/events.jsonl` for recovery on the next launch.

## Requirements

- macOS with Xcode 26.5 or newer for the current project settings.
- Claude Code, Cursor, or Codex installed locally for the corresponding provider.

## Build

```bash
git clone https://github.com/johnreicabunas/TokenBar.git
cd TokenBar
swift test
xcodebuild -project TokenBar.xcodeproj -scheme TokenBar -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Open `TokenBar.xcodeproj` in Xcode to run the app locally.

## Setup

Open TokenBar settings and choose one of two paths:

- **Guided Setup:** review the exact local script and configuration changes, then install the bridges.
- **Manual Setup:** follow the displayed commands and configuration snippets yourself.

Guided setup creates backups before changing existing Claude Code and Cursor configuration. The settings screen also provides an uninstall-and-restore action.

## How It Works

1. Agent hooks invoke a TokenBar-owned bridge script.
2. The bridge sends a normalized JSON event to the localhost receiver.
3. If TokenBar is closed, the bridge writes the event to a local queue.
4. TokenBar drains queued events on launch and reconciles every 30 seconds.
5. The menu bar displays today's aggregate token total and provider-level details.

TokenBar intentionally starts counting from setup time. It does not scan or import older conversations.

## Tests

```bash
swift test
```

The test suite covers event validation, live-only filtering, duplicate handling, daily aggregation, project-name privacy, queue recovery, configuration merge safety, and backups.

## Contributing

Issues and pull requests are welcome. Keep provider-specific behavior behind adapters or normalized telemetry events, preserve the local-only privacy model, and add tests for changes to storage or setup behavior.

## License

MIT
