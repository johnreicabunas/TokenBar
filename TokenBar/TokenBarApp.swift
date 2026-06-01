import SwiftUI

@main
struct TokenBarApp: App {
    @StateObject private var viewModel = UsageViewModel()

    init() {
        TelemetryService.shared.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(viewModel)
                .task {
                    viewModel.startMonitoring()
                    await viewModel.refresh()
                }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.circle.fill")
                Text(viewModel.menuBarTitle)
            }
        }
        .menuBarExtraStyle(.window)

        Window("TokenBar Setup", id: "setup") {
            SettingsView()
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)
    }
}
