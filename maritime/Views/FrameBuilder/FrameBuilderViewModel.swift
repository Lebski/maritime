import SwiftUI
import Combine

@MainActor
final class FrameBuilderViewModel: ObservableObject {
    @Published var activeFrameID: UUID?
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var showBackgroundPicker = false
    @Published var showPropPicker = false
    @Published var leftCollapsed = false
    @Published var rightCollapsed = false
    @Published var renderErrorMessage: String?

    private let project: MovieBlazeProject
    private let imageService: ImageGenerationService
    private var cancellables: Set<AnyCancellable> = []

    var frames: [Frame] { project.frames }

    init(project: MovieBlazeProject,
         imageService: ImageGenerationService = FalaiSceneRenderService()) {
        self.project = project
        self.imageService = imageService
        activeFrameID = project.frames.first?.id
        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var activeFrame: Frame? {
        project.frames.first(where: { $0.id == activeFrameID })
    }

    private func mutate(_ block: (inout Frame) -> Void) {
        guard let id = activeFrameID else { return }
        project.mutateFrame(id: id, block)
    }

    func setActive(_ frame: Frame) {
        activeFrameID = frame.id
    }

    // MARK: Frame Setup

    func setTimeOfDay(_ time: TimeOfDay) { mutate { $0.timeOfDay = time } }
    func setMood(_ mood: LightingMood) { mutate { $0.lightingMood = mood } }
    func setKeyLight(_ dir: KeyLightDirection) { mutate { $0.keyLight = dir } }
    func setShot(_ shot: CameraShotType) { mutate { $0.shotType = shot } }
    func setInterior(_ isInterior: Bool) { mutate { $0.isInterior = isInterior } }
    func setBackground(_ bg: SceneBackground) { mutate { $0.background = bg } }
    func addProp(_ prop: SceneProp) {
        mutate { if !$0.props.contains(prop) { $0.props.append(prop) } }
    }
    func removeProp(_ prop: SceneProp) {
        mutate { $0.props.removeAll(where: { $0.id == prop.id }) }
    }
    func toggleGuide(_ guide: CompositionGuide) {
        mutate {
            if $0.activeGuides.contains(guide) { $0.activeGuides.remove(guide) }
            else { $0.activeGuides.insert(guide) }
        }
    }

    // MARK: Canvas

    func moveCharacter(id: UUID, x: CGFloat, y: CGFloat) {
        mutate {
            if let i = $0.characters.firstIndex(where: { $0.id == id }) {
                $0.characters[i].xRatio = max(0.05, min(0.95, x))
                $0.characters[i].yRatio = max(0.1, min(0.9, y))
            }
        }
    }

    /// Adds a finalized LabCharacter to the active frame at the given
    /// normalized (0-1) canvas position. Returns true on success.
    @discardableResult
    func addCharacter(from lab: LabCharacter, at position: CGPoint) -> Bool {
        guard project.frames.firstIndex(where: { $0.id == activeFrameID }) != nil else { return false }
        if activeFrame?.characters.contains(where: { $0.name == lab.name }) == true {
            if let existing = activeFrame?.characters.first(where: { $0.name == lab.name }) {
                moveCharacter(id: existing.id, x: position.x, y: position.y)
            }
            return false
        }
        let tint = lab.finalVariation?.accentColor ?? Theme.magenta
        let ref = SceneCharacterRef(
            name: lab.name,
            role: lab.role,
            tint: tint,
            xRatio: max(0.05, min(0.95, position.x)),
            yRatio: max(0.1, min(0.9, position.y)),
            gazeDegrees: position.x < 0.5 ? 10 : -170,
            depthLayer: .foreground
        )
        mutate { $0.characters.append(ref) }
        return true
    }

    func removeCharacter(id: UUID) {
        mutate { $0.characters.removeAll(where: { $0.id == id }) }
    }

    func cycleDepth(id: UUID) {
        mutate {
            if let i = $0.characters.firstIndex(where: { $0.id == id }) {
                let all = DepthLayer.allCases
                let cur = $0.characters[i].depthLayer
                let next = all.firstIndex(of: cur).map { (all.count + $0 + 1) % all.count } ?? 0
                $0.characters[i].depthLayer = all[next]
            }
        }
    }

    // MARK: Generation

    /// Assembles the render package onto the active frame and kicks off the
    /// image generation service. Returns `true` on success (caller can dismiss).
    @discardableResult
    func render(package: RenderPackage) async -> Bool {
        renderErrorMessage = nil

        if package.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            renderErrorMessage = ImageGenerationError.missingPrompt.errorDescription
            return false
        }
        if package.totalReferenceImageCount > package.model.maxReferenceImages {
            renderErrorMessage = ImageGenerationError
                .tooManyReferenceImages(package.totalReferenceImageCount,
                                         max: package.model.maxReferenceImages)
                .errorDescription
            return false
        }

        mutate { $0.renderPackage = package }

        isGenerating = true
        generationProgress = 0
        let progressTask = Task { [weak self] in
            for i in 1...20 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                guard let self, self.isGenerating else { return }
                self.generationProgress = min(0.95, Double(i) / 20.0)
            }
        }

