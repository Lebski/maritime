import SwiftUI

struct TimelineView: View {
    @ObservedObject var vm: VideoRendererViewModel
    @EnvironmentObject var project: MovieBlazeProject

    private let pixelsPerSecond: CGFloat = 70
    private let trackHeight: CGFloat = 72

    private func panel(for clip: VideoClip) -> StoryboardPanel? {
        project.storyboardPanels.first(where: { $0.id == clip.id })
    }

    private func sketchImage(for clip: VideoClip) -> NSImage? {
        guard let assetID = panel(for: clip)?.pencilSketchAssetID,
              let data = project.assetImageData(for: assetID) else { return nil }
        return NSImage(data: data)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 6) {
                timeRuler
                clipTrack
                cutsTrack
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: totalWidth + 32)
        }
        .background(Theme.bgElevated)
    }

    private var totalWidth: CGFloat {
        max(600, CGFloat(vm.totalDuration) * pixelsPerSecond)
    }

    private var timeRuler: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { _ in
                let seconds = Int(vm.totalDuration.rounded(.up))
                ForEach(0...max(seconds, 10), id: \.self) { s in
                    let x = CGFloat(s) * pixelsPerSecond
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Theme.stroke)
                            .frame(width: 1, height: s % 5 == 0 ? 16 : 8)
                    }
                    .offset(x: x, y: 20 - (s % 5 == 0 ? 16 : 8))
                    if s % 5 == 0 {
                        Text("\(s)s")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                            .offset(x: x + 2, y: 0)
                    }
                }
                // Playhead
                Rectangle()
                    .fill(AppModule.videoRenderer.tint)
                    .frame(width: 1.5, height: 22)
                    .offset(x: CGFloat(vm.playheadSeconds) * pixelsPerSecond, y: 0)
            }
        }
        .frame(height: 20)
    }

    private var clipTrack: some View {
        HStack(spacing: 2) {
            ForEach(vm.clips) { clip in
                clipBlock(clip: clip)
            }
        }
        .frame(height: trackHeight)
    }

    private func clipBlock(clip: VideoClip) -> some View {
        let width = max(60, CGFloat(clip.duration) * pixelsPerSecond)
        let isActive = vm.selectedClipID == clip.id
        let sketch = sketchImage(for: clip)
        return Button(action: { vm.setActive(clip) }) {
            ZStack(alignment: .topLeading) {
                if let sketch {
                    Image(nsImage: sketch)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.black.opacity(0.15)],
                        startPoint: .top, endPoint: .center
                    )
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.7)],
                        startPoint: .center, endPoint: .bottom
                    )
                } else {
                    LinearGradient(colors: clip.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("#\(clip.number)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(.black.opacity(0.5))
                            .clipShape(Capsule())
                        if clip.keyframeCount > 1 {
                            HStack(spacing: 2) {
                                Image(systemName: "film.stack")
                                    .font(.system(size: 7, weight: .bold))
                                Text("\(clip.keyframeCount)")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Theme.teal.opacity(0.85))
                            .clipShape(Capsule())
                        }
                        Spacer()
                        Image(systemName: clip.motion.icon)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    HStack {
                        Text(clip.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        if clip.isApproved {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.lime)
                        }
                    }
                    Text(String(format: "%.1fs · %@", clip.duration, clip.motion.rawValue))
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(6)
            }
            .frame(width: width, height: trackHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isActive ? Color.white : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var cutsTrack: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(vm.clips) { clip in
                let width = max(60, CGFloat(clip.duration) * pixelsPerSecond)
                ZStack {
                    Rectangle().fill(Color.clear)
                    if let cut = vm.cuts.first(where: { $0.afterClipNumber == clip.number }) {
                        HStack(spacing: 4) {
                            Image(systemName: "scissors")
                                .font(.system(size: 8, weight: .bold))
                            Text(cut.priority.rawValue)
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundStyle(cut.priority.tint)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(cut.priority.tint.opacity(0.18))
                        .overlay(Capsule().stroke(cut.priority.tint.opacity(0.5), lineWidth: 1))
                        .clipShape(Capsule())
                        .offset(x: width / 2 - 2)
                    }
                }
                .frame(width: width, height: 22)
            }
        }
    }
}
