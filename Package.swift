// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TokenBarCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TokenBarCore", targets: ["TokenBarCore"])
    ],
    targets: [
        .target(
            name: "TokenBarCore",
            path: "TokenBar",
            exclude: [
                "Assets.xcassets",
                "ContentView.swift",
                "LocalTelemetryServer.swift",
                "LocalUsageProvider.swift",
                "MenuBarView.swift",
                "ProviderUsageRow.swift",
                "SettingsView.swift",
                "TelemetryService.swift",
                "TokenBarApp.swift",
                "UsageProvider.swift",
                "UsageSummary.swift",
                "UsageViewModel.swift"
            ],
            sources: [
                "TelemetryEvent.swift",
                "DailyUsageStore.swift",
                "TelemetryQueue.swift",
                "SetupManager.swift"
            ]
        ),
        .testTarget(
            name: "TokenBarCoreTests",
            dependencies: ["TokenBarCore"],
            path: "Tests/TokenBarCoreTests"
        )
    ]
)
