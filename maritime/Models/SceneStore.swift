import SwiftUI

// MARK: - Scene Store
//
// Shared scene list across Scene Builder and Story Forge.
// Scene Builder observes this store so that scenes promoted from Story Forge
// appear automatically.

@MainActor
final class SceneStore: ObservableObject {
    static let shared = SceneStore()

    @Published var scenes: [FilmScene]

    private init() {
        self.scenes = SceneBuilderSamples.scenes
    }

    func add(_ scene: FilmScene) {
        scenes.append(scene)
    }

    func update(_ scene: FilmScene) {
        if let i = scenes.firstIndex(where: { $0.id == scene.id }) {
            scenes[i] = scene
        }
    }

    func remove(id: UUID) {
        scenes.removeAll(where: { $0.id == id })
    }

    func mutate(id: UUID, _ block: (inout FilmScene) -> Void) {
        guard let i = scenes.firstIndex(where: { $0.id == id }) else { return }
        block(&scenes[i])
    }
}
