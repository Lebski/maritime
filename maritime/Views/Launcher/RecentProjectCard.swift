import AppKit
import SwiftUI

struct RecentProjectCard: View {
    let url: URL
    let action: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                poster
                info
            }
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isHovering ? Theme.accent.opacity(0.55) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plainSolid)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
    }

    private var poster: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: Self.gradientColors(for: url),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "film.stack.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(12)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(url.deletingPathExtension().lastPathComponent)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(parentLabel)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var parentLabel: String {
        let parent = url.deletingLastPathComponent().lastPathComponent
        return parent.isEmpty ? url.path : parent
    }

    private static let palette: [[Color]] = [
        [Theme.accent, Theme.coral],
        [Theme.magenta, Theme.violet],
        [Theme.teal, Theme.violet],
        [Theme.violet, Theme.magenta],
        [Theme.coral, Theme.magenta],
        [Theme.lime, Theme.teal]
    ]

    private static func gradientColors(for url: URL) -> [Color] {
        let key = url.path
        var hash: UInt64 = 1469598103934665603
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        let index = Int(hash % UInt64(palette.count))
        return palette[index]
    }
}
