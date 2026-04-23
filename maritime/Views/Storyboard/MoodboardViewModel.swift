import SwiftUI
import Combine

// MARK: - Moodboard View Model
//
// Owns transient canvas state: which item is selected, whether a drag is in
// flight, and the active left-rail section. All persistent mutations go back
// through MovieBlazeProject so the document dirties.

@MainActor
final class MoodboardViewModel: ObservableObject {

    enum RailSection: String, CaseIterable, Identifiable {
        case setPieces, characters, colors, notes
        var id: String { rawValue }
        var title: String {
            switch self {
            case .setPieces:  return "Set Pieces"
            case .characters: return "Characters"
            case .colors:     return "Colors"
            case .notes:      return "Notes"
            }
        }
        var icon: String {
            switch self {
            case .setPieces:  return "cube.transparent.fill"
            case .characters: return "person.crop.artframe"
            case .colors:     return "paintpalette.fill"
            case .notes:      return "note.text"
            }
        }
    }

    @Published var selectedItemID: UUID?
    @Published var railCollapsed = false
    @Published var activeRail: RailSection = .setPieces

    /// 8px grid resolution expressed as a fraction of a 1000pt canvas for
    /// both axes. Canvases render at arbitrary sizes so snap happens against
    /// the ratio.
    let gridStep: Double = 0.02

    let project: MovieBlazeProject

    init(project: MovieBlazeProject) {
        self.project = project
    }

    // MARK: Derived

    var items: [MoodboardItem] {
        project.moodboard.items.sorted(by: { $0.zOrder < $1.zOrder })
    }

    var snapOn: Bool { project.moodboard.snapToGrid }

    // MARK: Selection

    func select(_ id: UUID?) {
        selectedItemID = id
        if let id { project.bringMoodboardItemToFront(id: id) }
    }

    // MARK: Item add

    func addSetPieceRef(_ piece: SetPiece) {
        project.addMoodboardItem(
            MoodboardItem(
                kind: .setPieceRef,
                refID: piece.id,
                xRatio: nextPlacement().x,
                yRatio: nextPlacement().y
            )
        )
    }

    func addCharacterRef(_ character: LabCharacter) {
        project.addMoodboardItem(
            MoodboardItem(
                kind: .characterRef,
                refID: character.id,
                xRatio: nextPlacement().x,
                yRatio: nextPlacement().y
            )
        )
    }

    func addColorSwatch(_ color: Color) {
        project.addMoodboardItem(
            MoodboardItem(
                kind: .colorSwatch,
                swatchColor: color,
                xRatio: nextPlacement().x,
                yRatio: nextPlacement().y
            )
        )
    }

    func addNote(_ text: String = "New note") {
        project.addMoodboardItem(
            MoodboardItem(
                kind: .note,
                noteText: text,
                xRatio: nextPlacement().x,
                yRatio: nextPlacement().y
            )
        )
    }

    func addReferenceImage(_ data: Data) {
        project.addMoodboardItem(
            MoodboardItem(
                kind: .referenceImage,
                imageData: data,
                xRatio: nextPlacement().x,
                yRatio: nextPlacement().y
            )
        )
    }

    // MARK: Item update

    func move(id: UUID, to point: CGPoint, canvas: CGSize) {
        guard canvas.width > 0, canvas.height > 0 else { return }
        let rawX = Double(point.x / canvas.width)
        let rawY = Double(point.y / canvas.height)
        let snapped = applySnap(x: rawX, y: rawY)
        project.mutateMoodboardItem(id: id) {
            $0.xRatio = max(0.02, min(0.98, snapped.x))
            $0.yRatio = max(0.02, min(0.98, snapped.y))
        }
    }

    func updateNoteText(id: UUID, text: String) {
        project.mutateMoodboardItem(id: id) { $0.noteText = text }
    }

    func delete(id: UUID) {
        if selectedItemID == id { selectedItemID = nil }
        project.removeMoodboardItem(id: id)
    }

    func deleteSelected() {
        guard let id = selectedItemID else { return }
        delete(id: id)
    }

    func setSnap(_ on: Bool) {
        project.setMoodboardSnap(on)
    }

    func updateTitle(_ title: String) {
        project.updateMoodboardTitle(title)
    }

    // MARK: Helpers

    func applySnap(x: Double, y: Double) -> (x: Double, y: Double) {
        guard snapOn else { return (x, y) }
        let snapX = (x / gridStep).rounded() * gridStep
        let snapY = (y / gridStep).rounded() * gridStep
        return (snapX, snapY)
    }

    /// Pick an unused-ish spot when the user taps "add" without a canvas drop.
    private func nextPlacement() -> (x: Double, y: Double) {
        let existing = project.moodboard.items.count
        let col = existing % 4
        let row = (existing / 4) % 4
        return (0.22 + Double(col) * 0.18, 0.22 + Double(row) * 0.18)
    }
}
