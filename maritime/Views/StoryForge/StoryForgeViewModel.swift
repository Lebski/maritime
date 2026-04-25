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

    // Bible wizard / scene-regen orchestration
    @Published var bibleWizardMode: StoryBibleWizardMode?
    @Published var pendingSceneDiff: SceneDiffProposal?
    @Published var showSceneDiff = false
    @Published var isRegeneratingScenes = false
    @Published var hasPresentedInitialWizard = false

    /// Snapshot of scenes at the moment the diff was proposed, plus the proposed scenes.
    /// Held on the VM so the diff stays stable even if the user keeps editing the bible.
    struct SceneDiffProposal {
        let oldScenes: [SceneBreakdown]
        let proposedScenes: [SceneBreakdown]
        let oldTemplate: StoryStructureTemplate
        let newTemplate: StoryStructureTemplate
    }

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

        if project.bible.isEmpty {
            Task { @MainActor [weak self] in
                guard let self, !self.hasPresentedInitialWizard else { return }
                self.bibleWizardMode = .initialEmpty
                self.hasPresentedInitialWizard = true
            }
        }
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

    /// Promote the active draft into a LabCharacter in the project.
    /// Idempotent — if already promoted, does nothing.
    func promoteActiveDraftToLab() {
        guard var draft = activeDraft, !draft.isPromoted else { return }
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

    func promoteScene(_ scene: SceneBreakdown) {
        guard !scene.isPromoted else { return }
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
            projectTitle: bible.projectTitle
        )
        project.addFilmScene(filmScene)
        project.markScenePromoted(sceneID: scene.id, filmSceneID: filmScene.id)
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

    // MARK: Bible wizard

    func openBibleWizard(mode: StoryBibleWizardMode) {
        bibleWizardMode = mode
    }

    /// Wholesale-replace the bible from a generated draft. Atomic at the document level.
    func applyGeneratedBible(title: String,
                             logline: String,
                             pitch: String,
                             characters: [StoryCharacterDraft],
                             structure: StoryStructureDraft,
                             scenes: [SceneBreakdown],
                             theme: ThemeTracker) {
        project.applyGeneratedBible(
            title: title,
            logline: logline,
            pitch: pitch,
            characters: characters,
            structure: structure,
            scenes: scenes,
            theme: theme
        )
        activeDraftID = characters.first?.id
        selectedBeatID = structure.beats.first?.id
        expandedSceneID = nil
        bibleWizardMode = nil
    }

    func updatePitch(_ text: String) {
        project.updatePitch(text)
    }

    // MARK: Scene regeneration

    /// Switch to a new structure template. If scenes already exist, kick off scene regeneration
    /// in the background and surface the result via `pendingSceneDiff` for the diff sheet.
    func chooseTemplateWithRegen(_ template: StoryStructureTemplate, settings: AppSettings) async {
        let oldStructure = bible.structure
        let oldScenes = bible.sceneBreakdowns

        project.chooseTemplate(template)
        selectedBeatID = bible.structure.beats.first?.id

        guard !oldScenes.isEmpty, oldStructure.template != template else { return }
        guard settings.isConfigured else {
            generationError = "Add your Anthropic API key in Preferences (⌘,) first."
            return
        }

        isRegeneratingScenes = true
        defer { isRegeneratingScenes = false }
        generationError = nil

        let client = AnthropicClient(apiKey: settings.apiKey, model: settings.modelID)
        let service = SceneRegenerationService(client: client)
        let req = SceneRegenerationService.Request(
            pitch: bible.pitch,
            logline: bible.logline,
            characters: bible.characterDrafts,
            oldTemplate: oldStructure.template,
            newTemplate: template,
            oldBeats: oldStructure.beats,
            newBeats: bible.structure.beats,
            oldScenes: oldScenes,
            theme: bible.theme
        )

        do {
            let out = try await service.generate(req)
            pendingSceneDiff = SceneDiffProposal(
                oldScenes: oldScenes,
                proposedScenes: out.scenes,
                oldTemplate: oldStructure.template,
                newTemplate: template
            )
            showSceneDiff = true
        } catch {
            generationError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Apply a user-curated scene diff: replacements/additions/removals derived from the proposal.
    func applySceneDiff(replacements: [Int: SceneBreakdown],
                        removals: Set<Int>,
                        additions: [SceneBreakdown]) {
        project.applySceneDiff(replacements: replacements, removals: removals, additions: additions)
        pendingSceneDiff = nil
        showSceneDiff = false
        expandedSceneID = nil
    }

    func dismissSceneDiff() {
        showSceneDiff = false
    }

    func discardSceneDiff() {
        pendingSceneDiff = nil
        showSceneDiff = false
    }
}
