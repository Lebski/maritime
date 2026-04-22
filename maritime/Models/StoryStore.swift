import SwiftUI

// MARK: - Story Store
//
// Single source of truth for Story Bibles. Parallels CharacterStore.
// Pre-seeded with the four project bibles that match SampleData.projects
// so Story Forge feels continuous with the Home dashboard.

@MainActor
final class StoryStore: ObservableObject {
    static let shared = StoryStore()

    @Published var bibles: [StoryBible]
    @Published var activeBibleID: UUID?

    private init() {
        self.bibles = StoryForgeSamples.bibles
        // Default-active bible: Lantern Keeper — mid-complete, best showcase.
        self.activeBibleID = bibles.first(where: { $0.projectTitle == "The Lantern Keeper" })?.id
            ?? bibles.first?.id
    }

    var activeBible: StoryBible? {
        guard let id = activeBibleID else { return nil }
        return bibles.first(where: { $0.id == id })
    }

    func setActiveBible(_ id: UUID) {
        activeBibleID = id
    }

    // MARK: Mutation

    private func mutateActive(_ block: (inout StoryBible) -> Void) {
        guard let id = activeBibleID,
              let idx = bibles.firstIndex(where: { $0.id == id }) else { return }
        block(&bibles[idx])
        bibles[idx].lastUpdated = Date()
    }

    // Character drafts
    func updateDraft(_ draft: StoryCharacterDraft) {
        mutateActive { bible in
            if let i = bible.characterDrafts.firstIndex(where: { $0.id == draft.id }) {
                bible.characterDrafts[i] = draft
            }
        }
    }

    func addDraft(_ draft: StoryCharacterDraft) {
        mutateActive { $0.characterDrafts.append(draft) }
    }

    func removeDraft(id: UUID) {
        mutateActive { $0.characterDrafts.removeAll(where: { $0.id == id }) }
    }

    func markDraftPromoted(draftID: UUID, labCharacterID: UUID) {
        mutateActive { bible in
            if let i = bible.characterDrafts.firstIndex(where: { $0.id == draftID }) {
                bible.characterDrafts[i].promotedLabCharacterID = labCharacterID
            }
        }
    }

    // Structure
    func chooseTemplate(_ template: StoryStructureTemplate) {
        mutateActive { $0.structure = StoryStructureDraft(template: template) }
    }

    func updateBeatNotes(beatID: UUID, notes: String) {
        mutateActive { bible in
            if let i = bible.structure.beats.firstIndex(where: { $0.id == beatID }) {
                bible.structure.beats[i].userNotes = notes
            }
        }
    }

    // Scenes
    func addScene(_ scene: SceneBreakdown) {
        mutateActive { $0.sceneBreakdowns.append(scene) }
    }

    func updateScene(_ scene: SceneBreakdown) {
        mutateActive { bible in
            if let i = bible.sceneBreakdowns.firstIndex(where: { $0.id == scene.id }) {
                bible.sceneBreakdowns[i] = scene
            }
        }
    }

    func removeScene(id: UUID) {
        mutateActive { $0.sceneBreakdowns.removeAll(where: { $0.id == id }) }
    }

    func markScenePromoted(sceneID: UUID, filmSceneID: UUID) {
        mutateActive { bible in
            if let i = bible.sceneBreakdowns.firstIndex(where: { $0.id == sceneID }) {
                bible.sceneBreakdowns[i].promotedFilmSceneID = filmSceneID
            }
        }
    }

    // Theme
    func updateTheme(_ theme: ThemeTracker) {
        mutateActive { $0.theme = theme }
    }

    // Bible lifecycle
    func createBible(title: String) -> StoryBible {
        let bible = StoryBible(
            projectTitle: title.isEmpty ? "Untitled Story" : title,
            logline: "",
            structure: StoryStructureDraft(template: .threeAct),
            posterColors: [Theme.violet, Theme.magenta]
        )
        bibles.append(bible)
        activeBibleID = bible.id
        return bible
    }
}
