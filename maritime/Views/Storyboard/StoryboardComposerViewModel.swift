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
        selectedPanelID = project.storyboardPanels.first?.id

        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: Lookups

    var panels: [StoryboardPanel] { project.storyboardPanels }

    var selectedPanel: StoryboardPanel? {
        guard let id = selectedPanelID else { return nil }
        return panels.first(where: { $0.id == id })
    }

    var selectedPanelIndex: Int? {
        guard let id = selectedPanelID else { return nil }
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

    // MARK: Panel CRUD

    func addPanel(shotType: CameraShotType) {
        let base = panels.last
        let panel = StoryboardPanel(
            number: panels.count + 1,
            shotType: shotType,
            cameraMovement: .static,
            duration: 2.5,
            actionNote: "",
            timeOfDay: base?.timeOfDay ?? .day,
            editingPriority: .emotion,
            thumbnailSymbol: base?.thumbnailSymbol ?? "square.grid.3x2",
            thumbnailColors: base?.thumbnailColors ?? [Theme.violet, Theme.magenta],
            sceneBreakdownID: base?.sceneBreakdownID
        )
        project.addPanel(panel)
        selectedPanelID = panel.id
    }

    func updatePanel(_ panel: StoryboardPanel) {
        project.updatePanel(panel)
    }

    func removeSelectedPanel() {
        guard let panel = selectedPanel else { return }
        let nextIndex = (panels.firstIndex(where: { $0.id == panel.id }) ?? 0) - 1
        project.removePanel(id: panel.id)
        let updated = panels
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
        project.reorderPanels(from: sourceIndex, to: destinationIndex)
    }

    // MARK: Promotion → Scene Builder

    @discardableResult
    func promoteSelectedPanelToSceneBuilder() -> (panel: StoryboardPanel, filmScene: FilmScene)? {
        guard let panel = selectedPanel,
              !panel.isPromoted else { return nil }
        let number = (project.scenes.map(\.number).max() ?? 0) + 1
        let originScene = originSceneBreakdown(for: panel)
        let title = originScene.map { "Scene \($0.number) · Panel \(panel.number)" }
            ?? "Panel \(panel.number)"
        let location = originScene?.title ?? project.bible.projectTitle
        let filmScene = FilmScene(
            number: number,
            title: title,
            location: location,
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
            projectTitle: project.bible.projectTitle
        )
        project.addFilmScene(filmScene)
        project.markPanelPromoted(panelID: panel.id, filmSceneID: filmScene.id)
        return (panel, filmScene)
    }

    // MARK: Scene lookup

    func originSceneBreakdown(for panel: StoryboardPanel) -> SceneBreakdown? {
        guard let id = panel.sceneBreakdownID else { return nil }
        return project.bible.sceneBreakdowns.first(where: { $0.id == id })
    }
}
