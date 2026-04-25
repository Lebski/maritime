import SwiftUI

// MARK: - Navigation

enum AppModule: String, CaseIterable, Identifiable {
    case home
    case storyForge
    case characterLab
    case setDesign
    case storyboard
    case sceneBuilder
    case videoRenderer
    case assetLibrary
    case exports

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .storyForge: return "Story Forge"
        case .storyboard: return "Storyboard Composer"
        case .characterLab: return "Character Lab"
        case .setDesign: return "Set Design"
        case .sceneBuilder: return "Scene Builder"
        case .videoRenderer: return "Video Renderer"
        case .assetLibrary: return "Asset Library"
        case .exports: return "Exports"
        }
    }

    var shortTitle: String {
        switch self {
        case .storyboard: return "Storyboard"
        case .videoRenderer: return "Renderer"
        case .assetLibrary: return "Assets"
        default: return title
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .storyForge: return "text.book.closed.fill"
        case .storyboard: return "square.grid.3x2.fill"
        case .characterLab: return "person.crop.artframe"
        case .setDesign: return "cube.transparent.fill"
        case .sceneBuilder: return "photo.stack.fill"
        case .videoRenderer: return "film.stack.fill"
        case .assetLibrary: return "tray.full.fill"
        case .exports: return "square.and.arrow.up.on.square.fill"
        }
    }

    var tint: Color {
        switch self {
        case .home: return Theme.accent
        case .storyForge: return Theme.magenta
        case .storyboard: return Theme.violet
        case .characterLab: return Theme.teal
        case .setDesign: return Theme.coral
        case .sceneBuilder: return Theme.accent
        case .videoRenderer: return Theme.lime
        case .assetLibrary: return Color.white.opacity(0.7)
        case .exports: return Color.white.opacity(0.7)
        }
    }

    var tagline: String {
        switch self {
        case .home: return "Your filmmaking cockpit"
        case .storyForge: return "Develop compelling stories"
        case .storyboard: return "Visualize shot sequences"
        case .characterLab: return "Design consistent heroes"
        case .setDesign: return "Build the world's vocabulary"
        case .sceneBuilder: return "Compose cinematic frames"
        case .videoRenderer: return "Bring scenes to motion"
        case .assetLibrary: return "All your creative assets"
        case .exports: return "Deliver to Premiere & more"
        }
    }
}

// MARK: - Project

struct MovieProject: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let genre: String
    let logline: String
    let progress: Double           // 0.0 ... 1.0
    let scenes: Int
    let characters: Int
    let durationMinutes: Int
    let updatedLabel: String
    let posterColors: [Color]
    let status: ProjectStatus
}

enum ProjectStatus: String {
    case story = "Story"
    case storyboard = "Storyboard"
    case shooting = "Rendering"
    case finishing = "Finishing"

    var tint: Color {
        switch self {
        case .story: return Theme.magenta
        case .storyboard: return Theme.violet
        case .shooting: return Theme.lime
        case .finishing: return Theme.accent
        }
    }
}

// MARK: - Sample Data

enum SampleData {
    static let projects: [MovieProject] = [
        MovieProject(
            title: "Neon Requiem",
            genre: "Neo-Noir Thriller",
            logline: "A cybernetic detective chases a ghost through a city that never sleeps.",
            progress: 0.72,
            scenes: 14,
            characters: 6,
            durationMinutes: 22,
            updatedLabel: "2h ago",
            posterColors: [Color(red: 0.55, green: 0.15, blue: 0.35), Color(red: 0.95, green: 0.45, blue: 0.25)],
            status: .shooting
        ),
        MovieProject(
            title: "The Lantern Keeper",
            genre: "Fantasy Drama",
            logline: "An old woman guards the last flame of memory in a world turning to silence.",
            progress: 0.38,
            scenes: 9,
            characters: 3,
            durationMinutes: 14,
            updatedLabel: "Yesterday",
            posterColors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.35, green: 0.65, blue: 0.75)],
            status: .storyboard
        ),
        MovieProject(
            title: "Paper Moon 2049",
            genre: "Sci-Fi Romance",
            logline: "Two strangers exchange dreams across a decaying lunar colony.",
            progress: 0.15,
            scenes: 4,
            characters: 2,
            durationMinutes: 8,
            updatedLabel: "3 days ago",
            posterColors: [Color(red: 0.2, green: 0.1, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.85)],
            status: .story
        ),
        MovieProject(
            title: "Tide & Bone",
            genre: "Coastal Mystery",
            logline: "A biologist uncovers something ancient buried beneath her childhood beach.",
            progress: 0.92,
            scenes: 18,
            characters: 5,
            durationMinutes: 27,
            updatedLabel: "Just now",
            posterColors: [Color(red: 0.08, green: 0.22, blue: 0.30), Color(red: 0.25, green: 0.78, blue: 0.82)],
            status: .finishing
        )
    ]

    static let tips: [FilmTip] = [
        .init(title: "Murch's Rule of Six", body: "Emotion first, story second, rhythm third. Cut on the highest-priority element you can preserve."),
        .init(title: "Mamet on Want", body: "Every protagonist must want something. Make it clear, make it active, make it visual."),
        .init(title: "180° Rule", body: "Keep the camera on one side of an imaginary axis to preserve spatial continuity for the audience.")
    ]
}

struct FilmTip: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let body: String
}
