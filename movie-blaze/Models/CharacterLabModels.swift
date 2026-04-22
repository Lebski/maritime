import SwiftUI

// MARK: - Character Lab Models

enum CharacterSource {
    case storyForge, library, new
}

enum RefinementRound: Int, CaseIterable {
    case broad = 1, focused = 2, polish = 3

    var title: String {
        switch self {
        case .broad:   return "Round 1 — Broad Exploration"
        case .focused: return "Round 2 — Focused Refinement"
        case .polish:  return "Round 3 — Final Polish"
        }
    }

    var subtitle: String {
        switch self {
        case .broad:   return "8–12 diverse interpretations. Pick your favourites."
        case .focused: return "4–6 variations based on your picks. Narrow it down."
        case .polish:  return "2–3 near-final options. Approve or tweak."
        }
    }

    var count: Int {
        switch self {
        case .broad: return 10
        case .focused: return 6
        case .polish: return 3
        }
    }

    var maxSelections: Int {
        switch self {
        case .broad: return 3
        case .focused: return 2
        case .polish: return 1
        }
    }
}

enum ReferenceSheetType: String, CaseIterable, Identifiable {
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

struct CharacterVariation: Identifiable, Hashable {
    let id = UUID()
    let index: Int
    let label: String
    let age: String
    let style: String
    let accentColor: Color
    let gradientColors: [Color]
    var isSelected: Bool = false
}

struct LabCharacter: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var role: String
    var currentRound: RefinementRound = .broad
    var selectedVariations: [CharacterVariation] = []
    var finalVariation: CharacterVariation? = nil
    var isFinalized: Bool = false
    var generatedSheets: Set<ReferenceSheetType> = []
    var costumes: [String] = ["Casual", "Formal", "Combat"]
}

// MARK: - Sample Variations

enum CharacterLabSamples {
    static let broadVariations: [CharacterVariation] = [
        .init(index: 0, label: "The Noir Detective", age: "Late 30s", style: "Weathered, brooding, trench coat",
              accentColor: Color(red: 0.95, green: 0.45, blue: 0.25),
              gradientColors: [Color(red: 0.55, green: 0.15, blue: 0.10), Color(red: 0.95, green: 0.45, blue: 0.25)]),
        .init(index: 1, label: "The Idealist", age: "Mid 20s", style: "Clean-cut, earnest, bright eyes",
              accentColor: Color(red: 0.28, green: 0.78, blue: 0.82),
              gradientColors: [Color(red: 0.10, green: 0.30, blue: 0.50), Color(red: 0.28, green: 0.78, blue: 0.82)]),
        .init(index: 2, label: "The Survivor", age: "Early 40s", style: "Practical, scarred, intense gaze",
              accentColor: Color(red: 0.62, green: 0.88, blue: 0.42),
              gradientColors: [Color(red: 0.15, green: 0.30, blue: 0.12), Color(red: 0.62, green: 0.88, blue: 0.42)]),
        .init(index: 3, label: "The Scholar", age: "50s", style: "Spectacled, thoughtful, dishevelled",
              accentColor: Color(red: 0.56, green: 0.43, blue: 0.95),
              gradientColors: [Color(red: 0.18, green: 0.12, blue: 0.40), Color(red: 0.56, green: 0.43, blue: 0.95)]),
        .init(index: 4, label: "The Outsider", age: "Late 20s", style: "Androgynous, sharp features, minimalist",
              accentColor: Color(red: 0.92, green: 0.35, blue: 0.62),
              gradientColors: [Color(red: 0.35, green: 0.10, blue: 0.25), Color(red: 0.92, green: 0.35, blue: 0.62)]),
        .init(index: 5, label: "The Elder", age: "Late 60s", style: "Distinguished, silver hair, calm authority",
              accentColor: Color(red: 1.0, green: 0.72, blue: 0.29),
              gradientColors: [Color(red: 0.35, green: 0.25, blue: 0.08), Color(red: 1.0, green: 0.72, blue: 0.29)]),
        .init(index: 6, label: "The Rebel", age: "Early 20s", style: "Edgy, asymmetric hair, defiant posture",
              accentColor: Color(red: 0.95, green: 0.45, blue: 0.25),
              gradientColors: [Color(red: 0.40, green: 0.08, blue: 0.12), Color(red: 0.95, green: 0.45, blue: 0.25)]),
        .init(index: 7, label: "The Ghost", age: "Ageless", style: "Ethereal, pale, barely-there presence",
              accentColor: Color.white.opacity(0.7),
              gradientColors: [Color(red: 0.15, green: 0.15, blue: 0.25), Color(red: 0.55, green: 0.55, blue: 0.75)]),
        .init(index: 8, label: "The Protector", age: "Mid 30s", style: "Broad-shouldered, steady eyes, strong jaw",
              accentColor: Color(red: 0.28, green: 0.78, blue: 0.82),
              gradientColors: [Color(red: 0.08, green: 0.25, blue: 0.38), Color(red: 0.28, green: 0.78, blue: 0.82)]),
        .init(index: 9, label: "The Visionary", age: "40s", style: "Eccentric, restless energy, creative flair",
              accentColor: Color(red: 0.56, green: 0.43, blue: 0.95),
              gradientColors: [Color(red: 0.22, green: 0.08, blue: 0.45), Color(red: 0.56, green: 0.43, blue: 0.95)])
    ]

