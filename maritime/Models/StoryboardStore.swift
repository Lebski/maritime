import SwiftUI

// MARK: - Storyboard mutators
//
// Extensions on MovieBlazeProject that replace the old singleton
// StoryboardStore. All mutation still funnels through the active-sequence
// helper so lastUpdated is refreshed automatically.

@MainActor
extension MovieBlazeProject {

    // MARK: Sequence helpers

    func mutateActiveSequence(_ block: (inout StoryboardSequence) -> Void) {
        guard let id = activeSequenceID,
              let idx = sequences.firstIndex(where: { $0.id == id }) else { return }
        block(&sequences[idx])
        sequences[idx].lastUpdated = Date()
    }

    func mutateSequence(id: UUID, _ block: (inout StoryboardSequence) -> Void) {
        guard let idx = sequences.firstIndex(where: { $0.id == id }) else { return }
        block(&sequences[idx])
        sequences[idx].lastUpdated = Date()
    }

    // MARK: Panel CRUD

    func addPanel(_ panel: StoryboardPanel) {
        mutateActiveSequence { seq in
            var p = panel
            p.number = seq.panels.count + 1
            seq.panels.append(p)
        }
    }

    func updatePanel(_ panel: StoryboardPanel) {
        mutateActiveSequence { seq in
            guard let i = seq.panels.firstIndex(where: { $0.id == panel.id }) else { return }
            seq.panels[i] = panel
        }
    }

    func removePanel(id: UUID) {
        mutateActiveSequence { seq in
            seq.panels.removeAll(where: { $0.id == id })
            for i in seq.panels.indices { seq.panels[i].number = i + 1 }
        }
    }

    func reorderPanels(sequenceID: UUID, from sourceIndex: Int, to destinationIndex: Int) {
        mutateSequence(id: sequenceID) { seq in
            guard sourceIndex >= 0, sourceIndex < seq.panels.count else { return }
            let panel = seq.panels.remove(at: sourceIndex)
            let target = max(0, min(destinationIndex, seq.panels.count))
            seq.panels.insert(panel, at: target)
            for i in seq.panels.indices { seq.panels[i].number = i + 1 }
        }
    }

    func reorderActivePanels(from sourceIndex: Int, to destinationIndex: Int) {
        guard let id = activeSequenceID else { return }
        reorderPanels(sequenceID: id, from: sourceIndex, to: destinationIndex)
    }

    func markPanelPromoted(panelID: UUID, filmSceneID: UUID) {
        mutateActiveSequence { seq in
            guard let i = seq.panels.firstIndex(where: { $0.id == panelID }) else { return }
            seq.panels[i].promotedFilmSceneID = filmSceneID
        }
    }

    // MARK: Sequence lifecycle

    func addSequence(_ sequence: StoryboardSequence) {
        sequences.append(sequence)
        activeSequenceID = sequence.id
    }

    func sequence(forSceneBreakdown sceneID: UUID) -> StoryboardSequence? {
        sequences.first(where: { $0.sceneBreakdownID == sceneID })
    }

    /// Build a fresh sequence from a Story Forge SceneBreakdown with four
    /// starter panels (WS → CU → OTS → WS) so the user has a canvas to build on.
    @discardableResult
    func addSequence(fromScene scene: SceneBreakdown, bible: StoryBible) -> StoryboardSequence {
        let colors = bible.posterColors
        let symbol: String
        switch scene.timeOfDay {
        case .dawn:        symbol = "sunrise.fill"
        case .day:         symbol = "sun.max.fill"
        case .goldenHour:  symbol = "sun.horizon.fill"
        case .dusk:        symbol = "sunset.fill"
        case .night:       symbol = "moon.stars.fill"
        }
        let seed: [StoryboardPanel] = [
            StoryboardPanel(number: 1, shotType: .wide, cameraMovement: .static, duration: 4.0,
                            actionNote: "Establishing — \(scene.locationLabel).",
                            timeOfDay: scene.timeOfDay, editingPriority: .rhythm,
                            characterDraftIDs: scene.characterDraftIDs,
                            thumbnailSymbol: symbol, thumbnailColors: colors),
            StoryboardPanel(number: 2, shotType: .closeUp, cameraMovement: .static, duration: 2.2,
                            actionNote: scene.emotionalBeat.isEmpty ? "Reaction." : scene.emotionalBeat,
                            timeOfDay: scene.timeOfDay, editingPriority: .emotion,
                            characterDraftIDs: scene.characterDraftIDs,
                            thumbnailSymbol: symbol, thumbnailColors: colors),
            StoryboardPanel(number: 3, shotType: .overTheShoulder, cameraMovement: .static, duration: 2.5,
                            actionNote: scene.conflict.isEmpty ? "Conflict beat." : scene.conflict,
                            timeOfDay: scene.timeOfDay, editingPriority: .story,
                            characterDraftIDs: scene.characterDraftIDs,
                            thumbnailSymbol: symbol, thumbnailColors: colors),
            StoryboardPanel(number: 4, shotType: .wide, cameraMovement: .zoomOut, duration: 3.2,
                            actionNote: scene.transitionNote.isEmpty ? "Outro — release the tension." : scene.transitionNote,
                            timeOfDay: scene.timeOfDay, editingPriority: .rhythm,
                            characterDraftIDs: scene.characterDraftIDs,
                            thumbnailSymbol: symbol, thumbnailColors: colors)
        ]
        let seq = StoryboardSequence(
            title: scene.title,
            bibleID: bible.id,
            sceneBreakdownID: scene.id,
            projectTitle: bible.projectTitle,
            posterColors: colors,
            panels: seed
        )
        addSequence(seq)
        return seq
    }
}
