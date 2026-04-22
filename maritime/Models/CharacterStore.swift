import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

// MARK: - Shared Character Store
//
// Single source of truth for finalized characters so Character Lab
// and Scene Builder stay in sync. Pre-seeded with the Library characters
// so Scene Builder has draggable characters on launch.

@MainActor
final class CharacterStore: ObservableObject {
    static let shared = CharacterStore()

    @Published var characters: [LabCharacter]

    private init() {
        // Seed with the library characters (Elena, Marcus) so Scene Builder
        // has draggable finalized characters immediately.
        self.characters = CharacterLabSamples.libraryCharacters
    }

    /// All finalized characters across personal + library
    var finalizedCharacters: [LabCharacter] {
        characters.filter { $0.isFinalized }
    }

    func character(id: UUID) -> LabCharacter? {
        characters.first(where: { $0.id == id })
    }

    func upsert(_ character: LabCharacter) {
        if let idx = characters.firstIndex(where: { $0.id == character.id }) {
            characters[idx] = character
        } else {
            characters.append(character)
        }
    }

    func upsertAll(_ list: [LabCharacter]) {
        for c in list { upsert(c) }
    }
}

// MARK: - Transferable Payload

/// Lightweight payload used during drag-and-drop. We only serialize the
/// UUID; the Scene Builder looks up the full character from CharacterStore.
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
