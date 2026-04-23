import SwiftUI

// MARK: - Set Design Models
//
// A SetPiece is a single AI-generated object or environment fragment — a
// chair, a castle tower, a shed, a car. Pieces are project-scoped and feed
// two downstream modules: the Moodboard (as visual ingredients) and Scene
// Builder (as props the user can drop into a scene). Each piece carries an
// optional reference image for image-to-image generation, and an optional
// generated output blob produced by the image generation service.

enum SetPieceCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case furniture
    case architecture
    case prop
    case vegetation
    case vehicle
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .furniture:    return "Furniture"
        case .architecture: return "Architecture"
        case .prop:         return "Prop"
        case .vegetation:   return "Vegetation"
        case .vehicle:      return "Vehicle"
        case .other:        return "Other"
        }
    }

    var icon: String {
        switch self {
        case .furniture:    return "chair.lounge.fill"
        case .architecture: return "building.columns.fill"
        case .prop:         return "cube.fill"
        case .vegetation:   return "leaf.fill"
        case .vehicle:      return "car.fill"
        case .other:        return "questionmark.diamond.fill"
        }
    }

    var tint: Color {
        switch self {
        case .furniture:    return Theme.coral
        case .architecture: return Theme.accent
        case .prop:         return Theme.violet
        case .vegetation:   return Theme.lime
        case .vehicle:      return Theme.teal
        case .other:        return Color.white.opacity(0.6)
        }
    }
}

struct SetPiece: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var category: SetPieceCategory
    var description: String
    var promptSeed: String
    var referenceImageData: Data?
    var generatedImageData: Data?
    var tags: [String]
    var primaryColors: [Color]
    var createdAt: Date
    var lastUpdated: Date

    init(id: UUID = UUID(),
         name: String,
         category: SetPieceCategory = .prop,
         description: String = "",
         promptSeed: String = "",
         referenceImageData: Data? = nil,
         generatedImageData: Data? = nil,
         tags: [String] = [],
         primaryColors: [Color] = [Theme.coral, Theme.accent],
         createdAt: Date = Date(),
         lastUpdated: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.promptSeed = promptSeed
        self.referenceImageData = referenceImageData
        self.generatedImageData = generatedImageData
        self.tags = tags
        self.primaryColors = primaryColors
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }

    var hasGeneratedImage: Bool { generatedImageData != nil }
    var hasReferenceImage: Bool { referenceImageData != nil }
}

// MARK: - Image generation service

/// Input for a set-piece generation request. Wraps the fields the service
/// actually needs so the UI doesn't have to pass an entire SetPiece (and so
/// the payload can evolve independently of the document model).
struct SetPieceRenderRequest: Sendable {
    var pieceID: UUID
    var prompt: String
    var category: SetPieceCategory
    var referenceImage: Data?
}

protocol SetPieceGenerationService: Sendable {
    func generate(request: SetPieceRenderRequest) async throws -> Data
}

struct StubSetPieceGenerationService: SetPieceGenerationService {
    var simulatedLatencySeconds: Double = 1.8

    func generate(request: SetPieceRenderRequest) async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatencySeconds * 1_000_000_000))
        return Data()
    }
}

// MARK: - Samples

enum SetDesignSamples {
    static let lanternKeeperPieces: [SetPiece] = [
        SetPiece(
            name: "Weathered Oak Lantern",
            category: .prop,
            description: "Hand-forged iron cage, oak handle worn smooth. The flame inside is the story's anchor.",
            promptSeed: "A weathered oak and black iron hand lantern, warm amber flame inside, grain and patina visible, soft studio lighting, white backdrop.",
            tags: ["lantern", "hero prop", "iron", "oak"],
            primaryColors: [Color(red: 0.35, green: 0.15, blue: 0.05),
                            Color(red: 1.0, green: 0.72, blue: 0.29)]
        ),
        SetPiece(
            name: "Stone Cottage Interior",
            category: .architecture,
            description: "Rough-hewn stone walls, low beams, a single shuttered window facing the valley.",
            promptSeed: "A rough stone cottage interior with low wooden beams, whitewashed walls, a single shuttered window, candlelight, cozy and lived-in.",
            tags: ["cottage", "stone", "rural"],
            primaryColors: [Color(red: 0.22, green: 0.18, blue: 0.14),
                            Color(red: 0.85, green: 0.72, blue: 0.55)]
        ),
        SetPiece(
            name: "Valley Well",
            category: .architecture,
            description: "Circular stone well with a rope-and-bucket windlass, worn smooth by generations.",
            promptSeed: "A medieval village stone well with a wooden rope windlass, bucket hanging, weathered stone rim, highland valley landscape, overcast daylight.",
            tags: ["well", "village", "stone"],
            primaryColors: [Color(red: 0.28, green: 0.32, blue: 0.35),
                            Color(red: 0.65, green: 0.72, blue: 0.75)]
        ),
        SetPiece(
            name: "Wooden Ferry",
            category: .vehicle,
            description: "A small flat-bottomed ferry, painted rails worn bare, meant for still water crossings.",
            promptSeed: "A small wooden flat-bottomed ferry boat on calm water at dusk, worn painted rails, lantern hung at the prow, atmospheric mist.",
            tags: ["ferry", "boat", "wooden"],
            primaryColors: [Color(red: 0.20, green: 0.14, blue: 0.10),
                            Color(red: 0.45, green: 0.38, blue: 0.55)]
        )
    ]
}
