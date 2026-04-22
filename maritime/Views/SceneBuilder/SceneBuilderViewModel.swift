import SwiftUI
import Combine

@MainActor
final class SceneBuilderViewModel: ObservableObject {
    @Published var scenes: [FilmScene] = SceneBuilderSamples.scenes
    @Published var activeSceneID: UUID?
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var showBackgroundPicker = false
    @Published var showPropPicker = false

    init() {
        activeSceneID = scenes.first?.id
    }

    var activeScene: FilmScene? {
        scenes.first(where: { $0.id == activeSceneID })
    }

    private func mutate(_ block: (inout FilmScene) -> Void) {
        guard let idx = scenes.firstIndex(where: { $0.id == activeSceneID }) else { return }
        block(&scenes[idx])
    }

    func setActive(_ scene: FilmScene) {
        activeSceneID = scene.id
    }

    // MARK: Scene Setup

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

    /// Adds a finalized LabCharacter to the active scene at the given
    /// normalized (0-1) canvas position. Returns true on success.
    @discardableResult
    func addCharacter(from lab: LabCharacter, at position: CGPoint) -> Bool {
        guard scenes.firstIndex(where: { $0.id == activeSceneID }) != nil else { return false }
        // Don't add duplicates by name in the same scene
        if activeScene?.characters.contains(where: { $0.name == lab.name }) == true {
            // Move existing instead
            if let existing = activeScene?.characters.first(where: { $0.name == lab.name }) {
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

    func generateFrame() {
        isGenerating = true
        generationProgress = 0
        Task {
            for i in 1...12 {
                try? await Task.sleep(nanoseconds: 90_000_000)
                generationProgress = Double(i) / 12.0
            }
            isGenerating = false
        }
    }

    func approveFrame() {
        mutate { $0.frameApproved = true }
    }

    func regenerateFrame() {
        mutate { $0.frameApproved = false }
        generateFrame()
    }

    func createNewScene() {
        let nextNumber = (scenes.map { $0.number }.max() ?? 0) + 1
        let scene = FilmScene(
            number: nextNumber,
            title: "New Scene",
            location: "Untitled Location",
            isInterior: true,
            timeOfDay: .day,
            lightingMood: .neutral,
            keyLight: .frontal,
            shotType: .medium,
            background: nil,
            props: [],
            characters: [],
            activeGuides: [.ruleOfThirds],
            frameApproved: false,
            projectTitle: "Untitled Project"
        )
        scenes.append(scene)
        activeSceneID = scene.id
    }
}
