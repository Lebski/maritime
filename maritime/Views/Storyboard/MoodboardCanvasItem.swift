import SwiftUI
import AppKit

// MARK: - Moodboard Canvas Item
//
// Renders one MoodboardItem on the canvas. The switch on kind is small
// enough that breaking each into its own view would just add indirection;
// the view body stays readable as one block.

struct MoodboardCanvasItem: View {
    let item: MoodboardItem
    let project: MovieBlazeProject
    let isSelected: Bool
    let onTap: () -> Void
    let onNoteEdit: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        content
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Theme.magenta)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: -6)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Theme.violet : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .setPieceRef:   setPieceCard
        case .characterRef:  characterCard
        case .colorSwatch:   swatchCard
        case .note:          noteCard
        case .referenceImage: referenceImageCard
        }
    }

    // MARK: Set Piece card

    @ViewBuilder
    private var setPieceCard: some View {
        let piece = item.refID.flatMap { id in project.setPieces.first(where: { $0.id == id }) }
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(piece?.category.tint.opacity(0.35) ?? Theme.coral.opacity(0.25))
                if let data = piece?.generatedImageData, let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else if let piece {
                    Image(systemName: piece.category.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(piece.category.tint)
                } else {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(width: 140, height: 100)
            if let piece {
                Text(piece.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
        }
        .padding(6)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: Character card

    @ViewBuilder
    private var characterCard: some View {
        let character = item.refID.flatMap { id in project.characters.first(where: { $0.id == id }) }
        let tint = character?.finalVariation?.accentColor ?? Theme.teal
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(tint.opacity(0.3))
                    .frame(width: 70, height: 70)
                if let name = character?.name {
                    Text(String(name.prefix(1)))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(tint)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            if let name = character?.name {
                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: Swatch card

    @ViewBuilder
    private var swatchCard: some View {
        let color = item.swatchColor ?? Color.gray
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
                .frame(width: 70, height: 70)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
        .padding(6)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: Note card

    @ViewBuilder
    private var noteCard: some View {
        let binding = Binding<String>(
            get: { item.noteText ?? "" },
            set: { onNoteEdit($0) }
        )
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "note.text")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.accent)
                Text("NOTE")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.accent)
            }
            TextEditor(text: binding)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(width: 160, height: 64)
        }
        .padding(10)
        .background(Theme.accent.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: Reference image card

    @ViewBuilder
    private var referenceImageCard: some View {
        ZStack {
            if let data = item.imageData, let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.card)
                    .frame(width: 140, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.textTertiary)
                    )
            }
        }
        .padding(4)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
