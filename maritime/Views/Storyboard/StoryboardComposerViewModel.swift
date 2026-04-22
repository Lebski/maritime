import SwiftUI
import Combine

// MARK: - Storyboard Composer ViewModel
//
// Transient UI state only. Persistent data lives in StoryboardStore.

enum StoryboardTab: String, CaseIterable, Identifiable, Hashable {
    case panels, rhythm, library

    var id: String { rawValue }

    var title: String {
        switch self {
        case .panels:  return "Panels"
        case .rhythm:  return "Rhythm & Timing"
        case .library: return "Shot Library"
        }
    }

    var icon: String {
        switch self {
        case .panels:  return "square.grid.3x2.fill"
        case .rhythm:  return "waveform.path"
        case .library: return "film.stack.fill"
        }
    }
}

enum PanelField: String, Hashable {
    case action, dialogue, duration, shotType, movement, priority, characters
}

@MainActor
final class StoryboardComposerViewModel: ObservableObject {
    @Published var activeTab: StoryboardTab = .panels
    @Published var selectedPanelID: UUID?
    @Published var focusedField: PanelField?
    @Published var showNewPanelSheet = false

    private let store = StoryboardStore.shared
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let seq = store.activeSequence
        selectedPanelID = seq?.panels.first?.id

        store.$activeSequenceID
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    let seq = self.store.activeSequence
                    self.selectedPanelID = seq?.panels.first?.id
                    self.focusedField = nil
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Lookups

    var activeSequence: StoryboardSequence? { store.activeSequence }

    var selectedPanel: StoryboardPanel? {
        guard let id = selectedPanelID else { return nil }
        return activeSequence?.panels.first(where: { $0.id == id })
    }

    var selectedPanelIndex: Int? {
        guard let id = selectedPanelID,
              let panels = activeSequence?.panels else { return nil }
        return panels.firstIndex(where: { $0.id == id })
    }

    // MARK: Tabs + selection

    func selectTab(_ tab: StoryboardTab) {
        activeTab = tab
        focusedField = nil
    }

    func selectPanel(_ id: UUID) {
        selectedPanelID = id
        focusedField = nil
        if activeTab == .library { activeTab = .panels }
    }

    func setActiveSequence(_ id: UUID) {
        store.setActive(id)
    }

    // MARK: Panel CRUD

    func addPanel(shotType: CameraShotType) {
        guard let seq = activeSequence else { return }
        let base = seq.panels.last
        let panel = StoryboardPanel(
            number: seq.panels.count + 1,
            shotType: shotType,
            cameraMovement: .static,
            duration: 2.5,
            actionNote: "",
            timeOfDay: base?.timeOfDay ?? .day,
            editingPriority: .emotion,
            thumbnailSymbol: base?.thumbnailSymbol ?? "square.grid.3x2",
            thumbnailColors: base?.thumbnailColors ?? seq.posterColors
        )
        store.addPanel(panel)
        selectedPanelID = panel.id
    }

    func updatePanel(_ panel: StoryboardPanel) {
        store.updatePanel(panel)
    }

    func removeSelectedPanel() {
        guard let panel = selectedPanel else { return }
        let panels = activeSequence?.panels ?? []
        let nextIndex = (panels.firstIndex(where: { $0.id == panel.id }) ?? 0) - 1
        store.removePanel(id: panel.id)
        let updated = activeSequence?.panels ?? []
        if updated.isEmpty {
            selectedPanelID = nil
        } else {
            selectedPanelID = updated[max(0, min(nextIndex, updated.count - 1))].id
        }
    }

    func applyShotType(_ type: CameraShotType) {
        guard var panel = selectedPanel else { return }
        panel.shotType = type
        store.updatePanel(panel)
    }

    func reorderPanels(from sourceIndex: Int, to destinationIndex: Int) {
        store.reorderActivePanels(from: sourceIndex, to: destinationIndex)
    }

    // MARK: Promotion → Scene Builder

    func promoteSelectedPanelToSceneBuilder() {
        guard let seq = activeSequence,
              let panel = selectedPanel,
              !panel.isPromoted else { return }
        let number = (SceneStore.shared.scenes.map(\.number).max() ?? 0) + 1
        let filmScene = FilmScene(
            number: number,
            title: "\(seq.projectTitle) · Panel \(panel.number)",
            location: seq.title,
            isInterior: true,
            timeOfDay: panel.timeOfDay,
            lightingMood: .neutral,
            keyLight: .frontal,
            shotType: panel.shotType,
            background: nil,
            props: [],
            characters: [],
            activeGuides: [.ruleOfThirds],
            frameApproved: false,
            projectTitle: seq.projectTitle
        )
        SceneStore.shared.add(filmScene)
        store.markPanelPromoted(panelID: panel.id, filmSceneID: filmScene.id)
    }
}
