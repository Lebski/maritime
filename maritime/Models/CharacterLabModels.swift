import SwiftUI

// MARK: - Character Lab Models

enum CharacterSource {
    case storyForge, library, new
}

/// Where a character is in the portrait-generation pipeline.
enum CharacterLabPhase: String, Codable {
    case setup       // user is filling in description + Q&A
    case generating  // recraft-v4 call in flight
    case selecting   // grid of generated portraits, awaiting pick
    case finalized   // a portrait has been chosen; sheets can be generated
}

/// Optional guided-question answers. Each is free-form text, all skippable.
struct CharacterSetupAnswers: Codable, Hashable {
    var ageRange: String = ""
    var heightBuild: String = ""
    var hairColorStyle: String = ""
    var eyeColor: String = ""
    var skinTone: String = ""
    var facialFeatures: String = ""
    var facialHair: String = ""
    var distinguishing: String = ""
    var clothingStyle: String = ""

    var isEmpty: Bool {
        ageRange.isEmpty && heightBuild.isEmpty && hairColorStyle.isEmpty &&
        eyeColor.isEmpty && skinTone.isEmpty && facialFeatures.isEmpty &&
        facialHair.isEmpty && distinguishing.isEmpty && clothingStyle.isEmpty
    }

    /// Non-empty answers as comma-joinable prompt fragments, in display order.
    var promptFragments: [String] {
        var out: [String] = []
        let pairs: [(String, String)] = [
            (ageRange, "age"),
            (heightBuild, "build"),
            (hairColorStyle, "hair"),
            (eyeColor, "eye color"),
            (skinTone, "skin"),
            (facialFeatures, "facial features"),
            (facialHair, "facial hair"),
            (distinguishing, "distinguishing"),
            (clothingStyle, "wearing")
        ]
        for (value, _) in pairs {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { out.append(trimmed) }
        }
        return out
    }
}

/// A single recraft-v4 portrait result.
struct PortraitVariation: Identifiable, Hashable, Codable {
    let id: UUID
    let index: Int
    var imageData: Data
    var seed: Int?

    init(id: UUID = UUID(), index: Int, imageData: Data, seed: Int? = nil) {
        self.id = id
        self.index = index
        self.imageData = imageData
        self.seed = seed
    }
}

/// Tint/style hint shown in adjacent UI (Scene Builder, Moodboard, sidebar) when
/// the real portrait isn't available or appropriate. Auto-derived per character.
struct CharacterVariation: Identifiable, Hashable, Codable {
    let id: UUID
    let index: Int
    let label: String
    let age: String
    let style: String
    let accentColor: Color
    let gradientColors: [Color]
    var isSelected: Bool = false

    init(id: UUID = UUID(), index: Int, label: String, age: String, style: String,
         accentColor: Color, gradientColors: [Color], isSelected: Bool = false) {
        self.id = id
        self.index = index
        self.label = label
        self.age = age
        self.style = style
        self.accentColor = accentColor
        self.gradientColors = gradientColors
        self.isSelected = isSelected
    }
}

enum ReferenceSheetType: String, CaseIterable, Identifiable, Codable {
    case portrait, turnaround, fullBody, expressions, actionPoses
    var id: String { rawValue }

    var title: String {
        switch self {
        case .portrait:     return "Portrait"
        case .turnaround:   return "Head Turnaround"
        case .fullBody:     return "Full Body"
        case .expressions:  return "Expression Sheet"
        case .actionPoses:  return "Action Poses"
        }
    }

    var icon: String {
        switch self {
        case .portrait:     return "face.smiling"
        case .turnaround:   return "arrow.triangle.2.circlepath"
        case .fullBody:     return "figure.stand"
        case .expressions:  return "theatermasks.fill"
        case .actionPoses:  return "figure.run"
        }
    }

    var description: String {
        switch self {
        case .portrait:     return "Neutral 3/4 angle, even lighting"
        case .turnaround:   return "Front, 3/4, profile, 3/4 back, back"
        case .fullBody:     return "A-pose or relaxed standing"
        case .expressions:  return "Happy, sad, angry, surprised, neutral"
        case .actionPoses:  return "Walking, running, sitting, gesturing"
        }
    }
}

