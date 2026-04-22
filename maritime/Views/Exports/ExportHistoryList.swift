import SwiftUI

struct ExportHistoryList: View {
    @ObservedObject var vm: ExportsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(vm.history) { job in
                        HistoryRow(job: job, onDelete: { vm.deleteJob(job) })
                    }
                }
                .padding(12)
            }
        }
        .background(Theme.bgElevated)
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppModule.exports.tint.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppModule.exports.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Export History")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(vm.history.count) jobs")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            Divider().background(Theme.stroke)
        }
    }
}

private struct HistoryRow: View {
    let job: ExportJob
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(job.format.tint.opacity(0.18))
                Image(systemName: job.format.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(job.format.tint)
            }
            .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(job.format.shortCode)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(job.format.tint)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(job.format.tint.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    Text(job.projectTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                }
                statusLine
            }
            Spacer(minLength: 4)
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var statusLine: some View {
        switch job.status {
        case .idle:
            Text("Queued")
                .font(.system(size: 9))
                .foregroundStyle(Theme.textTertiary)
        case .running(let progress):
            HStack(spacing: 4) {
                ProgressView(value: progress)
                    .tint(job.format.tint)
                    .frame(width: 80)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        case .done(let timestamp):
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.lime)
                Text(timestamp)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textTertiary)
            }
        case .failed(let reason):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.magenta)
                Text(reason)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.magenta)
                    .lineLimit(1)
            }
        }
    }
}
