import SwiftUI

struct BeatSheetView: View {
    @ObservedObject var vm: StoryForgeViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(vm.beats) { beat in
                        BeatRowView(
                            beat: beat,
                            isActive: vm.selectedBeatID == beat.id,
                            tint: AppModule.storyForge.tint,
                            onTap: { vm.setActive(beat) },
                            onToggle: { vm.toggleDone(beat) }
                        )
                    }
                }
                .padding(14)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppModule.storyForge.tint.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: AppModule.storyForge.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppModule.storyForge.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Beat Sheet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(vm.beats.count) beats · \(Int(vm.completion * 100))%")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            ProgressView(value: vm.completion)
                .tint(AppModule.storyForge.tint)
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
            Divider().background(Theme.stroke)
        }
    }
}

private struct BeatRowView: View {
    let beat: Beat
    let isActive: Bool
    let tint: Color
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: onToggle) {
                    Image(systemName: beat.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(beat.isDone ? tint : Theme.textTertiary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(beat.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(Int(beat.pct * 100))%")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(tint.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Text(beat.summary)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .background(isActive ? tint.opacity(0.12) : Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? tint.opacity(0.5) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
