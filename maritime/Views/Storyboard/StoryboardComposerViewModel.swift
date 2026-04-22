import SwiftUI
import Combine

// MARK: - Storyboard Composer ViewModel
//
// Transient UI state only. Persistent data lives on the document.

enum StoryboardTab: String, CaseIterable, Identifiable, Hashable {
    case panels, rhythm, library

    var id: String { rawValue }

    var title: String {
        switch self {
        case .panels:  return "Panels"
        case .rhythm:  return "Pacing Check"
        case .library: return "Shot Reference"
        }
    }

    var subtitle: String {
        switch self {
        case .panels:  return "Compose and order your shots."
        case .rhythm:  return "Verify shot lengths before Scene Builder."
        case .library: return "Shot-type cheat sheet with film examples."
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

    private let project: MovieBlazeProject
    private var cancellables: Set<AnyCancellable> = []

    init(project: MovieBlazeProject) {
        self.project = project
        let seq = project.activeSequence
        selectedPanelID = seq?.panels.first?.id

        project.$activeSequenceID
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    let seq = self.project.activeSequence
                    self.selectedPanelID = seq?.panels.first?.id
                    self.focusedField = nil
                }
            }
            .store(in: &cancellables)

        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: Lookups

    var activeSequence: StoryboardSequence? { project.activeSequence }

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
        project.setActiveSequence(id)
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
        project.addPanel(panel)
        selectedPanelID = panel.id
    }

    func updatePanel(_ panel: StoryboardPanel) {
        project.updatePanel(panel)
    }

    func removeSelectedPanel() {
        guard let panel = selectedPanel else { return }
        let panels = activeSequence?.panels ?? []
        let nextIndex = (panels.firstIndex(where: { $0.id == panel.id }) ?? 0) - 1
        project.removePanel(id: panel.id)
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
        project.updatePanel(panel)
    }

    func reorderPanels(from sourceIndex: Int, to destinationIndex: Int) {
        project.reorderActivePanels(from: sourceIndex, to: destinationIndex)
    }

    // MARK: Promotion → Scene Builder

    @discardableResult
    func promoteSelectedPanelToSceneBuilder() -> (panel: StoryboardPanel, filmScene: FilmScene)? {
        guard let seq = activeSequence,
              let panel = selectedPanel,
              !panel.isPromoted else { return nil }
        let number = (project.scenes.map(\.number).max() ?? 0) + 1
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
        project.addFilmScene(filmScene)
        project.markPanelPromoted(panelID: panel.id, filmSceneID: filmScene.id)
        return (panel, filmScene)
    }
}
