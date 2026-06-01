# TokenBar Local Agent Telemetry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace TokenBar's manual sample values with local-only live telemetry for Claude Code, Cursor, and experimental Codex monitoring, then prepare the repository for an open-source GitHub release.

**Architecture:** Keep provider integrations behind normalized `TelemetryEvent` payloads received by a localhost-only server or queue file. Persist idempotent live-only events in application support, aggregate them into provider summaries for SwiftUI, and install reversible TokenBar-owned bridge scripts through a previewable setup screen.

**Tech Stack:** Swift 6, SwiftUI, Foundation, Network framework, XCTest through Swift Package Manager, JSON configuration files, POSIX shell bridge scripts.

---

### Task 1: Add A Testable Telemetry Core

**Files:**
- Create: `Package.swift`
- Create: `TokenBar/TelemetryEvent.swift`
- Create: `TokenBar/DailyUsageStore.swift`
- Create: `Tests/TokenBarCoreTests/TelemetryEventTests.swift`
- Create: `Tests/TokenBarCoreTests/DailyUsageStoreTests.swift`

- [ ] Add a Swift package test harness that compiles the non-UI core files from `TokenBar`.
- [ ] Write failing tests for payload decoding, invalid payload rejection, duplicate IDs, live-only installation filtering, daily aggregation, estimated state, and project-name-only storage.
- [ ] Run `swift test` and confirm the new tests fail before implementation.
- [ ] Implement `TelemetryEvent`, provider models, validation, and `DailyUsageStore`.
- [ ] Run `swift test` and confirm the telemetry-core tests pass.

### Task 2: Add Queue Recovery And A Local Receiver

**Files:**
- Create: `TokenBar/TelemetryQueue.swift`
- Create: `TokenBar/LocalTelemetryServer.swift`
- Create: `Tests/TokenBarCoreTests/TelemetryQueueTests.swift`
- Modify: `Package.swift`

- [ ] Write failing tests for queue append, drain, malformed-line recovery, and idempotent persistence after replay.
- [ ] Run `swift test` and confirm the queue tests fail before implementation.
- [ ] Implement the newline-delimited JSON queue and a localhost-only HTTP receiver with a bounded request body.
- [ ] Run `swift test` and confirm queue and telemetry-core tests pass.

### Task 3: Add Reversible Agent Setup

**Files:**
- Create: `TokenBar/SetupManager.swift`
- Create: `Tests/TokenBarCoreTests/SetupManagerTests.swift`
- Modify: `Package.swift`

- [ ] Write failing tests for generated bridge scripts, Claude Code configuration merge, Cursor configuration merge, backup creation, uninstall, and restore.
- [ ] Run `swift test` and confirm the setup tests fail before implementation.
- [ ] Implement preview, install, verification, uninstall, restore, and manual instructions.
- [ ] Configure Claude Code status-line forwarding, Cursor hooks, and an experimental Codex notify bridge without overwriting unrelated settings.
- [ ] Run `swift test` and confirm all package tests pass.

### Task 4: Replace Manual Values With Live Usage

**Files:**
- Modify: `TokenBar/UsageSummary.swift`
- Modify: `TokenBar/UsageProvider.swift`
- Modify: `TokenBar/LocalUsageProvider.swift`
- Modify: `TokenBar/UsageViewModel.swift`
- Modify: `TokenBar/TokenBarApp.swift`
- Modify: `TokenBar/MenuBarView.swift`
- Modify: `TokenBar/ProviderUsageRow.swift`
- Modify: `TokenBar/SettingsView.swift`

- [ ] Replace price-based sample models with provider status, project names, exact-versus-estimated state, and daily token values.
- [ ] Start the receiver with the app and refresh immediately after accepted events.
- [ ] Add the 30-second queue-drain and reconciliation refresh.
- [ ] Replace manual settings with guided setup preview, install, restore, uninstall, verification, and manual-instruction tabs.
- [ ] Run `swift test` and `xcodebuild -project TokenBar.xcodeproj -scheme TokenBar -configuration Debug build`.

### Task 5: Prepare The Public Repository

**Files:**
- Create: `.gitignore`
- Create: `LICENSE`
- Create: `README.md`
- Remove from index: `TokenBar.xcodeproj/xcuserdata/johnreicabunas.xcuserdatad/xcschemes/xcschememanagement.plist`

- [ ] Add Xcode, macOS, SwiftPM, and local-data exclusions.
- [ ] Add the MIT license.
- [ ] Document privacy, provider support levels, build steps, guided setup, manual setup, and contribution notes.
- [ ] Remove the tracked Xcode user-specific scheme metadata from the repository index.
- [ ] Run a repository scan for secrets, local user paths, and tracked ignored files.

### Task 6: Verify The Release Candidate

**Files:**
- Modify only files required by verification fixes.

- [ ] Run `swift test`.
- [ ] Run `xcodebuild -project TokenBar.xcodeproj -scheme TokenBar -configuration Debug build CODE_SIGNING_ALLOWED=NO`.
- [ ] Run `git status --short --ignored` and confirm only intentional source changes remain.
- [ ] Confirm `git check-ignore` covers Xcode user data, `.DS_Store`, `.build`, and local TokenBar telemetry files.
- [ ] Summarize the remaining GitHub repository creation decision before pushing.
