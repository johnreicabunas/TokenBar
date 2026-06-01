import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: UsageViewModel
    @State private var selectedTab = 0
    @State private var message = SetupManager().status().message
    private let setupManager = SetupManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TokenBar Setup")
                .font(.title2.bold())
            Text("TokenBar keeps coding-agent telemetry on this Mac. Review every local configuration change before installing.")
                .foregroundStyle(.secondary)

            Picker("Setup mode", selection: $selectedTab) {
                Text("Guided Setup").tag(0)
                Text("Manual Setup").tag(1)
            }
            .pickerStyle(.segmented)

            ScrollView {
                Text(selectedTab == 0 ? setupManager.preview() : setupManager.manualInstructions())
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(10)
            .background(.quaternary.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Install Local Bridges") {
                    do {
                        try setupManager.install()
                        message = "Installed. Start an agent session to receive live telemetry."
                        Task { await viewModel.refresh() }
                    } catch {
                        message = error.localizedDescription
                    }
                }
                Button("Uninstall And Restore") {
                    do {
                        try setupManager.uninstall()
                        message = "Removed TokenBar bridge configuration and restored backups."
                    } catch {
                        message = error.localizedDescription
                    }
                }
                Spacer()
                Button("Refresh") {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .padding()
        .frame(width: 620, height: 560)
    }
}
