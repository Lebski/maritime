import SwiftUI

// MARK: - Storyboard mutators
//
// Extensions on MovieBlazeProject that replace the old singleton
// StoryboardStore. Panels are a flat list on the project — one project =
// one ordered panel sequence. Panels originating from a Story Forge
// SceneBreakdown carry the source ID so the UI can still group by scene.

@MainActor
extension MovieBlazeProject {

    // MARK: Panel CRUD

    func addPanel(_ panel: StoryboardPanel) {
        var p = panel
        p.number = storyboardPanels.count + 1
        storyboardPanels.append(p)
    }

    func updatePanel(_ panel: StoryboardPanel) {
        guard let i = storyboardPanels.firstIndex(where: { $0.id == panel.id }) else { return }
        storyboardPanels[i] = panel
    }

    func removePanel(id: UUID) {
        storyboardPanels.removeAll(where: { $0.id == id })
        for i in storyboardPanels.indices { storyboardPanels[i].number = i + 1 }
    }

    func reorderPanels(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0, sourceIndex < storyboardPanels.count else { return }
        let panel = storyboardPanels.remove(at: sourceIndex)
        let target = max(0, min(destinationIndex, storyboardPanels.count))
        storyboardPanels.insert(panel, at: target)
        for i in storyboardPanels.indices { storyboardPanels[i].number = i + 1 }
    }

    func markPanelPromoted(panelID: UUID, filmSceneID: UUID) {
        guard let i = storyboardPanels.firstIndex(where: { $0.id == panelID }) else { return }
        storyboardPanels[i].promotedFilmSceneID = filmSceneID
    }

    // MARK: Scene → Storyboard promotion

    func panels(forSceneBreakdown sceneID: UUID) -> [StoryboardPanel] {
        storyboardPanels.filter { $0.sceneBreakdownID == sceneID }
    }

    /// Append four starter panels (WS → CU → OTS → WS) seeded from a
    /// Story Forge SceneBreakdown. Returns the newly appended panels so the
    /// caller can scroll-to them.
    @discardableResult
    func appendPanels(fromScene scene: SceneBreakdown) -> [StoryboardPanel] {
        let colors = bible.posterColors
        let symbol: String
        switch scene.timeOfDay {
        case .dawn:        symbol = "sunrise.fill"
        case .day:         symbol = "sun.max.fill"
        case .goldenHour:  symbol = "sun.horizon.fill"
        case .dusk:        symbol = "sunset.fill"
        case .night:       symbol = "moon.stars.fill"
        }
        let base = storyboardPanels.count
        let seed: [StoryboardPanel] = [
            StoryboardPanel(number: base + 1, shotType: .wide, cameraMovement: .static, duration: 4.0,
                            actionNote: "Establishing — \(scene.locationLabel).",
                            timeOfDay: scene.timeOfDay, editingPriority: .rhythm,
                            characterDraftIDs: scene.characterDraftIDs,
                            thumbnailSymbol: symbol, thumbnailColors: colors,
                            sceneBreakdownID: scene.id),
            StoryboardPanel(number: base + 2, shotType: .closeUp, cameraMovement: .static, duration: 2.2,
                            actionNote: scene.emotionalBeat.isEmpty ? "Reaction." : scene.emotionalBeat,
                            timeOfDay: scene.timeOfDay, editingPriority: .emotion,
                            characterDraftIDs: scene.characterDraftIDs,
                            thumbnailSymbol: symbol, thumbnailColors: colors,
                            sceneBreakdownID: scene.id),
            StoryboardPanel(number: base + 3, shotType: .overTheShoulder, cameraMovement: .static, duration: 2.5,
                            actionNote: scene.conflict.isEmpty ? "Conflict beat." : scene.conflict,
                            timeOfDay: scene.timeOfDay, editingPriority: .story,
                            characterDraftIDs: scene.characterDraftIDs,
                            thumbnailSymbol: symbol, thumbnailColors: colors,
                            sceneBreakdownID: scene.id),
            StoryboardPanel(number: base + 4, shotType: .wide, cameraMovement: .zoomOut, duration: 3.2,
                            actionNote: scene.transitionNote.isEmpty ? "Outro — release the tension." : scene.transitionNote,
                            timeOfDay: scene.timeOfDay, editingPriority: .rhythm,
                            characterDraftIDs: scene.characterDraftIDs,
                            thumbnailSymbol: symbol, thumbnailColors: colors,
                            sceneBreakdownID: scene.id)
        ]
        storyboardPanels.append(contentsOf: seed)
        return seed
    }
}