        do {
            _ = try await imageService.generate(package: package)
            progressTask.cancel()
            generationProgress = 1.0
            mutate {
                $0.renderPackage?.lastRenderedAt = Date()
            }
            isGenerating = false
            return true
        } catch {
            progressTask.cancel()
            isGenerating = false
            renderErrorMessage = error.localizedDescription
            return false
        }
    }

    func approveFrame() {
        mutate { $0.frameApproved = true }
        rollUpClipApproval(forFrameID: activeFrameID)
    }

    func unapproveFrame() {
        mutate { $0.frameApproved = false }
        rollUpClipApproval(forFrameID: activeFrameID)
    }

    /// After a frame's approval flips, recompute the parent panel's
    /// `clipApproved` so it matches "all frames approved".
    private func rollUpClipApproval(forFrameID frameID: UUID?) {
        guard let id = frameID,
              let frame = project.frames.first(where: { $0.id == id }) else { return }
        let siblings = project.frames(forPanel: frame.panelID)
        guard !siblings.isEmpty else { return }
        let allApproved = siblings.allSatisfy { $0.frameApproved }
        project.mutatePanel(id: frame.panelID) { $0.clipApproved = allApproved }
    }

    func regenerateFrame() {
        mutate { $0.frameApproved = false }
        rollUpClipApproval(forFrameID: activeFrameID)
        Task {
            guard let frame = activeFrame else { return }
            let package = frame.renderPackage
                ?? RenderPackage(frameID: frame.id,
                                 prompt: PromptBuilder.buildPrompt(frame: frame,
                                                                   characters: project.characters))
            await render(package: package)
        }
    }

    /// Convenience: appends a keyframe to whichever panel currently holds the
    /// active frame. No-op if nothing is selected. Used by the sidebar's
    /// "New Frame" button until the tree-style sidebar lands in Phase 6.
    @discardableResult
    func addKeyframeToActivePanel() -> Frame? {
        guard let panelID = activeFrame?.panelID else { return nil }
        return addKeyframe(toPanel: panelID)
    }

    /// Appends a keyframe to the given panel. Ordinal/role are derived from the
    /// panel's existing frames: 0 → keyStart, 1 → keyEnd, 2+ → intermediate.
    @discardableResult
    func addKeyframe(toPanel panelID: UUID) -> Frame? {
        guard let panel = project.storyboardPanels.first(where: { $0.id == panelID }) else {
            return nil
        }
        let panelFrames = project.frames(forPanel: panelID)
        let ordinal = panelFrames.count
        let role: FrameRole
        switch ordinal {
        case 0:  role = .keyStart
        case 1:  role = .keyEnd
        default: role = .intermediate
        }
        let originScene = project.bible.sceneBreakdowns.first(where: { $0.id == panel.sceneBreakdownID })
        let title = originScene.map { "Scene \($0.number) · Shot \(panel.number) · \(role.rawValue)" }
            ?? "Shot \(panel.number) · \(role.rawValue)"
        let location = originScene?.title ?? project.bible.projectTitle
        let frame = Frame(
            panelID: panelID,
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
        project.appendFrame(frame, toPanel: panelID)
        activeFrameID = frame.id
        return frame
    }
}
