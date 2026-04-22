import SwiftUI

// MARK: - Scene (FilmScene) mutators
//
// Extensions on MovieBlazeProject that replace the old singleton SceneStore.

@MainActor
extension MovieBlazeProject {

    func addFilmScene(_ scene: FilmScene) {
        scenes.append(scene)
    }

    func updateFilmScene(_ scene: FilmScene) {
        if let i = scenes.firstIndex(where: { $0.id == scene.id }) {
            scenes[i] = scene
        }
    }

    func removeFilmScene(id: UUID) {
        scenes.removeAll(where: { $0.id == id })
    }

    func mutateFilmScene(id: UUID, _ block: (inout FilmScene) -> Void) {
        guard let i = scenes.firstIndex(where: { $0.id == id }) else { return }
        block(&scenes[i])
    }
}
