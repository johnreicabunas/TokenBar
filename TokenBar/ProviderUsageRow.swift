import SwiftUI

struct ProviderUsageRow: View {
    let summary: UsageSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(summary.provider.displayName, systemImage: summary.provider.iconName)
                    .font(.subheadline)
                    .bold()

                Spacer()

                Text(summary.connectionStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("\(summary.totalTokens.formatted()) tokens")
                    .font(.headline)

                Spacer()

                Text(summary.isEstimated ? "Estimated" : "Exact")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                metric(title: "Input", value: summary.inputTokens)
                metric(title: "Output", value: summary.outputTokens)
                metric(title: "Cached", value: summary.cachedTokens)
            }

            ProgressView(value: min(Double(summary.totalTokens) / 100_000.0, 1.0))

            if !summary.projectNames.isEmpty {
                Text(summary.projectNames.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metric(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value.formatted())
                .font(.caption)
        }
    }
}
