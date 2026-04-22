import SwiftUI

struct CutSuggestionsList: View {
    @ObservedObject var vm: VideoRendererViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            muchRulePreamble
            VStack(spacing: 6) {
                ForEach(vm.cuts) { cut in
                    SuggestionRow(cut: cut) { vm.applyCut(cut) }
                }
            }
        }
        .padding(14)
        .cardStyle()
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "scissors.badge.ellipsis")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppModule.videoRenderer.tint)
            Text("CUT SUGGESTIONS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text("Rule of Six")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AppModule.videoRenderer.tint)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(AppModule.videoRenderer.tint.opacity(0.18))
                .clipShape(Capsule())
        }
    }

    private var muchRulePreamble: some View {
        HStack(spacing: 6) {
            ForEach(CutPriority.allCases, id: \.self) { p in
                HStack(spacing: 3) {
                    Circle().fill(p.tint).frame(width: 6, height: 6)
                    Text(p.weight)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 2)
    }
}

private struct SuggestionRow: View {
    let cut: CutSuggestion
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 2) {
                ZStack {
                    Circle().fill(cut.priority.tint.opacity(0.2))
                    Image(systemName: "scissors")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(cut.priority.tint)
                }
                .frame(width: 28, height: 28)
                Text("#\(cut.afterClipNumber)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(cut.priority.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(cut.priority.tint)
                    Text(cut.priority.weight)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                }
                Text(cut.rationale)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Button(action: onToggle) {
                Image(systemName: cut.applied ? "checkmark" : "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(cut.applied ? .black : cut.priority.tint)
                    .frame(width: 24, height: 24)
                    .background(cut.applied ? cut.priority.tint : cut.priority.tint.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plainSolid)
            .help(cut.applied ? "Applied" : "Apply suggestion")
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
