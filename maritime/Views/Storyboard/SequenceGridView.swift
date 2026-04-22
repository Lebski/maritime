import SwiftUI

struct SequenceGridView: View {
    @ObservedObject var vm: StoryboardViewModel

    private let columns = [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 14)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(vm.panels) { panel in
                PanelTile(panel: panel,
                          isActive: vm.selectedPanelID == panel.id,
                          onTap: { vm.setActive(panel) },
                          onToggleKey: { vm.toggleKey(panel) },
                          onDelete: { vm.removePanel(panel) })
            }
            addCard
        }
    }

    private var addCard: some View {
        Button(action: { vm.addPanel(for: .medium) }) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppModule.storyboard.tint)
                Text("Add Panel")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color.white.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppModule.storyboard.tint.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct PanelTile: View {
    let panel: StoryboardPanel
    let isActive: Bool
    let onTap: () -> Void
    let onToggleKey: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                thumbnail
                meta
            }
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isActive ? AppModule.storyboard.tint : Theme.stroke,
                            lineWidth: isActive ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: panel.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("#\(panel.number)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                    Spacer()
                    HStack(spacing: 4) {
                        Button(action: onToggleKey) {
                            Image(systemName: panel.isKey ? "star.fill" : "star")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(panel.isKey ? Theme.accent : .white.opacity(0.8))
                                .padding(5)
                                .background(.black.opacity(0.45))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        Button(action: onDelete) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(5)
                                .background(.black.opacity(0.45))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                Spacer()
                HStack {
                    Text(panel.shot.shortLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(AppModule.storyboard.tint.opacity(0.85))
                        .clipShape(Capsule())
                    Spacer()
                    Text(String(format: "%.1fs", panel.duration))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                }
                .padding(8)
            }
            Image(systemName: panel.shot.icon)
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 120)
    }

    private var meta: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(panel.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Text(panel.description)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
    }
}
