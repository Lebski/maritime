import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

// MARK: - Character (LabCharacter) mutators
//
// Extensions on MovieBlazeProject that replace the old singleton
// CharacterStore. Also hosts the drag-and-drop transferable payload
// and its UTType registration.

@MainActor
extension MovieBlazeProject {

    var finalizedCharacters: [LabCharacter] {
        characters.filter(\.isFinalized)
    }

    func character(id: UUID) -> LabCharacter? {
        characters.first(where: { $0.id == id })
    }

    func upsertCharacter(_ character: LabCharacter) {
        if let idx = characters.firstIndex(where: { $0.id == character.id }) {
            characters[idx] = character
        } else {
            characters.append(character)
        }
    }

    func upsertAllCharacters(_ list: [LabCharacter]) {
        for c in list { upsertCharacter(c) }
    }
}

// MARK: - Transferable Payload

/// Lightweight payload used during drag-and-drop. We only serialize the
/// UUID; the Scene Builder looks up the full character from the active
/// MovieBlazeProject.
struct DraggableCharacter: Codable, Transferable {
    let id: UUID
    let name: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .movieBlazeCharacter)
        ProxyRepresentation(exporting: \.name) // fallback for external targets
    }
}

extension UTType {
    static let movieBlazeCharacter = UTType(exportedAs: "com.movieblaze.character")
}
