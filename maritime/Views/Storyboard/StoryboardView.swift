import SwiftUI

struct StoryboardView: View {
    @StateObject private var vm = StoryboardViewModel()

    var body: some View {
        HStack(spacing: 0) {
            CollapsiblePane(
                isCollapsed: $vm.libraryCollapsed,
                edge: .leading,
                expandedWidth: 280,
                tint: AppModule.storyboard.tint,
                icon: AppModule.storyboard.icon,
                label: "Library",
                shortcut: "["
            ) {
                ShotLibraryPanel(vm: vm)
            }
            Divider().background(Theme.stroke)
            workspace
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }

    private var workspace: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let panel = vm.selectedPanel {
                        panelEditor(panel: panel)
                    }
                    SequenceGridView(vm: vm)
                }
                .padding(24)
            }
            RhythmTimingBar(vm: vm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppModule.storyboard.tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: AppModule.storyboard.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppModule.storyboard.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(vm.sequenceName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(vm.projectTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
                Text("\(vm.panels.count) panels · \(String(format: "%.1fs", vm.totalDuration))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button(action: {}) {
                Label("Generate thumbnails", systemImage: "wand.and.stars")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button(action: {}) {
                Label("Send to Scene Builder", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(AppModule.storyboard.tint)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    @ViewBuilder
    private func panelEditor(panel: StoryboardPanel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppModule.storyboard.tint.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Text("#\(panel.number)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppModule.storyboard.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(panel.shot.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(panel.shot.shortLabel)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppModule.storyboard.tint)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(AppModule.storyboard.tint.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Text(panel.shot.description)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                durationStepper(panel: panel)
            }

            VStack(alignment: .leading, spacing: 6) {
                label("TITLE")
                TextField("Shot title…", text: Binding(
                    get: { panel.title },
                    set: { vm.updateTitle(panel, title: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(8)
                .background(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                label("DESCRIPTION")
                TextField("What happens in this shot?", text: Binding(
                    get: { panel.description },
                    set: { vm.updateDescription(panel, description: $0) }
                ), axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2...4)
                .padding(8)
                .background(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func durationStepper(panel: StoryboardPanel) -> some View {
        HStack(spacing: 4) {
            Button(action: { vm.updateDuration(panel, seconds: panel.duration - 0.5) }) {
                Image(systemName: "minus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Text(String(format: "%.1fs", panel.duration))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 46)
            Button(action: { vm.updateDuration(panel, seconds: panel.duration + 0.5) }) {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(Theme.textTertiary)
    }
}
