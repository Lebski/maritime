import SwiftUI
import UniformTypeIdentifiers

// MARK: - Storyboard Panels Grid View
//
// Top: 3-column LazyVGrid of StoryboardPanelCards, with drag-to-reorder.
// Bottom: PanelDetailEditor for the currently selected panel.

struct StoryboardPanelsGridView: View {
    @ObservedObject var vm: StoryboardComposerViewModel
    @EnvironmentObject var navigator: AppNavigator

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                gridSection
                Divider().background(Theme.stroke)
                PanelDetailEditor(vm: vm)
            }
            .padding(24)
        }
    }

    // MARK: Grid

    @ViewBuilder
    private var gridSection: some View {
        let panels = vm.panels
        if panels.isEmpty {
            emptySequenceState
        } else {
            gridHeader(panels)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(panels.enumerated()), id: \.element.id) { idx, panel in
                    StoryboardPanelCard(
                        panel: panel,
                        isSelected: vm.selectedPanelID == panel.id,
                        onTap: { vm.selectPanel(panel.id) },
                        onReturnToScene: panel.promotedFilmSceneID.map { sceneID in
                            { navigator.openSceneBuilder(sceneID: sceneID) }
                        }
                    )
                    .draggable(PanelDragPayload(panelID: panel.id, fromIndex: idx)) {
                        StoryboardPanelCard(
                            panel: panel,
                            isSelected: true,
                            onTap: {}
                        )
                        .frame(width: 220)
                        .opacity(0.85)
                    }
                    .dropDestination(for: PanelDragPayload.self) { payloads, _ in
                        guard let payload = payloads.first else { return false }
                        vm.reorderPanels(from: payload.fromIndex, to: idx)
                        return true
                    }
                }
                addCard
            }
        }
    }

    private func gridHeader(_ panels: [StoryboardPanel]) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("PANELS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
                Text("\(panels.count) panels · \(panels.runtimeLabel) runtime")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button(action: { vm.showNewPanelSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add Panel")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Theme.violet)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var addCard: some View {
        Button(action: { vm.showNewPanelSheet = true }) {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.violet.opacity(0.7))
                Text("Add Panel")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16.0/9.0, contentMode: .fit)
            .background(Theme.card.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        Theme.violet.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Empty state

    private var emptySequenceState: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.grid.3x2")
                .font(.system(size: 34))
                .foregroundStyle(Theme.violet.opacity(0.6))
            Text("No panels yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Add your first panel — start with a wide to establish geography, then close in.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
            Button(action: { vm.showNewPanelSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Plan a sequence →")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Theme.violet)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(32)
        .background(Theme.card.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    Theme.violet.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Drag payload

struct PanelDragPayload: Codable, Transferable {
    let panelID: UUID
    let fromIndex: Int

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .storyboardPanel)
    }
}

extension UTType {
    static var storyboardPanel: UTType {
        UTType(exportedAs: "com.maritime.storyboard.panel")
    }
}
