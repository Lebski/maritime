import SwiftUI

// MARK: - Video Renderer mutators
//
// Video clips are a strict projection of project.scenes — one FilmScene maps
// to one VideoClip. Per-clip state (motion + duration + approval) lives on the
// FilmScene itself, so editing in the Renderer or in Scene Builder writes to
// the same source of truth. Cut suggestions are first-class on the project.

@MainActor
extension MovieBlazeProject {

    /// Derives the renderer's clip list from the current scene catalogue.
    /// IDs match the source FilmScene so selection, mutations, and SwiftUI
    /// diffing stay stable across re-derivations.
    var videoClips: [VideoClip] {
        scenes
            .sorted { $0.number < $1.number }
            .map { scene in
                VideoClip(
                    id: scene.id,
                    number: scene.number,
                    title: scene.title,
                    sceneNumber: scene.number,
                    duration: scene.clipDuration,
                    motion: scene.clipMotion,
                    gradientSeed: scene.number,
                    isApproved: scene.frameApproved
                )
            }
    }

    func setClipMotion(_ motion: MotionIntensity, clipID: UUID) {
        mutateFilmScene(id: clipID) { $0.clipMotion = motion }
    }

    func setClipDuration(_ duration: Double, clipID: UUID) {
        mutateFilmScene(id: clipID) { $0.clipDuration = max(0.5, duration) }
    }

    func toggleClipApproval(clipID: UUID) {
        mutateFilmScene(id: clipID) { $0.frameApproved.toggle() }
    }

    func toggleCutApplied(cutID: UUID) {
        guard let i = cutSuggestions.firstIndex(where: { $0.id == cutID }) else { return }
        cutSuggestions[i].applied.toggle()
    }
}
