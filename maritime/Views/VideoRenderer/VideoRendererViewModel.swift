import SwiftUI
import Combine

// MARK: - Video Renderer view model
//
// Binds the renderer to the open MovieBlazeProject. Clip list is derived from
// project.storyboardPanels (one shot → one VideoClip), and per-clip mutations
// write back to the panel via VideoStore helpers, so Storyboard, Frame Builder,
// and the renderer all stay in lockstep. Each panel's frameIDs are the
// keyframes the motion model interpolates between. Cuts live on the project
// document. Local-only state — selection, playhead, transient render progress,
// panel collapse — stays on the view model.

@MainActor
final class VideoRendererViewModel: ObservableObject {
    @Published var selectedClipID: UUID?
    @Published var playheadSeconds: Double = 0
    @Published var isRendering = false
    @Published var renderProgress: Double = 0
    @Published var inspectorCollapsed = false

    private let project: MovieBlazeProject
    private var cancellables: Set<AnyCancellable> = []

    init(project: MovieBlazeProject) {
        self.project = project
        selectedClipID = project.videoClips.first?.id
        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: Derived state

    var clips: [VideoClip] { project.videoClips }
    var cuts: [CutSuggestion] { project.cutSuggestions }

    var projectTitle: String {
        project.bible.projectTitle
    }

    var selectedClip: VideoClip? {
        clips.first(where: { $0.id == selectedClipID })
    }

    var totalDuration: Double {
        clips.reduce(0) { $0 + $1.duration }
    }

    var approvalPercent: Double {
        guard !clips.isEmpty else { return 0 }
        return Double(clips.filter(\.isApproved).count) / Double(clips.count)
    }

    // MARK: Mutations

    func setActive(_ clip: VideoClip) {
        selectedClipID = clip.id
        // Snap playhead to clip start
        var acc = 0.0
        for c in clips {
            if c.id == clip.id { playheadSeconds = acc; break }
            acc += c.duration
        }
    }

    func setMotion(_ motion: MotionIntensity, for clip: VideoClip) {
        project.setClipMotion(motion, clipID: clip.id)
    }

    func setDuration(_ duration: Double, for clip: VideoClip) {
        project.setClipDuration(duration, clipID: clip.id)
    }

    func toggleApproval(_ clip: VideoClip) {
        project.toggleClipApproval(clipID: clip.id)
    }

    func applyCut(_ cut: CutSuggestion) {
        project.toggleCutApplied(cutID: cut.id)
    }

    func render() {
        isRendering = true
        renderProgress = 0
        Task {
            for i in 1...20 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                renderProgress = Double(i) / 20.0
            }
            isRendering = false
        }
    }
}
