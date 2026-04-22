import SwiftUI

// MARK: - Asset Kind

enum AssetKind: String, CaseIterable, Identifiable {
    case character = "Characters"
    case prop = "Props"
    case background = "Backgrounds"
    case audio = "Audio"
    case reference = "References"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .character: return "person.crop.rectangle.fill"
        case .prop: return "shippingbox.fill"
        case .background: return "photo.fill"
        case .audio: return "waveform"
        case .reference: return "photo.on.rectangle.angled"
        }
    }

    var tint: Color {
        switch self {
        case .character: return Theme.teal
        case .prop: return Theme.accent
        case .background: return Theme.violet
        case .audio: return Theme.lime
        case .reference: return Theme.magenta
        }
    }
}

// MARK: - Asset

struct Asset: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var kind: AssetKind
    var tags: [String]
    var versions: Int
    var favorited: Bool
    var linkedProjects: [String]
    var updatedLabel: String
    var gradientSeed: Int

    var gradientColors: [Color] {
        let palette: [[Color]] = [
            [Color(red: 0.55, green: 0.15, blue: 0.35), Color(red: 0.95, green: 0.45, blue: 0.25)],
            [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.35, green: 0.65, blue: 0.75)],
            [Color(red: 0.2, green: 0.1, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.85)],
            [Color(red: 0.08, green: 0.22, blue: 0.30), Color(red: 0.25, green: 0.78, blue: 0.82)],
            [Color(red: 0.4, green: 0.12, blue: 0.08), Color(red: 0.95, green: 0.55, blue: 0.22)]
        ]
        return palette[gradientSeed % palette.count]
    }
}

struct AssetCollection: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var count: Int
    var tint: Color
}

// MARK: - Samples

enum AssetLibrarySamples {
    static let collections: [AssetCollection] = [
        .init(name: "All Assets", count: 42, tint: Theme.accent),
        .init(name: "Favorites", count: 8, tint: Theme.magenta),
        .init(name: "Neon Requiem", count: 18, tint: Theme.teal),
        .init(name: "Tide & Bone", count: 12, tint: Theme.violet)
    ]

    static let assets: [Asset] = [
        .init(name: "Elena Voss", kind: .character, tags: ["hero", "detective", "noir"],
              versions: 3, favorited: true, linkedProjects: ["Neon Requiem"],
              updatedLabel: "2h ago", gradientSeed: 0),
        .init(name: "Kade Ortiz", kind: .character, tags: ["ally", "mechanic"],
              versions: 2, favorited: false, linkedProjects: ["Neon Requiem"],
              updatedLabel: "Yesterday", gradientSeed: 1),
        .init(name: "Rain-soaked alley", kind: .background, tags: ["exterior", "night", "neon"],
              versions: 4, favorited: true, linkedProjects: ["Neon Requiem"],
              updatedLabel: "3d ago", gradientSeed: 2),
        .init(name: "Dive bar interior", kind: .background, tags: ["interior", "night", "warm"],
              versions: 2, favorited: false, linkedProjects: ["Neon Requiem"],
              updatedLabel: "1w ago", gradientSeed: 3),
        .init(name: "Detective's badge", kind: .prop, tags: ["hero", "metal"],
              versions: 1, favorited: false, linkedProjects: ["Neon Requiem"],
              updatedLabel: "4d ago", gradientSeed: 4),
        .init(name: "Folded photograph", kind: .prop, tags: ["clue", "paper"],
              versions: 2, favorited: true, linkedProjects: ["Neon Requiem"],
              updatedLabel: "2d ago", gradientSeed: 0),
        .init(name: "Coastal cliffs", kind: .background, tags: ["exterior", "day", "mystery"],
              versions: 3, favorited: false, linkedProjects: ["Tide & Bone"],
              updatedLabel: "5h ago", gradientSeed: 1),
        .init(name: "Lantern Room", kind: .background, tags: ["interior", "warm", "ornate"],
              versions: 2, favorited: false, linkedProjects: ["The Lantern Keeper"],
              updatedLabel: "2w ago", gradientSeed: 2),
        .init(name: "Distant thunder", kind: .audio, tags: ["ambient", "dark"],
              versions: 1, favorited: false, linkedProjects: ["Neon Requiem", "Tide & Bone"],
              updatedLabel: "1d ago", gradientSeed: 3),
        .init(name: "Noir score — cue 03", kind: .audio, tags: ["music", "tense"],
              versions: 2, favorited: true, linkedProjects: ["Neon Requiem"],
              updatedLabel: "6h ago", gradientSeed: 4),
        .init(name: "Ridley Scott — reference", kind: .reference, tags: ["lighting", "mood"],
              versions: 1, favorited: false, linkedProjects: [],
              updatedLabel: "Last month", gradientSeed: 0),
        .init(name: "Deakins — reference", kind: .reference, tags: ["composition", "wide"],
              versions: 1, favorited: true, linkedProjects: [],
              updatedLabel: "Last month", gradientSeed: 1)
    ]
}
