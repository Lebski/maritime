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
//
// Derived projection of a project entity (LabCharacter, SceneBackground,
// SceneProp, …). The id is the underlying entity's UUID so that selection
// and favorites survive across re-derivations.

struct Asset: Identifiable, Hashable {
    let id: UUID
    var name: String
    var kind: AssetKind
    var tags: [String]
    var versions: Int
    var favorited: Bool
    var linkedProjects: [String]
    var updatedLabel: String
    var gradientColors: [Color]
}

struct AssetCollection: Identifiable, Hashable {
    let id: UUID
    var name: String
    var count: Int
    var tint: Color

    init(id: UUID = UUID(), name: String, count: Int, tint: Color) {
        self.id = id
        self.name = name
        self.count = count
        self.tint = tint
    }
}