    static let focusedVariations: [CharacterVariation] = [
        .init(index: 0, label: "Variant A — Hard Features", age: "Late 30s", style: "Angular jaw, deep-set eyes, scar above brow",
              accentColor: Color(red: 0.95, green: 0.45, blue: 0.25),
              gradientColors: [Color(red: 0.50, green: 0.12, blue: 0.08), Color(red: 0.95, green: 0.45, blue: 0.25)]),
        .init(index: 1, label: "Variant B — Soft Features", age: "Late 30s", style: "Rounded face, warm eyes, approachable",
              accentColor: Color(red: 1.0, green: 0.72, blue: 0.29),
              gradientColors: [Color(red: 0.40, green: 0.28, blue: 0.05), Color(red: 1.0, green: 0.72, blue: 0.29)]),
        .init(index: 2, label: "Variant C — Intense Gaze", age: "Late 30s", style: "Piercing eyes, high cheekbones, guarded",
              accentColor: Color(red: 0.92, green: 0.35, blue: 0.62),
              gradientColors: [Color(red: 0.38, green: 0.08, blue: 0.22), Color(red: 0.92, green: 0.35, blue: 0.62)]),
        .init(index: 3, label: "Variant D — Weathered", age: "Late 30s", style: "Lines from sun & stress, unshaven, tired but sharp",
              accentColor: Color(red: 0.62, green: 0.88, blue: 0.42),
              gradientColors: [Color(red: 0.18, green: 0.32, blue: 0.10), Color(red: 0.62, green: 0.88, blue: 0.42)]),
        .init(index: 4, label: "Variant E — Composed", age: "Late 30s", style: "Controlled expression, precise appearance, cold",
              accentColor: Color(red: 0.56, green: 0.43, blue: 0.95),
              gradientColors: [Color(red: 0.18, green: 0.12, blue: 0.42), Color(red: 0.56, green: 0.43, blue: 0.95)]),
        .init(index: 5, label: "Variant F — World-Weary", age: "Late 30s", style: "Heavy shoulders, knowing smile, seen too much",
              accentColor: Color(red: 0.28, green: 0.78, blue: 0.82),
              gradientColors: [Color(red: 0.08, green: 0.22, blue: 0.32), Color(red: 0.28, green: 0.78, blue: 0.82)])
    ]

    static let polishVariations: [CharacterVariation] = [
        .init(index: 0, label: "Final — Option 1", age: "Late 30s", style: "Angular jaw · scar · trench coat · dark curly hair",
              accentColor: Color(red: 0.95, green: 0.45, blue: 0.25),
              gradientColors: [Color(red: 0.55, green: 0.15, blue: 0.10), Color(red: 0.95, green: 0.45, blue: 0.25)]),
        .init(index: 1, label: "Final — Option 2", age: "Late 30s", style: "Soft features · warm tone · slightly dishevelled",
              accentColor: Color(red: 1.0, green: 0.72, blue: 0.29),
              gradientColors: [Color(red: 0.40, green: 0.25, blue: 0.05), Color(red: 1.0, green: 0.72, blue: 0.29)]),
        .init(index: 2, label: "Final — Option 3", age: "Late 30s", style: "Composed · high cheekbones · sharp eyes · minimal",
              accentColor: Color(red: 0.92, green: 0.35, blue: 0.62),
              gradientColors: [Color(red: 0.40, green: 0.08, blue: 0.22), Color(red: 0.92, green: 0.35, blue: 0.62)])
    ]

    static let libraryCharacters: [LabCharacter] = {
        var elena = LabCharacter(name: "Elena", description: "30-year-old woman, sharp features, dark curly hair", role: "Protagonist")
        elena.isFinalized = true
        elena.finalVariation = polishVariations[2]
        elena.generatedSheets = Set(ReferenceSheetType.allCases)
        var marcus = LabCharacter(name: "Marcus", description: "Weathered detective, mid-50s, commanding presence", role: "Antagonist")
        marcus.isFinalized = true
        marcus.finalVariation = polishVariations[0]
        marcus.generatedSheets = [.portrait, .fullBody, .turnaround]
        return [elena, marcus]
    }()
}
