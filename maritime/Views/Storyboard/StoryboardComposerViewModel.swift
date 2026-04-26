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
    @Published var breakdownErrorMessage: String?

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

    // MARK: Frame Builder hand-off

    /// Adds a fresh keyframe to the selected panel — first call seeds a
    /// `.keyStart`, subsequent calls append `.keyEnd` then `.intermediate`.
    @discardableResult
    func addKeyframeToSelectedPanel() -> (panel: StoryboardPanel, frame: Frame)? {
        guard let panel = selectedPanel else { return nil }
        let panelFrames = project.frames(forPanel: panel.id)
        let ordinal = panelFrames.count
        let role: FrameRole
        switch ordinal {
        case 0:  role = .keyStart
        case 1:  role = .keyEnd
        default: role = .intermediate
        }
        let originScene = originSceneBreakdown(for: panel)
        let title = originScene.map { "Scene \($0.number) · Shot \(panel.number) · \(role.rawValue)" }
            ?? "Shot \(panel.number) · \(role.rawValue)"
        let location = originScene?.title ?? project.bible.projectTitle
        let frame = Frame(
            panelID: panel.id,
            ordinal: ordinal,
            role: role,
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
        project.appendFrame(frame, toPanel: panel.id)
        return (panel, frame)
    }

    // MARK: Scene lookup

    func originSceneBreakdown(for panel: StoryboardPanel) -> SceneBreakdown? {
        guard let id = panel.sceneBreakdownID else { return nil }
        return project.bible.sceneBreakdowns.first(where: { $0.id == id })
    }

    // MARK: AI shot breakdown

    /// Drives the two-phase shot breakdown for a single scene's shot plan:
    /// Claude plans 3–6 shots, then Nano Banana 2 renders a pencil sketch per
    /// shot. Updates `plan.status` as it progresses; UI observes via
    /// `project.objectWillChange`.
    func generateBreakdown(forPlan planID: UUID) async {
        breakdownErrorMessage = nil

        guard let plan = project.shotPlans.first(where: { $0.id == planID }),
              let scene = project.bible.sceneBreakdowns.first(where: { $0.id == plan.sceneBreakdownID }) else {
            return
        }

        let anthropicKey = KeychainStore.get(account: .anthropic) ?? ""
        let falKey = KeychainStore.get(account: .fal) ?? ""

        var working = plan
        working.status = .generating
        working.lastError = nil
        project.updateShotPlan(working)

        let service = StoryboardBreakdownService(
            anthropic: AnthropicClient(apiKey: anthropicKey),
            fal: FalaiClient(apiKey: falKey)
        )
        let request = StoryboardBreakdownService.Request(
            scene: scene,
            bible: project.bible,
            characters: project.characters,
            moodboard: project.moodboard
        )

        let plans: [StoryboardBreakdownService.ShotPlan]
        do {
            plans = try await service.planShots(request)
        } catch {
            failBreakdown(planID: planID, error: error)
            return
        }

        let panels = plans.map { plan in
            StoryboardPanel(
                number: 0,
                shotType: plan.shotType,
                cameraMovement: plan.cameraMovement,
                duration: plan.duration,
                actionNote: plan.actionNote,
                dialogue: plan.dialogue,
                timeOfDay: scene.timeOfDay,
                editingPriority: plan.editingPriority,
                characterDraftIDs: plan.characterDraftIDs,
                sceneBreakdownID: scene.id,
                aiBreakdownReasoning: plan.reasoning
            )
        }
        project.replaceShotPlanPanels(planID: planID, panels: panels)

        let characterRefs = collectCharacterRefs(for: plans, scene: scene)
        let moodRefs = collectMoodRefs()

        let scenePanelIDs = project.storyboardPanels
            .filter { $0.sceneBreakdownID == scene.id }
            .map(\.id)

        for (plan, panelID) in zip(plans, scenePanelIDs) {
            do {
                let png = try await service.renderSketch(
                    plan: plan,
                    characterRefs: characterRefs,
                    moodRefs: moodRefs
                )
                let assetID = UUID()
                project.setAssetImageData(png, for: assetID)
                project.mutatePanel(id: panelID) {
                    $0.pencilSketchAssetID = assetID
                }
            } catch {
                failBreakdown(planID: planID, error: error)
                return
            }
        }

        var finished = working
        finished.status = .ready
        finished.lastGeneratedAt = Date()
        finished.lastError = nil
        project.updateShotPlan(finished)
    }

    private func failBreakdown(planID: UUID, error: Error) {
        breakdownErrorMessage = error.localizedDescription
        guard var plan = project.shotPlans.first(where: { $0.id == planID }) else { return }
        plan.status = .failed
        plan.lastError = error.localizedDescription
        project.updateShotPlan(plan)
    }

    private func collectCharacterRefs(for plans: [StoryboardBreakdownService.ShotPlan],
                                      scene: SceneBreakdown) -> [Data] {
        let referencedDraftIDs = Set(plans.flatMap(\.characterDraftIDs))
            .union(scene.characterDraftIDs)
        let nameSet = Set(referencedDraftIDs.compactMap { id in
            project.bible.characterDrafts.first(where: { $0.id == id })?.name.lowercased()
        })

        var refs: [Data] = []
        for character in project.characters where character.isFinalized {
            if !nameSet.isEmpty && !nameSet.contains(character.name.lowercased()) { continue }
            if let portrait = character.selectedPortrait {
                refs.append(portrait.imageData)
            } else if let first = character.portraitVariations.first {
                refs.append(first.imageData)
            }
        }
        return refs
    }

    private func collectMoodRefs() -> [Data] {
        Array(project.moodboard.items
            .filter { $0.kind == .referenceImage || $0.kind == .characterRef || $0.kind == .setPieceRef }
            .compactMap(\.imageData)
            .prefix(2))
    }
}