struct LabCharacter: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var role: String

    // Setup
    var setupAnswers: CharacterSetupAnswers = .init()
    var phase: CharacterLabPhase = .setup
    var portraitCount: Int = 10

    // Portraits
    var portraitVariations: [PortraitVariation] = []
    var selectedPortraitID: UUID? = nil

    // Reference sheets (real image bytes keyed by type)
    var sheetImages: [ReferenceSheetType: Data] = [:]

    // Display
    var finalVariation: CharacterVariation? = nil
    var isFinalized: Bool = false
    var costumes: [String] = ["Casual", "Formal", "Combat"]

    var selectedPortrait: PortraitVariation? {
        guard let id = selectedPortraitID else { return nil }
        return portraitVariations.first(where: { $0.id == id })
    }

    var generatedSheets: Set<ReferenceSheetType> {
        Set(sheetImages.keys)
    }

    /// Compact status label used in sidebars and home cards.
    var statusLabel: String {
        if isFinalized { return "Finalized" }
        switch phase {
        case .setup:      return "Setup"
        case .generating: return "Generating…"
        case .selecting:  return "Pick portrait"
        case .finalized:  return "Finalized"
        }
    }

    init(id: UUID = UUID(), name: String, description: String, role: String,
         setupAnswers: CharacterSetupAnswers = .init(),
         phase: CharacterLabPhase = .setup,
         portraitCount: Int = 10,
         portraitVariations: [PortraitVariation] = [],
         selectedPortraitID: UUID? = nil,
         sheetImages: [ReferenceSheetType: Data] = [:],
         finalVariation: CharacterVariation? = nil,
         isFinalized: Bool = false,
         costumes: [String] = ["Casual", "Formal", "Combat"]) {
        self.id = id
        self.name = name
        self.description = description
        self.role = role
        self.setupAnswers = setupAnswers
        self.phase = phase
        self.portraitCount = portraitCount
        self.portraitVariations = portraitVariations
        self.selectedPortraitID = selectedPortraitID
        self.sheetImages = sheetImages
        self.finalVariation = finalVariation
        self.isFinalized = isFinalized
        self.costumes = costumes
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, role
        case setupAnswers, phase, portraitCount
        case portraitVariations, selectedPortraitID
        case sheetImages
        case finalVariation, isFinalized, costumes
    }

    /// Older `.mblaze` files predate the portrait pipeline. Decode every new
    /// field with a default so existing projects keep loading.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.description = try c.decode(String.self, forKey: .description)
        self.role = try c.decode(String.self, forKey: .role)
        self.setupAnswers = try c.decodeIfPresent(CharacterSetupAnswers.self, forKey: .setupAnswers) ?? .init()
        self.phase = try c.decodeIfPresent(CharacterLabPhase.self, forKey: .phase) ?? .setup
        self.portraitCount = try c.decodeIfPresent(Int.self, forKey: .portraitCount) ?? 10
        self.portraitVariations = try c.decodeIfPresent([PortraitVariation].self, forKey: .portraitVariations) ?? []
        self.selectedPortraitID = try c.decodeIfPresent(UUID.self, forKey: .selectedPortraitID)
        self.sheetImages = try c.decodeIfPresent([ReferenceSheetType: Data].self, forKey: .sheetImages) ?? [:]
        self.finalVariation = try c.decodeIfPresent(CharacterVariation.self, forKey: .finalVariation)
        self.isFinalized = try c.decodeIfPresent(Bool.self, forKey: .isFinalized) ?? false
        self.costumes = try c.decodeIfPresent([String].self, forKey: .costumes) ?? ["Casual", "Formal", "Combat"]
    }
}

// MARK: - Display tints

/// Deterministic tint/gradient for a character. Used as a fallback when no
/// portrait is selected yet, and to populate `finalVariation` when one is.
enum CharacterTint {
    private static let palette: [(accent: Color, gradient: [Color])] = [
        (Color(red: 0.95, green: 0.45, blue: 0.25),
         [Color(red: 0.55, green: 0.15, blue: 0.10), Color(red: 0.95, green: 0.45, blue: 0.25)]),
        (Color(red: 0.28, green: 0.78, blue: 0.82),
         [Color(red: 0.10, green: 0.30, blue: 0.50), Color(red: 0.28, green: 0.78, blue: 0.82)]),
        (Color(red: 0.62, green: 0.88, blue: 0.42),
         [Color(red: 0.15, green: 0.30, blue: 0.12), Color(red: 0.62, green: 0.88, blue: 0.42)]),
        (Color(red: 0.56, green: 0.43, blue: 0.95),
         [Color(red: 0.18, green: 0.12, blue: 0.40), Color(red: 0.56, green: 0.43, blue: 0.95)]),
        (Color(red: 0.92, green: 0.35, blue: 0.62),
         [Color(red: 0.35, green: 0.10, blue: 0.25), Color(red: 0.92, green: 0.35, blue: 0.62)]),
        (Color(red: 1.0, green: 0.72, blue: 0.29),
         [Color(red: 0.35, green: 0.25, blue: 0.08), Color(red: 1.0, green: 0.72, blue: 0.29)])
    ]

    static func variation(for id: UUID, name: String, role: String, style: String) -> CharacterVariation {
        let hash = abs(id.uuidString.hashValue)
        let pick = palette[hash % palette.count]
        return CharacterVariation(
            id: UUID(),
            index: 0,
            label: name,
            age: role,
            style: style.isEmpty ? "—" : style,
            accentColor: pick.accent,
            gradientColors: pick.gradient
        )
    }
}

// MARK: - Sample library

enum CharacterLabSamples {
    /// Sidebar "Library" placeholders — finalized look, no real portrait images.
    /// These exist purely so the Library sidebar isn't empty; they cannot be
    /// dragged into Scene Builder as real assets.
    static let libraryCharacters: [LabCharacter] = {
        var elena = LabCharacter(name: "Elena",
                                 description: "30-year-old woman, sharp features, dark curly hair",
                                 role: "Protagonist",
                                 isFinalized: true)
        elena.finalVariation = CharacterTint.variation(for: elena.id, name: elena.name,
                                                       role: elena.role,
                                                       style: "Composed · high cheekbones · sharp eyes")
        var marcus = LabCharacter(name: "Marcus",
                                  description: "Weathered detective, mid-50s, commanding presence",
                                  role: "Antagonist",
                                  isFinalized: true)
        marcus.finalVariation = CharacterTint.variation(for: marcus.id, name: marcus.name,
                                                        role: marcus.role,
                                                        style: "Angular jaw · scar · trench coat")
        return [elena, marcus]
    }()
}
