import SwiftUI
import UniformTypeIdentifiers

// MARK: - Storyboard Panels Grid View
//
// Top: panels grouped by scene (one section per scene with a Generate
// breakdown action), plus a trailing "manual" group for panels without an
// origin scene. Bottom: PanelDetailEditor for the selected panel.

struct StoryboardPanelsGridView: View {
    @ObservedObject var vm: StoryboardComposerViewModel
    @EnvironmentObject var navigator: AppNavigator
    @EnvironmentObject var project: MovieBlazeProject

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
        let plans = project.shotPlans
        if panels.isEmpty && plans.isEmpty {
            emptySequenceState
        } else {
            globalHeader(panels)
            ForEach(scenePlanGroups(plans: plans, panels: panels), id: \.id) { group in
                sceneSection(group: group)
            }
            let orphans = panels.filter { $0.sceneBreakdownID == nil }
            if !orphans.isEmpty {
                orphanSection(panels: orphans)
            }
        }
    }

    // MARK: Sections

    private func sceneSection(group: ScenePlanGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sceneHeader(group: group)
            if group.panels.isEmpty {
                emptyPlanCard(group: group)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(group.panels) { panel in
                        panelCard(panel: panel)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.card.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sceneHeader(group: ScenePlanGroup) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("SCENE \(group.scene.number)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
                Text(group.scene.title.isEmpty ? "Untitled scene" : group.scene.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(group.panels.count) shot\(group.panels.count == 1 ? "" : "s") · \(group.panels.runtimeLabel) runtime")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            statusPill(group.plan.status)
            generateButton(group: group)
        }
    }

    private func statusPill(_ status: AIBreakdownStatus) -> some View {
        let (label, tint, icon): (String, Color, String) = {
            switch status {
            case .empty:      return ("EMPTY",      Theme.textTertiary, "circle.dashed")
            case .generating: return ("GENERATING", Theme.accent,       "circle.dotted")
            case .ready:      return ("READY",      Theme.lime,         "checkmark.seal.fill")
            case .failed:     return ("FAILED",     Theme.coral,        "exclamationmark.triangle.fill")
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12))
        .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func generateButton(group: ScenePlanGroup) -> some View {
        let isReady = group.plan.status == .ready
        let isGenerating = group.plan.status == .generating
        Button(action: { triggerBreakdown(planID: group.plan.id) }) {
            HStack(spacing: 6) {
                if isGenerating {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.65)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(isGenerating ? "Generating…" : (isReady ? "Regenerate breakdown" : "Generate breakdown"))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isGenerating ? Theme.accent.opacity(0.6) : Theme.accent)
            .clipShape(Capsule())
        }
        .buttonStyle(.plainSolid)
        .disabled(isGenerating)
    }

    private func emptyPlanCard(group: ScenePlanGroup) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 22))
                .foregroundStyle(Theme.accent.opacity(0.7))
            Text(group.plan.status == .failed
                 ? (group.plan.lastError ?? "Generation failed.")
                 : "Click Generate breakdown to plan shots for this scene with AI.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(20)
        .background(Theme.card.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func orphanSection(panels: [StoryboardPanel]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MANUAL PANELS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.textTertiary)
                    Text("Panels without an origin scene")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                addPanelButton(label: "Add Panel")
            }
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(panels) { panel in panelCard(panel: panel) }
                addCard
            }
        }
        .padding(16)
        .background(Theme.card.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func panelCard(panel: StoryboardPanel) -> some View {
        let idx = vm.panels.firstIndex(where: { $0.id == panel.id }) ?? 0
        return StoryboardPanelCard(
            panel: panel,
            isSelected: vm.selectedPanelID == panel.id,
            onTap: { vm.selectPanel(panel.id) },
            onReturnToScene: panel.hasFrames
                ? { navigator.openFrameBuilder(panelID: panel.id) }
                : nil
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

    // MARK: Header / add buttons

    private func globalHeader(_ panels: [StoryboardPanel]) -> some View {
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
            addPanelButton(label: "Add Panel")
        }
    }

    private func addPanelButton(label: String) -> some View {
        Button(action: { vm.showNewPanelSheet = true }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Theme.violet)
            .clipShape(Capsule())
        }
        .buttonStyle(.plainSolid)
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
        .buttonStyle(.plainSolid)
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
            Text("Send a Story Forge scene over here, or add a manual panel to start a sequence.")
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
            .buttonStyle(.plainSolid)
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

    // MARK: Helpers

    private func triggerBreakdown(planID: UUID) {
        Task { await vm.generateBreakdown(forPlan: planID) }
    }

    private func scenePlanGroups(plans: [SceneShotPlan],
                                 panels: [StoryboardPanel]) -> [ScenePlanGroup] {
        plans.compactMap { plan in
            guard let scene = project.bible.sceneBreakdowns.first(where: { $0.id == plan.sceneBreakdownID }) else { return nil }
            let scenePanels = panels.filter { $0.sceneBreakdownID == plan.sceneBreakdownID }
            return ScenePlanGroup(plan: plan, scene: scene, panels: scenePanels)
        }
        .sorted { $0.scene.number < $1.scene.number }
    }
}

private struct ScenePlanGroup: Identifiable {
    var id: UUID { plan.id }
    let plan: SceneShotPlan
    let scene: SceneBreakdown
    let panels: [StoryboardPanel]
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
