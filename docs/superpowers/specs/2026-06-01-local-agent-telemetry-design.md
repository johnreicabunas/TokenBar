# TokenBar Local Agent Telemetry Design

## Purpose

TokenBar is a native macOS menu-bar app for monitoring local coding-agent token activity. The first public release replaces manual sample values with live telemetry from Codex, Claude Code, and Cursor while keeping all collected data on the user's Mac.

The app is intentionally local-only. It has no account system, backend, cloud sync, hosted pricing service, or anonymous analytics.

## Scope

The first release will:

- Monitor Codex, Claude Code, and Cursor activity from the moment TokenBar setup is completed.
- Update near real time when agent hooks or event streams publish telemetry.
- Reconcile queued or missed events every 30 seconds.
- Display today's combined token total in the menu bar.
- Display provider-level token totals, active project names, connection states, and estimation state in the popover.
- Provide guided setup with a preview and confirmation step.
- Provide equivalent manual setup instructions.
- Prepare the repository for a public GitHub release with an MIT license, README, screenshots, privacy notes, build instructions, contribution guidance, and basic tests.

The first release will not:

- Import historical agent sessions.
- Read prompts, transcript contents, source code, email addresses, or full project paths into TokenBar storage.
- Display or estimate monetary cost.
- Upload telemetry or configuration to a remote service.
- Ship a signed or notarized downloadable macOS release.

## Architecture

TokenBar remains a self-contained native macOS application. It adds a localhost-only receiver, provider adapters, a local daily store, and setup management.

### Core Components

`LocalTelemetryServer`

- Binds to `127.0.0.1` only.
- Receives small JSON event payloads from TokenBar-owned hook scripts.
- Rejects oversized or malformed requests.
- Passes accepted payloads through normalization before persistence.

`TelemetryEvent`

- Normalizes provider-specific payloads into one model.
- Includes provider, opaque session ID, stable event ID, project name, model when available, timestamp, token values, activity state, and whether values are estimated.
- Excludes prompts, transcript contents, source code, email addresses, and full project paths.

`ClaudeCodeAdapter`

- Receives Claude Code status-line updates through a TokenBar-owned script.
- Treats Claude Code token values as exact when the status-line payload includes them.
- Maps session, project, model, input, output, and cached-token values into `TelemetryEvent`.

`CursorAdapter`

- Receives Cursor hook updates through a TokenBar-owned script.
- Tracks live activity, session, model, and project information.
- Marks derived token totals as estimated whenever Cursor does not expose exact token values.

`CodexAdapter`

- Consumes supported local Codex events and token-usage updates.
- Performs periodic reconciliation to recover missed updates.
- Is labeled experimental until verified against the locally installed Codex version because the upstream app-server integration surface is experimental.

`DailyUsageStore`

- Persists normalized events and today's aggregate totals locally.
- Ignores duplicate events by stable event ID.
- Applies an installation timestamp boundary so sessions from before setup are never imported.
- Supports queue draining after app launch or missed receiver delivery.

`SetupManager`

- Previews all configuration and script changes before applying them.
- Installs TokenBar-owned scripts under the user's application-support directory.
- Merges Claude Code and Cursor configuration while preserving unrelated settings.
- Creates backups before modifying existing configuration.
- Provides verification, uninstall, and restore actions.

`UsageViewModel`

- Publishes today's combined totals, provider summaries, project names, estimation state, and adapter status to SwiftUI.
- Refreshes immediately after accepted telemetry events.
- Reconciles queued events and provider state every 30 seconds.

## Data Flow

1. The user completes guided or manual setup.
2. TokenBar records the installation timestamp that defines the live-only telemetry boundary.
3. Claude Code status-line updates and Cursor hooks invoke TokenBar-owned scripts.
4. Scripts normalize the minimum required event envelope and submit it to TokenBar's `127.0.0.1` receiver.
5. If TokenBar is closed or unreachable, scripts append the event to a TokenBar-owned queue file.
6. Codex events are consumed through the supported local Codex integration surface and reconciled periodically.
7. `DailyUsageStore` validates the installation boundary, ignores duplicate IDs, persists accepted events, and updates daily totals.
8. `UsageViewModel` publishes fresh totals to the menu-bar label and popover.
9. On launch and every 30 seconds, TokenBar drains the queue and reconciles provider state.

## User Experience

### First Launch Setup

The setup panel contains two tabs.

`Guided Setup`

- Explains that telemetry remains local.
- Shows the exact scripts and configuration changes TokenBar plans to apply.
- Requests explicit confirmation.
- Applies changes, verifies each adapter, and reports provider-specific status.

`Manual Setup`

- Shows the same scripts and configuration snippets.
- Provides step-by-step installation and verification instructions.
- Supports users who prefer to manage their own configuration files.

### Menu-Bar Popover

The menu-bar label displays today's combined token total across Codex, Claude Code, and Cursor.

The popover displays:

- Today's combined token total.
- One row for each provider.
- Input, output, and cached-token values when available.
- An `Estimated` badge for Cursor values that are not exact.
- Active project names only.
- Provider-specific connection state.
- Refresh, Setup, and Quit actions.

The existing manual token-entry controls, sample values, and pricing controls are removed.

## Privacy And Security

- The receiver binds only to `127.0.0.1`.
- Receiver payload size is bounded.
- Malformed and unsupported events are rejected before persistence.
- Storage contains only provider, opaque session ID, stable event ID, project name, model when available, timestamps, token totals, activity state, and estimation state.
- Full local paths may be used transiently to derive a project name but are never persisted or displayed.
- Prompts, transcript contents, source code, and email addresses are never persisted.
- Setup changes are previewed, backed up, reversible, and limited to TokenBar-owned configuration additions.

## Failure Handling

- Hook scripts queue events locally when the app is unavailable.
- Duplicate events are harmless because persistence is idempotent by stable event ID.
- One adapter failure does not prevent other providers from updating.
- Provider rows display independent connection states.
- Missing Cursor token accounting produces explicitly estimated values, not silent substitution.
- Unsupported or changed upstream payloads produce a provider-specific degraded state and a useful setup verification message.
- Codex remains visibly experimental until local compatibility verification passes.

## Testing

The first release includes focused tests for:

- Telemetry payload decoding and validation.
- Payload-size rejection and malformed-event rejection.
- Daily aggregation and stable-ID duplicate handling.
- Installation-timestamp filtering for live-only monitoring.
- Queue-file draining and recovery after relaunch.
- Configuration merging that preserves unrelated Claude Code and Cursor settings.
- Backup creation, uninstall, and restore behavior.
- Exact-versus-estimated provider state.
- Project-name extraction without stored full paths.
- View-model refresh after accepted events and periodic reconciliation.

## Public GitHub Release

Before publishing, the repository will include:

- An MIT license.
- An Xcode and macOS `.gitignore`.
- Removal of tracked Xcode user-specific files from the public repository index.
- A README with screenshots, privacy notes, supported-provider caveats, requirements, build instructions, guided setup, manual setup, and contribution guidance.
- No secrets, user data, local paths, or Xcode user-specific files.

The initial public release will publish source code and documentation only. Signing, notarization, and downloadable app bundles are deferred.

## Implementation Notes

- Provider-specific integrations must remain isolated behind adapters so upstream changes do not spread through the UI or persistence layer.
- TokenBar must prefer supported integration points. It must not depend on undocumented transcript scraping when a provider exposes hooks or structured events.
- Cursor token totals must remain visibly estimated unless an exact supported telemetry field is available.
- The implementation plan should split public-release preparation from runtime telemetry work into independently verifiable tasks while delivering one cohesive first release.
