import SwiftUI
import AppKit

/// Preferences → Debug. Shows every AI request the app has made, with the
/// full request and response bodies (image data redacted), token usage, and
/// duration. Persisted across launches by `AIRequestLog`.
struct DebugPane: View {

    @ObservedObject private var log = AIRequestLog.shared
    @State private var filter: ProviderFilter = .all
    @State private var selectedID: UUID?

    enum ProviderFilter: String, CaseIterable, Identifiable {
        case all, anthropic, fal
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all:       return "All"
            case .anthropic: return "Anthropic"
            case .fal:       return "fal.ai"
            }
        }
        func includes(_ provider: AIRequestLog.Provider) -> Bool {
            switch self {
            case .all:       return true
            case .anthropic: return provider == .anthropic
            case .fal:       return provider == .fal || provider == .recraft
            }
        }
    }

    private var filteredEntries: [AIRequestLog.Entry] {
        log.entries.filter { filter.includes($0.provider) }
    }

    private var selectedEntry: AIRequestLog.Entry? {
        guard let id = selectedID else { return filteredEntries.first }
        return filteredEntries.first(where: { $0.id == id }) ?? filteredEntries.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if filteredEntries.isEmpty {
                emptyState
            } else {
                HStack(alignment: .top, spacing: 14) {
                    listColumn
                        .frame(width: 280)
                    detailColumn
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            ForEach(ProviderFilter.allCases) { option in
                filterChip(option)
            }
            Spacer()
            Text("\(log.entries.count) total")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
            Button(action: clear) {
                HStack(spacing: 4) {
                    Image(systemName: "trash").font(.system(size: 10))
                    Text("Clear").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            .disabled(log.entries.isEmpty)
        }
    }

    private func filterChip(_ option: ProviderFilter) -> some View {
        let selected = filter == option
        return Button(action: { filter = option }) {
            Text(option.label)
                .font(.system(size: 12, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Theme.teal.opacity(0.18) : Color.white.opacity(0.04))
                .overlay(
                    Capsule().stroke(selected ? Theme.teal.opacity(0.5) : Theme.stroke, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plainSolid)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "ladybug")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.teal)
                    .padding(.top, 1)
                Text("No AI requests yet. Run a generation to see it here.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(10)
            .background(Theme.teal.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.teal.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: List

    private var listColumn: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(filteredEntries) { entry in
                    listRow(entry)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func listRow(_ entry: AIRequestLog.Entry) -> some View {
        let isSelected = (selectedEntry?.id == entry.id)
        return Button(action: { selectedID = entry.id }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    statusIcon(for: entry.status)
                    providerChip(entry.provider)
                    Spacer()
                    Text(relativeTime(entry.startedAt))
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
                Text(entry.label ?? entry.model)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.model)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                    if let ms = entry.durationMs {
                        Text("· \(formatDuration(ms))")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                if let summary = entry.responseSummary {
                    Text(summary)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                } else if let error = entry.errorMessage {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.coral)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(isSelected ? Theme.teal.opacity(0.10) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Theme.teal.opacity(0.5) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    @ViewBuilder
    private func statusIcon(for status: AIRequestLog.Status) -> some View {
        switch status {
        case .pending:
            ProgressView().scaleEffect(0.5).frame(width: 12, height: 12)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.teal)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.coral)
        }
    }

    private func providerChip(_ provider: AIRequestLog.Provider) -> some View {
        let tint = providerTint(provider)
        return Text(provider.displayName)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.15))
            .clipShape(Capsule())
    }

    private func providerTint(_ provider: AIRequestLog.Provider) -> Color {
        switch provider {
        case .anthropic: return Theme.magenta
        case .fal:       return Theme.coral
        case .recraft:   return Theme.violet
        }
    }

    // MARK: Detail

    @ViewBuilder
    private var detailColumn: some View {
        if let entry = selectedEntry {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    detailHeader(entry)
                    if let tokens = entry.tokens {
                        tokenRow(tokens)
                    }
                    bodyBlock(title: "Request",
                              text: entry.requestBody)
                    if let response = entry.responseBody {
                        bodyBlock(title: "Response", text: response)
                    }
                    if let error = entry.errorMessage {
                        bodyBlock(title: "Error", text: error, tint: Theme.coral)
                    }
                }
                .padding(.trailing, 4)
            }
        } else {
            EmptyView()
        }
    }

    private func detailHeader(_ entry: AIRequestLog.Entry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                providerChip(entry.provider)
                Text(entry.label ?? entry.model)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                statusIcon(for: entry.status)
            }
            Text(entry.endpoint)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
                .textSelection(.enabled)
            HStack(spacing: 12) {
                metaItem(label: "model", value: entry.model)
                metaItem(label: "started", value: absoluteTime(entry.startedAt))
                if let ms = entry.durationMs {
                    metaItem(label: "duration", value: formatDuration(ms))
                }
            }
            if let summary = entry.responseSummary {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func metaItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func tokenRow(_ tokens: AIRequestLog.TokenUsage) -> some View {
        HStack(spacing: 14) {
            tokenItem("input", tokens.input)
            tokenItem("output", tokens.output)
            tokenItem("cache read", tokens.cacheRead)
            tokenItem("cache write", tokens.cacheWrite)
        }
        .padding(10)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func tokenItem(_ label: String, _ value: Int?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            Text(value.map { formatNumber($0) } ?? "—")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func bodyBlock(title: String, text: String, tint: Color = Theme.textSecondary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Button(action: { copyToClipboard(text) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc").font(.system(size: 9))
                        Text("Copy").font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
            }
            ScrollView {
                Text(text)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(10)
            }
            .frame(maxHeight: 320)
            .background(Theme.bg)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: Actions

    private func clear() {
        log.clear()
        selectedID = nil
    }

    private func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    // MARK: Formatting

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func absoluteTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDuration(_ ms: Int) -> String {
        if ms < 1000 { return "\(ms) ms" }
        let seconds = Double(ms) / 1000.0
        return String(format: "%.1fs", seconds)
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
