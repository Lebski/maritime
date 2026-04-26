import SwiftUI

// MARK: - Video Renderer mutators
//
// Video clips are a strict projection of project.storyboardPanels — one panel
// (i.e. shot) maps to one VideoClip. Clip-time state (motion + duration +
// approval) lives on the panel, so editing in the Renderer or in Storyboard
// writes to the same source of truth. Frames in `panel.frameIDs` are keyframes
// rendered between by the motion model. Cut suggestions are first-class on the
// project.

@MainActor
extension MovieBlazeProject {

    /// Derives the renderer's clip list from the current panel catalogue.
    /// IDs match the source panel so selection, mutations, and SwiftUI
    /// diffing stay stable across re-derivations.
    var videoClips: [VideoClip] {
        storyboardPanels
            .sorted { $0.number < $1.number }
            .map { panel in
                VideoClip(
                    id: panel.id,
                    number: panel.number,
                    title: clipTitle(for: panel),
                    sceneNumber: sceneNumber(forBreakdown: panel.sceneBreakdownID),
                    duration: panel.duration,
                    motion: panel.clipMotion,
                    gradientSeed: panel.number,
                    isApproved: panel.clipApproved,
                    keyframeCount: panel.frameIDs.count,
                    sourceFrames: panel.frameIDs
                )
            }
    }

    func setClipMotion(_ motion: MotionIntensity, clipID: UUID) {
        mutatePanel(id: clipID) { $0.clipMotion = motion }
    }

    func setClipDuration(_ duration: Double, clipID: UUID) {
        mutatePanel(id: clipID) { $0.duration = max(0.5, duration) }
    }

    func toggleClipApproval(clipID: UUID) {
        mutatePanel(id: clipID) { $0.clipApproved.toggle() }
    }

    func toggleCutApplied(cutID: UUID) {
        guard let i = cutSuggestions.firstIndex(where: { $0.id == cutID }) else { return }
        cutSuggestions[i].applied.toggle()
    }

    private func clipTitle(for panel: StoryboardPanel) -> String {
        let trimmed = panel.actionNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Shot \(panel.number)" }
        if trimmed.count <= 48 { return trimmed }
        let cut = trimmed.prefix(45)
        return cut + "…"
    }

    private func sceneNumber(forBreakdown id: UUID?) -> Int {
        guard let id,
              let scene = bible.sceneBreakdowns.first(where: { $0.id == id }) else {
            return 0
        }
        return scene.number
    }
}
