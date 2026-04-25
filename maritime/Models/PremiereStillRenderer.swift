import SwiftUI
import AppKit

// MARK: - Premiere placeholder still renderer
//
// Each VideoClip becomes a single PNG (gradient + scene title + duration
// chip) sized to the sequence resolution. The XML serializer references
// these via <pathurl> so Premiere shows a populated timeline instead of
// "media offline" cards.

@MainActor
struct PremiereStillRenderer {

    /// Render each clip to `<folder>/clip-NNN.png`, where NNN is the clip
    /// number zero-padded. Returns a map from VideoClip.id to the on-disk
    /// URL so the XML serializer can reference each file by clip.
    static func renderClips(
        _ clips: [VideoClip],
        size: CGSize,
        into folder: URL
    ) throws -> [UUID: URL] {
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        var map: [UUID: URL] = [:]
        for clip in clips {
            let view = ClipStillView(clip: clip, size: size)
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = ProposedViewSize(size)
            renderer.scale = 1

            guard
                let nsImage = renderer.nsImage,
                let tiff = nsImage.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiff),
                let png = bitmap.representation(using: .png, properties: [:])
            else {
                throw NSError(
                    domain: "PremiereStillRenderer",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Failed to render PNG for clip \(clip.number)."]
                )
            }

            let filename = String(format: "clip-%03d.png", clip.number)
            let url = folder.appendingPathComponent(filename)
            try png.write(to: url, options: .atomic)
            map[clip.id] = url
        }
        return map
    }
}

private struct ClipStillView: View {
    let clip: VideoClip
    let size: CGSize

    var body: some View {
        let titleSize = max(48, size.height * 0.08)
        let labelSize = max(20, size.height * 0.035)
        let metaSize  = max(16, size.height * 0.025)
        let pad       = max(40, size.height * 0.06)

        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: clip.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 14) {
                Text("SCENE \(clip.sceneNumber)")
                    .font(.system(size: labelSize, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.75))

                Text(clip.title)
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 10) {
                    Image(systemName: clip.motion.icon)
                    Text(clip.motion.rawValue)
                    Text("·")
                    Text(String(format: "%.1fs", clip.duration))
                }
                .font(.system(size: metaSize, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            }
            .padding(pad)
        }
        .frame(width: size.width, height: size.height)
    }
}
