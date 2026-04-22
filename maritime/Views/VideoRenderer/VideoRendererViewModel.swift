import SwiftUI
import Combine

@MainActor
final class VideoRendererViewModel: ObservableObject {
    @Published var clips: [VideoClip] = VideoRendererSamples.clips
    @Published var cuts: [CutSuggestion] = VideoRendererSamples.cuts
    @Published var selectedClipID: UUID?
    @Published var playheadSeconds: Double = 0
    @Published var isRendering = false
    @Published var renderProgress: Double = 0
    @Published var inspectorCollapsed = false
    @Published var projectTitle: String = "Neon Requiem"
    @Published var sequenceName: String = "Act I — Opening"

    init() {
        selectedClipID = clips.first?.id
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
        guard let idx = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[idx].motion = motion
    }

    func toggleApproval(_ clip: VideoClip) {
        guard let idx = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[idx].isApproved.toggle()
    }

    func applyCut(_ cut: CutSuggestion) {
        guard let idx = cuts.firstIndex(where: { $0.id == cut.id }) else { return }
        cuts[idx].applied.toggle()
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
