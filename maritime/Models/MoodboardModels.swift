import SwiftUI

// MARK: - Moodboard Models
//
// A project has exactly one moodboard. It hosts a free-form canvas of items
// drawn from four sources: set-piece references, character references,
// free-form reference images, color swatches, and notes. Item positions are
// stored as ratios (0…1) so the canvas can be any size without invalidating
// layouts on save/load.

enum MoodboardItemKind: String, Codable, CaseIterable, Hashable {
    case setPieceRef
    case characterRef
    case referenceImage
    case colorSwatch
    case note

    var title: String {
        switch self {
        case .setPieceRef:    return "Set Piece"
        case .characterRef:   return "Character"
        case .referenceImage: return "Image"
        case .colorSwatch:    return "Swatch"
        case .note:           return "Note"
        }
    }

    var icon: String {
        switch self {
        case .setPieceRef:    return "cube.transparent.fill"
        case .characterRef:   return "person.crop.artframe"
        case .referenceImage: return "photo.fill"
        case .colorSwatch:    return "paintpalette.fill"
        case .note:           return "note.text"
        }
    }
}

struct MoodboardItem: Identifiable, Hashable, Codable {
    let id: UUID
    var kind: MoodboardItemKind
    var refID: UUID?
    var imageData: Data?
    var swatchColor: Color?
    var noteText: String?

    /// Position relative to the canvas, 0…1.
    var xRatio: Double
    var yRatio: Double
    var scale: Double
    var rotation: Double
    var zOrder: Int

    init(id: UUID = UUID(),
         kind: MoodboardItemKind,
         refID: UUID? = nil,
         imageData: Data? = nil,
         swatchColor: Color? = nil,
         noteText: String? = nil,
         xRatio: Double = 0.5,
         yRatio: Double = 0.5,
         scale: Double = 1.0,
         rotation: Double = 0,
         zOrder: Int = 0) {
        self.id = id
        self.kind = kind
        self.refID = refID
        self.imageData = imageData
        self.swatchColor = swatchColor
        self.noteText = noteText
        self.xRatio = xRatio
        self.yRatio = yRatio
        self.scale = scale
        self.rotation = rotation
        self.zOrder = zOrder
    }
}

struct ProjectMoodboard: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var items: [MoodboardItem]
    var colorPalette: [Color]
    var snapToGrid: Bool
    var lastUpdated: Date

    init(id: UUID = UUID(),
         title: String = "Mood",
         items: [MoodboardItem] = [],
         colorPalette: [Color] = [],
         snapToGrid: Bool = true,
         lastUpdated: Date = Date()) {
        self.id = id
        self.title = title
        self.items = items
        self.colorPalette = colorPalette
        self.snapToGrid = snapToGrid
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Samples

enum MoodboardSamples {
    static let lanternKeeper: ProjectMoodboard = ProjectMoodboard(
        title: "Hearth & Silence",
        items: [
            MoodboardItem(
                kind: .colorSwatch,
                swatchColor: Color(red: 1.0, green: 0.72, blue: 0.29),
                xRatio: 0.18, yRatio: 0.22, zOrder: 1
            ),
            MoodboardItem(
                kind: .colorSwatch,
                swatchColor: Color(red: 0.22, green: 0.18, blue: 0.14),
                xRatio: 0.30, yRatio: 0.22, zOrder: 2
            ),
            MoodboardItem(
                kind: .colorSwatch,
                swatchColor: Color(red: 0.35, green: 0.65, blue: 0.75),
                xRatio: 0.42, yRatio: 0.22, zOrder: 3
            ),
            MoodboardItem(
                kind: .note,
                noteText: "Warm amber against cold slate. The lantern is always the only warm thing in the frame.",
                xRatio: 0.72, yRatio: 0.28, zOrder: 4
            ),
            MoodboardItem(
                kind: .note,
                noteText: "Silence as a character: wide empty compositions before every memory reveal.",
                xRatio: 0.74, yRatio: 0.70, zOrder: 5
            )
        ],
        colorPalette: [
            Color(red: 1.0, green: 0.72, blue: 0.29),
            Color(red: 0.22, green: 0.18, blue: 0.14),
            Color(red: 0.35, green: 0.65, blue: 0.75)
        ],
        snapToGrid: true
    )
}
