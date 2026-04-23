import SwiftUI

// MARK: - Set Design mutators
//
// Extensions on MovieBlazeProject for the flat setPieces list. Pieces are
// created on the fly, mutated in place while the user edits their prompt
// seed or reference image, and can be deleted independently — removal does
// not cascade into Moodboard or Scene Builder references.

@MainActor
extension MovieBlazeProject {

    func addSetPiece(_ piece: SetPiece) {
        setPieces.append(piece)
    }

    func updateSetPiece(_ piece: SetPiece) {
        guard let i = setPieces.firstIndex(where: { $0.id == piece.id }) else { return }
        var updated = piece
        updated.lastUpdated = Date()
        setPieces[i] = updated
    }

    func mutateSetPiece(id: UUID, _ block: (inout SetPiece) -> Void) {
        guard let i = setPieces.firstIndex(where: { $0.id == id }) else { return }
        block(&setPieces[i])
        setPieces[i].lastUpdated = Date()
    }

    func removeSetPiece(id: UUID) {
        setPieces.removeAll(where: { $0.id == id })
    }

    func setPiece(id: UUID) -> SetPiece? {
        setPieces.first(where: { $0.id == id })
    }
}
