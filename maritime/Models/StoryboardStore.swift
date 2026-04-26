import SwiftUI

// MARK: - Storyboard mutators
//
// Extensions on MovieBlazeProject for the storyboard's shot catalogue. Panels
// are a flat list — one project = one ordered shot sequence. Panels carry the
// source SceneBreakdown ID so the UI can group by scene. AI shot-breakdown
// status lives in `shotPlans` (one per scene); panels themselves remain the
// authoritative shot list, with frame-builder keyframes attached via
// `frameIDs`.

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

    func mutatePanel(id: UUID, _ block: (inout StoryboardPanel) -> Void) {
        guard let i = storyboardPanels.firstIndex(where: { $0.id == id }) else { return }
        block(&storyboardPanels[i])
    }

    func removePanel(id: UUID) {
        if let panel = storyboardPanels.first(where: { $0.id == id }) {
            cleanupAssets(forPanel: panel)
        }
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

    // MARK: Scene → Storyboard

    func panels(forSceneBreakdown sceneID: UUID) -> [StoryboardPanel] {
        storyboardPanels.filter { $0.sceneBreakdownID == sceneID }
    }

    // MARK: Shot Plan (AI-driven breakdown)

    func shotPlan(forScene sceneID: UUID) -> SceneShotPlan? {
        shotPlans.first(where: { $0.sceneBreakdownID == sceneID })
    }

    /// Idempotent — returns the existing plan for the scene if one exists,
    /// else appends a fresh `.empty` stub.
    @discardableResult
    func createShotPlanStub(forScene sceneID: UUID) -> SceneShotPlan {
        if let existing = shotPlan(forScene: sceneID) { return existing }
        let plan = SceneShotPlan(sceneBreakdownID: sceneID, status: .empty)
        shotPlans.append(plan)
        return plan
    }

    func updateShotPlan(_ plan: SceneShotPlan) {
        guard let i = shotPlans.firstIndex(where: { $0.id == plan.id }) else { return }
        shotPlans[i] = plan
    }

    /// Removes panels with the plan's `sceneBreakdownID`, appends `panels`,
    /// renumbers the global list, and cleans up orphaned sketch assets.
    func replaceShotPlanPanels(planID: UUID, panels: [StoryboardPanel]) {
        guard let plan = shotPlans.first(where: { $0.id == planID }) else { return }
        let sceneID = plan.sceneBreakdownID
        let outgoing = storyboardPanels.filter { $0.sceneBreakdownID == sceneID }
        for panel in outgoing { cleanupAssets(forPanel: panel) }
        storyboardPanels.removeAll { $0.sceneBreakdownID == sceneID }
        var stamped = panels
        for i in stamped.indices { stamped[i].sceneBreakdownID = sceneID }
        storyboardPanels.append(contentsOf: stamped)
        for i in storyboardPanels.indices { storyboardPanels[i].number = i + 1 }
    }

    // MARK: Frame attachment

    func appendFrame(_ frame: Frame, toPanel panelID: UUID) {
        guard storyboardPanels.contains(where: { $0.id == panelID }) else { return }
        var stamped = frame
        stamped.panelID = panelID
        if !frames.contains(where: { $0.id == stamped.id }) {
            frames.append(stamped)
        } else {
            updateFrame(stamped)
        }
        mutatePanel(id: panelID) {
            if !$0.frameIDs.contains(stamped.id) {
                $0.frameIDs.append(stamped.id)
            }
        }
    }

    // MARK: Asset cleanup

    private func cleanupAssets(forPanel panel: StoryboardPanel) {
        if let sketch = panel.pencilSketchAssetID {
            assetImageBytes.removeValue(forKey: sketch)
            assetEditCounts.removeValue(forKey: sketch)
        }
        for frameID in panel.frameIDs {
            removeFrame(id: frameID)
            assetImageBytes.removeValue(forKey: frameID)
            assetEditCounts.removeValue(forKey: frameID)
        }
    }
}
