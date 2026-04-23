import SwiftUI
import Combine
import AppKit

// MARK: - Set Design View Model
//
// Owns UI state that isn't on the document: selection, an in-flight
// generation job tracked by pieceID, and the category filter applied to the
// sidebar. Writes all piece mutations back through MovieBlazeProject so the
// document becomes dirty and autosave picks them up.

@MainActor
final class SetDesignViewModel: ObservableObject {

    @Published var selectedPieceID: UUID?
    @Published var generatingPieceIDs: Set<UUID> = []
    @Published var categoryFilter: SetPieceCategory?
    @Published var sidebarCollapsed = false
    @Published var promptPanelCollapsed = false

    let project: MovieBlazeProject
    private let service: SetPieceGenerationService

    init(project: MovieBlazeProject,
         service: SetPieceGenerationService = StubSetPieceGenerationService()) {
        self.project = project
        self.service = service
        self.selectedPieceID = project.setPieces.first?.id
    }

    // MARK: Selection / filter

    var pieces: [SetPiece] { project.setPieces }

    var filteredPieces: [SetPiece] {
        guard let filter = categoryFilter else { return pieces }
        return pieces.filter { $0.category == filter }
    }

    var selectedPiece: SetPiece? {
        guard let id = selectedPieceID else { return nil }
        return project.setPieces.first(where: { $0.id == id })
    }

    func select(_ id: UUID) { selectedPieceID = id }

    // MARK: CRUD

    func createPiece(name: String = "New Set Piece",
                     category: SetPieceCategory = .prop) {
        let piece = SetPiece(name: name, category: category)
        project.addSetPiece(piece)
        selectedPieceID = piece.id
    }

    func deleteSelected() {
        guard let id = selectedPieceID else { return }
        project.removeSetPiece(id: id)
        generatingPieceIDs.remove(id)
        selectedPieceID = project.setPieces.first?.id
    }

    func updateName(_ name: String) {
        guard let id = selectedPieceID else { return }
        project.mutateSetPiece(id: id) { $0.name = name }
    }

    func updateDescription(_ text: String) {
        guard let id = selectedPieceID else { return }
        project.mutateSetPiece(id: id) { $0.description = text }
    }

    func updatePrompt(_ text: String) {
        guard let id = selectedPieceID else { return }
        project.mutateSetPiece(id: id) { $0.promptSeed = text }
    }

    func updateCategory(_ category: SetPieceCategory) {
        guard let id = selectedPieceID else { return }
        project.mutateSetPiece(id: id) { $0.category = category }
    }

    func updateTags(_ raw: String) {
        guard let id = selectedPieceID else { return }
        let tokens = raw
            .split(whereSeparator: { $0 == "," || $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        project.mutateSetPiece(id: id) { $0.tags = tokens }
    }

    // MARK: Reference image

    func attachReferenceImage(_ data: Data) {
        guard let id = selectedPieceID else { return }
        project.mutateSetPiece(id: id) { $0.referenceImageData = data }
    }

    func clearReferenceImage() {
        guard let id = selectedPieceID else { return }
        project.mutateSetPiece(id: id) { $0.referenceImageData = nil }
    }

    // MARK: Generation

    func isGenerating(_ pieceID: UUID) -> Bool {
        generatingPieceIDs.contains(pieceID)
    }

    func regenerate(_ piece: SetPiece) {
        guard !generatingPieceIDs.contains(piece.id) else { return }
        let request = SetPieceRenderRequest(
            pieceID: piece.id,
            prompt: piece.promptSeed,
            category: piece.category,
            referenceImage: piece.referenceImageData
        )
        generatingPieceIDs.insert(piece.id)
        Task { [service, project] in
            do {
                let data = try await service.generate(request: request)
                await MainActor.run {
                    project.mutateSetPiece(id: piece.id) { $0.generatedImageData = data }
                    generatingPieceIDs.remove(piece.id)
                }
            } catch {
                await MainActor.run {
                    generatingPieceIDs.remove(piece.id)
                }
            }
        }
    }
}
