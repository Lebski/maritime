import SwiftUI
import Combine

@MainActor
final class StoryForgeViewModel: ObservableObject {
    // Transient UI state only. Persistent story data lives on the document.

    @Published var activeSection: StoryForgeSection = .characters
    @Published var activeDraftID: UUID?
    @Published var focusedField: StoryCharacterField?
    @Published var selectedBeatID: UUID?
    @Published var expandedSceneID: UUID?
    @Published var focusedSceneField: SceneField?
    @Published var showNewCharacterSheet = false
    @Published var showNewSceneSheet = false
    @Published var showNewBibleSheet = false
    @Published var showAddMotifSheet = false

    enum SceneField: String {
        case goal, conflict, emotionalBeat, visualMetaphor, transition
    }

    private let project: MovieBlazeProject
    private var cancellables: Set<AnyCancellable> = []

    init(project: MovieBlazeProject) {
        self.project = project
        let bible = project.activeBible
        activeDraftID = bible?.characterDrafts.first?.id
        selectedBeatID = bible?.structure.beats.first?.id

        // When the active bible changes, refresh selections so we don't
        // hold onto IDs from a different bible.
        project.$activeBibleID
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    let b = self.project.activeBible
                    self.activeDraftID = b?.characterDrafts.first?.id
                    self.selectedBeatID = b?.structure.beats.first?.id
                    self.expandedSceneID = nil
                    self.focusedField = nil
                    self.focusedSceneField = nil
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Lookups

    var activeBible: StoryBible? { project.activeBible }

    var activeDraft: StoryCharacterDraft? {
        guard let id = activeDraftID else { return nil }
        return activeBible?.characterDrafts.first(where: { $0.id == id })
    }

    var selectedBeat: StoryBeat? {
        guard let id = selectedBeatID else { return nil }
        return activeBible?.structure.beats.first(where: { $0.id == id })
    }

    var expandedScene: SceneBreakdown? {
        guard let id = expandedSceneID else { return nil }
        return activeBible?.sceneBreakdowns.first(where: { $0.id == id })
    }

    // MARK: Section nav

    func selectSection(_ section: StoryForgeSection) {
        activeSection = section
        focusedField = nil
        focusedSceneField = nil
    }

    // MARK: Characters

    func selectDraft(_ id: UUID) {
        activeDraftID = id
        focusedField = nil
    }

    func updateDraftField(_ field: StoryCharacterField, value: String) {
        guard var draft = activeDraft else { return }
        draft.setValue(value, for: field)
        project.updateDraft(draft)
    }

    func updateDraftName(_ name: String) {
        guard var draft = activeDraft else { return }
        draft.name = name
        project.updateDraft(draft)
    }

    func updateDraftRole(_ role: String) {
        guard var draft = activeDraft else { return }
        draft.role = role
        project.updateDraft(draft)
    }

    func addCharacterDraft(name: String, role: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let draft = StoryCharacterDraft(
            name: trimmed.isEmpty ? "New Character" : trimmed,
            role: role.isEmpty ? "Supporting" : role
        )
        project.addDraft(draft)
        activeDraftID = draft.id
    }

    func removeActiveDraft() {
        guard let draft = activeDraft else { return }
        project.removeDraft(id: draft.id)
        activeDraftID = activeBible?.characterDrafts.first?.id
    }

    /// Promote the active draft into a LabCharacter in the project.
    /// Idempotent — if already promoted, does nothing.
    func promoteActiveDraftToLab() {
        guard let bible = activeBible, var draft = activeDraft, !draft.isPromoted else { return }
        let labCharacter = LabCharacter(
            name: draft.name,
            description: bible.labDescription(for: draft),
            role: bible.mapLabRole(for: draft)
        )
        project.upsertCharacter(labCharacter)
        draft.promotedLabCharacterID = labCharacter.id
        project.markDraftPromoted(draftID: draft.id, labCharacterID: labCharacter.id)
    }

    // MARK: Structure

    func chooseTemplate(_ template: StoryStructureTemplate) {
        project.chooseTemplate(template)
        selectedBeatID = project.activeBible?.structure.beats.first?.id
    }

    func selectBeat(_ id: UUID) {
        selectedBeatID = id
    }

    func updateBeatNotes(_ notes: String) {
        guard let beat = selectedBeat else { return }
        project.updateBeatNotes(beatID: beat.id, notes: notes)
    }

    // MARK: Scenes

    func expandScene(_ id: UUID) {
        if expandedSceneID == id {
            expandedSceneID = nil
            focusedSceneField = nil
        } else {
            expandedSceneID = id
            focusedSceneField = nil
        }
    }

    func addScene(title: String, location: String) {
        guard let bible = activeBible else { return }
        let next = (bible.sceneBreakdowns.map(\.number).max() ?? 0) + 1
        let scene = SceneBreakdown(
            number: next,
            title: title.isEmpty ? "New Scene" : title,
            location: location.isEmpty ? "Untitled Location" : location,
            isInterior: true,
            timeOfDay: .day
        )
        project.addScene(scene)
        expandedSceneID = scene.id
    }

    func updateScene(_ scene: SceneBreakdown) {
        project.updateScene(scene)
    }

    func removeScene(_ id: UUID) {
        project.removeScene(id: id)
        if expandedSceneID == id { expandedSceneID = nil }
    }

    func promoteScene(_ scene: SceneBreakdown) {
        guard !scene.isPromoted else { return }
        let bibleTitle = activeBible?.projectTitle ?? "Untitled"
        let filmScene = FilmScene(
            number: (project.scenes.map(\.number).max() ?? 0) + 1,
            title: scene.title,
            location: scene.location,
            isInterior: scene.isInterior,
            timeOfDay: scene.timeOfDay,
            lightingMood: .neutral,
            keyLight: .frontal,
            shotType: .medium,
            background: nil,
            props: [],
            characters: [],
            activeGuides: [.ruleOfThirds],
            frameApproved: false,
            projectTitle: bibleTitle
        )
        project.addFilmScene(filmScene)
        project.markScenePromoted(sceneID: scene.id, filmSceneID: filmScene.id)
    }

    // MARK: Storyboard cross-module

    func hasStoryboard(scene: SceneBreakdown) -> Bool {
        project.sequence(forSceneBreakdown: scene.id) != nil
    }

    func storyboardScene(_ scene: SceneBreakdown) {
        guard let bible = activeBible, !hasStoryboard(scene: scene) else { return }
        _ = project.addSequence(fromScene: scene, bible: bible)
    }

    // MARK: Theme

    func updateThemeStatement(_ text: String) {
        guard var theme = activeBible?.theme else { return }
        theme.themeStatement = text
        project.updateTheme(theme)
    }

    func addMotif(label: String, symbol: String, tint: Color) {
        guard var theme = activeBible?.theme else { return }
        let motif = VisualMotif(label: label, symbol: symbol, tint: tint, frequency: 1)
        theme.motifs.append(motif)
        project.updateTheme(theme)
    }

    func removeMotif(_ id: UUID) {
        guard var theme = activeBible?.theme else { return }
        theme.motifs.removeAll(where: { $0.id == id })
        project.updateTheme(theme)
    }

    func addPaletteSwatch(hex: String, color: Color, role: String) {
        guard var theme = activeBible?.theme else { return }
        let swatch = ColorPaletteSwatch(hex: hex, color: color, role: role)
        theme.palette.append(swatch)
        project.updateTheme(theme)
    }

    func removePaletteSwatch(_ id: UUID) {
        guard var theme = activeBible?.theme else { return }
        theme.palette.removeAll(where: { $0.id == id })
        project.updateTheme(theme)
    }

    // MARK: Bible lifecycle

    func createNewBible(title: String) {
        _ = project.createBible(title: title)
        activeSection = .characters
        activeDraftID = nil
    }

    func setActiveBible(_ id: UUID) {
        project.setActiveBible(id)
    }
}
