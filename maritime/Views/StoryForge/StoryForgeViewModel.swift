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
    @Published var showAddMotifSheet = false
    @Published var wizardMode: CharacterWizardMode?
    @Published var regeneratingField: StoryCharacterField?
    @Published var generationError: String?

    /// Drives the confirmation dialog before deleting the active character draft.
    @Published var confirmingDraftDelete = false
    /// Drives the confirmation dialog before deleting a scene breakdown.
    @Published var pendingSceneDeletionID: UUID?

    enum SceneField: String {
        case goal, conflict, emotionalBeat, visualMetaphor, transition
    }

    private let project: MovieBlazeProject
    private var cancellables: Set<AnyCancellable> = []

    init(project: MovieBlazeProject) {
        self.project = project
        activeDraftID = project.bible.characterDrafts.first?.id
        selectedBeatID = project.bible.structure.beats.first?.id

        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: Lookups

    var bible: StoryBible { project.bible }

    var activeDraft: StoryCharacterDraft? {
        guard let id = activeDraftID else { return nil }
        return bible.characterDrafts.first(where: { $0.id == id })
    }

    var selectedBeat: StoryBeat? {
        guard let id = selectedBeatID else { return nil }
        return bible.structure.beats.first(where: { $0.id == id })
    }

    var expandedScene: SceneBreakdown? {
        guard let id = expandedSceneID else { return nil }
        return bible.sceneBreakdowns.first(where: { $0.id == id })
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

    /// Add a fully-formed draft (used by the AI wizard when the user applies generated fields).
    func insertDraft(_ draft: StoryCharacterDraft) {
        project.addDraft(draft)
        activeDraftID = draft.id
    }

    /// Apply wizard edits to an existing draft. Only writes generated fields the wizard produced;
    /// anything not in `generated` is left untouched.
    func updateDraftFields(id: UUID,
                           name: String,
                           role: String,
                           backstory: String,
                           generated: [StoryCharacterField: String]) {
        guard var draft = bible.characterDrafts.first(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        draft.name = trimmedName.isEmpty ? draft.name : trimmedName
        draft.role = role
        draft.backstory = backstory
        for (field, value) in generated {
            draft.setValue(value, for: field)
        }
        project.updateDraft(draft)
        activeDraftID = id
    }

    /// Inline regeneration of a single psychology field on the active draft.
    /// Other non-empty fields are passed as context so the new value stays coherent.
    func regenerate(field: StoryCharacterField, settings: AppSettings) async {
        guard let draft = activeDraft else { return }
        guard settings.isConfigured else {
            generationError = "Add your Anthropic API key in Preferences (⌘,) first."
            return
        }
        guard StoryCharacterField.psychologyFields.contains(field) else { return }

        regeneratingField = field
        defer { regeneratingField = nil }
        generationError = nil

        var context: [StoryCharacterField: String] = [:]
        for f in StoryCharacterField.psychologyFields where f != field {
            let value = draft.value(for: f)
            if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                context[f] = value
            }
        }

        let client = AnthropicClient(apiKey: settings.apiKey, model: settings.modelID)
        let service = CharacterGenerationService(client: client)
        let req = CharacterGenerationService.Request(
            name: draft.name,
            role: draft.role,
            backstory: draft.backstory,
            existing: context,
            fieldsToFill: [field]
        )

        do {
            let result = try await service.generate(req)
            if let value = result.fields[field] {
                updateDraftField(field, value: value)
            }
        } catch {
            generationError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func removeActiveDraft() {
        guard let draft = activeDraft else { return }
        project.removeDraft(id: draft.id)
        activeDraftID = bible.characterDrafts.first?.id
    }

    /// True when the active draft is paired with a Lab character. Used to
    /// decide whether the delete confirmation needs to mention unlinking.
    var activeDraftHasLabLink: Bool {
        activeDraft?.promotedLabCharacterID != nil
    }

    // MARK: Structure

    func chooseTemplate(_ template: StoryStructureTemplate) {
        project.chooseTemplate(template)
        selectedBeatID = bible.structure.beats.first?.id
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

    /// Confirm + delete a scene that the user has chosen to remove. Triggered
    /// from the per-scene "Remove" button via `pendingSceneDeletionID`.
    func confirmPendingSceneDeletion() {
        guard let id = pendingSceneDeletionID else { return }
        removeScene(id)
        pendingSceneDeletionID = nil
    }

    func sceneHasFilmSceneLink(_ id: UUID) -> Bool {
        guard let scene = bible.sceneBreakdowns.first(where: { $0.id == id }) else { return false }
        return scene.promotedFilmSceneID != nil
    }

    // MARK: Storyboard cross-module

    func hasStoryboard(scene: SceneBreakdown) -> Bool {
        !project.panels(forSceneBreakdown: scene.id).isEmpty
    }

    func storyboardScene(_ scene: SceneBreakdown) {
        guard !hasStoryboard(scene: scene) else { return }
        _ = project.appendPanels(fromScene: scene)
    }

    // MARK: Theme

    func updateThemeStatement(_ text: String) {
        var theme = bible.theme
        theme.themeStatement = text
        project.updateTheme(theme)
    }

    func addMotif(label: String, symbol: String, tint: Color) {
        var theme = bible.theme
        let motif = VisualMotif(label: label, symbol: symbol, tint: tint, frequency: 1)
        theme.motifs.append(motif)
        project.updateTheme(theme)
    }

    func removeMotif(_ id: UUID) {
        var theme = bible.theme
        theme.motifs.removeAll(where: { $0.id == id })
        project.updateTheme(theme)
    }

    func addPaletteSwatch(hex: String, color: Color, role: String) {
        var theme = bible.theme
        let swatch = ColorPaletteSwatch(hex: hex, color: color, role: role)
        theme.palette.append(swatch)
        project.updateTheme(theme)
    }

    func removePaletteSwatch(_ id: UUID) {
        var theme = bible.theme
        theme.palette.removeAll(where: { $0.id == id })
        project.updateTheme(theme)
    }
}
