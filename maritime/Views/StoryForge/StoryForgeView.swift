import SwiftUI

struct StoryForgeView: View {
    @StateObject private var vm = StoryForgeViewModel()

    var body: some View {
        HStack(spacing: 0) {
            CollapsiblePane(
                isCollapsed: $vm.leftCollapsed,
                edge: .leading,
                expandedWidth: 300,
                tint: AppModule.storyForge.tint,
                icon: AppModule.storyForge.icon,
                label: "Beats",
                shortcut: "["
            ) {
                BeatSheetView(vm: vm).background(Theme.bgElevated)
            }
            Divider().background(Theme.stroke)
            middleEditor
            Divider().background(Theme.stroke)
            CollapsiblePane(
                isCollapsed: $vm.rightCollapsed,
                edge: .trailing,
                expandedWidth: 300,
                tint: AppModule.storyForge.tint,
                icon: "sparkles",
                label: "Theme",
                shortcut: "]"
            ) {
                ThemeMotifRail(vm: vm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }

    private var middleEditor: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    loglineCard
                    if let beat = vm.selectedBeat {
                        beatEditor(beat: beat)
                    }
                    WantVsNeedPanel(vm: vm)
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppModule.storyForge.tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: AppModule.storyForge.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppModule.storyForge.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.projectTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: vm.template.icon)
                        .font(.system(size: 10))
                    Text(vm.template.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button(action: {}) {
                Label("Send to Storyboard", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(AppModule.storyForge.tint)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    private var loglineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppModule.storyForge.tint)
                Text("LOGLINE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            TextField("A one-sentence premise…", text: $vm.logline, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2...4)
        }
        .padding(16)
        .cardStyle()
    }

    @ViewBuilder
    private func beatEditor(beat: Beat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppModule.storyForge.tint.opacity(0.2))
                        .frame(width: 34, height: 34)
                    Text("\(Int(beat.pct * 100))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppModule.storyForge.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(beat.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(beat.summary)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Button(action: { vm.toggleDone(beat) }) {
                    HStack(spacing: 4) {
                        Image(systemName: beat.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 11))
                        Text(beat.isDone ? "Done" : "Mark done")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(beat.isDone ? Theme.lime : Theme.textSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background((beat.isDone ? Theme.lime : Color.white).opacity(beat.isDone ? 0.15 : 0.05))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppModule.storyForge.tint)
                    Text("SCENE NOTES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.textSecondary)
                }
                TextEditor(text: Binding(
                    get: { beat.notes },
                    set: { vm.updateSelectedNotes($0) }
                ))
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(10)
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .cardStyle()
    }
}
