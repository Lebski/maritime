import SwiftUI
import AppKit

// MARK: - Set Piece Card
//
// Thumbnail card used in the Set Design sidebar. Shows the generated image
// when available; otherwise a tint-bathed category placeholder so the user
// can tell what kind of piece is there before generation completes.

struct SetPieceCard: View {
    let piece: SetPiece
    let isActive: Bool
    let isGenerating: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                thumbnail
                VStack(alignment: .leading, spacing: 3) {
                    Text(piece.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: piece.category.icon)
                            .font(.system(size: 9))
                            .foregroundStyle(piece.category.tint)
                        Text(piece.category.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                        if piece.hasReferenceImage {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.teal)
                                .help("Has reference image")
                        }
                    }
                }
                Spacer()
                if isGenerating {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Theme.coral)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? Theme.coral.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? Theme.coral.opacity(0.35) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: piece.primaryColors.isEmpty
                            ? [piece.category.tint.opacity(0.35), piece.category.tint.opacity(0.15)]
                            : piece.primaryColors.map { $0.opacity(0.45) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            if let data = piece.generatedImageData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: piece.category.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(piece.category.tint)
            }
        }
        .frame(width: 42, height: 42)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }
}
