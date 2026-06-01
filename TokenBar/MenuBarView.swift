import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var viewModel: UsageViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Refreshing usage...")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(viewModel.summaries) { summary in
                    ProviderUsageRow(summary: summary)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            HStack {
                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                Button {
                    openSettings()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
            }
        }
        .padding()
        .frame(width: 380)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text("TokenBar")
                        .font(.headline)

                    Text("Today’s AI usage")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Local only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(viewModel.totalTokens.formatted()) total tokens")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
