import SwiftUI

// MARK: - Scene Builder Models

enum TimeOfDay: String, CaseIterable, Identifiable, Codable {
    case dawn = "Dawn"
    case day = "Day"
    case goldenHour = "Golden Hour"
    case dusk = "Dusk"
    case night = "Night"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dawn: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .goldenHour: return "sun.horizon.fill"
        case .dusk: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var tint: Color {
        switch self {
        case .dawn: return Color(red: 1.0, green: 0.72, blue: 0.55)
        case .day: return Color(red: 0.98, green: 0.88, blue: 0.45)
        case .goldenHour: return Color(red: 1.0, green: 0.65, blue: 0.25)
        case .dusk: return Color(red: 0.85, green: 0.38, blue: 0.55)
        case .night: return Color(red: 0.35, green: 0.42, blue: 0.72)
        }
    }
}

enum LightingMood: String, CaseIterable, Identifiable, Codable {
    case warm = "Warm"
    case cold = "Cold"
    case neutral = "Neutral"
    case highContrast = "High Contrast"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .warm: return Theme.accent
        case .cold: return Theme.teal
        case .neutral: return Color.white.opacity(0.7)
        case .highContrast: return Theme.magenta
        }
    }
}

enum KeyLightDirection: String, CaseIterable, Identifiable, Codable {
    case frontal = "Frontal"
    case leftSide = "Left Side"
    case rightSide = "Right Side"
    case backlit = "Backlit"
    case topDown = "Top-Down"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .frontal: return "light.min"
        case .leftSide: return "arrow.right"
        case .rightSide: return "arrow.left"
        case .backlit: return "light.beacon.max.fill"
        case .topDown: return "arrow.down"
        }
    }
}

enum CameraShotType: String, CaseIterable, Identifiable, Codable {
    case extremeCloseUp = "Extreme Close-up"
    case closeUp = "Close-up"
    case medium = "Medium Shot"
    case full = "Full Shot"
    case wide = "Wide / Establishing"
    case overTheShoulder = "Over-the-Shoulder"
    case pov = "POV"
    case dutchAngle = "Dutch Angle"
    case lowAngle = "Low Angle"
    case highAngle = "High Angle"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .extremeCloseUp: return "ECU"
        case .closeUp: return "CU"
        case .medium: return "MS"
        case .full: return "FS"
        case .wide: return "WS"
        case .overTheShoulder: return "OTS"
        case .pov: return "POV"
        case .dutchAngle: return "Dutch"
        case .lowAngle: return "Low"
        case .highAngle: return "High"
        }
    }
}

enum CompositionGuide: String, CaseIterable, Identifiable, Codable {
    case ruleOfThirds = "Rule of Thirds"
    case goldenRatio = "Golden Ratio"
    case leadingLines = "Leading Lines"
    case headroom = "Headroom"
    case axis180 = "180° Line"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ruleOfThirds: return "grid"
        case .goldenRatio: return "rectangle.split.3x1"
        case .leadingLines: return "scope"
        case .headroom: return "arrow.up.and.down"
        case .axis180: return "arrow.left.and.right"
        }
    }
}

// MARK: - Assets

struct SceneBackground: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let tag: String
    let gradientColors: [Color]
    let symbol: String

    init(id: UUID = UUID(), name: String, tag: String, gradientColors: [Color], symbol: String) {
        self.id = id
        self.name = name
        self.tag = tag
        self.gradientColors = gradientColors
        self.symbol = symbol
    }
}

struct SceneProp: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let category: String
    let tint: Color
    let symbol: String

    init(id: UUID = UUID(), name: String, category: String, tint: Color, symbol: String) {
        self.id = id
        self.name = name
        self.category = category
        self.tint = tint
        self.symbol = symbol
    }
}

struct SceneCharacterRef: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let role: String
    let tint: Color
    var xRatio: CGFloat       // 0...1 position on canvas
    var yRatio: CGFloat
    var gazeDegrees: Double   // direction of gaze
    var depthLayer: DepthLayer

    init(id: UUID = UUID(), name: String, role: String, tint: Color, xRatio: CGFloat, yRatio: CGFloat, gazeDegrees: Double, depthLayer: DepthLayer) {
        self.id = id
        self.name = name
        self.role = role
        self.tint = tint
        self.xRatio = xRatio
        self.yRatio = yRatio
        self.gazeDegrees = gazeDegrees
        self.depthLayer = depthLayer
    }
}

enum DepthLayer: String, CaseIterable, Codable {
    case foreground = "FG"
    case midground = "MG"
    case background = "BG"

    var scale: CGFloat {
        switch self {
        case .foreground: return 1.0
        case .midground: return 0.72
        case .background: return 0.5
        }
    }

    var opacity: Double {
        switch self {
        case .foreground: return 1.0
        case .midground: return 0.85
        case .background: return 0.65
        }
    }
}

// MARK: - Film Scene

struct FilmScene: Identifiable, Codable {
    let id: UUID
    var number: Int
    var title: String
    var location: String
    var isInterior: Bool
    var timeOfDay: TimeOfDay
    var lightingMood: LightingMood
    var keyLight: KeyLightDirection
    var shotType: CameraShotType
    var background: SceneBackground?
    var props: [SceneProp]
    var characters: [SceneCharacterRef]
    var activeGuides: Set<CompositionGuide>
    var frameApproved: Bool
    var projectTitle: String
    var renderPackage: RenderPackage?

    init(id: UUID = UUID(), number: Int, title: String, location: String, isInterior: Bool,
         timeOfDay: TimeOfDay, lightingMood: LightingMood, keyLight: KeyLightDirection,
         shotType: CameraShotType, background: SceneBackground? = nil, props: [SceneProp] = [],
         characters: [SceneCharacterRef] = [], activeGuides: Set<CompositionGuide> = [],
         frameApproved: Bool = false, projectTitle: String, renderPackage: RenderPackage? = nil) {
        self.id = id
        self.number = number
        self.title = title
        self.location = location
        self.isInterior = isInterior
        self.timeOfDay = timeOfDay
        self.lightingMood = lightingMood
        self.keyLight = keyLight
        self.shotType = shotType
        self.background = background
        self.props = props
        self.characters = characters
        self.activeGuides = activeGuides
        self.frameApproved = frameApproved
        self.projectTitle = projectTitle
        self.renderPackage = renderPackage
    }

    var locationLabel: String {
        (isInterior ? "INT." : "EXT.") + " " + location.uppercased() + " — " + timeOfDay.rawValue.uppercased()
    }
}

// MARK: - Render Package
//
// Everything Nano Banana 2 (Gemini 3 Pro Image) needs to render a final frame
// from the composed scene: prompt text + up to 14 reference images.
// Saved per-scene inside the project document so re-opens preserve the exact
// prompt + selected character sheets the user last chose.

enum ImageModel: String, CaseIterable, Codable, Identifiable {
    case nanoBanana2 = "Nano Banana 2"
    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .nanoBanana2: return "Gemini 3 Pro Image · up to 14 refs"
        }
    }

    var maxReferenceImages: Int {
        switch self {
        case .nanoBanana2: return 14
        }
    }
}

enum AspectRatio: String, CaseIterable, Codable, Identifiable {
    case widescreen16x9 = "16:9"
    case cinema21x9     = "21:9"
    case square1x1      = "1:1"
    case portrait9x16   = "9:16"
    var id: String { rawValue }

    var label: String { rawValue }
}

struct CharacterReference: Identifiable, Codable, Hashable {
    let id: UUID
    let characterID: UUID
    var selectedSheetType: ReferenceSheetType
    var imageData: Data?

    init(id: UUID = UUID(), characterID: UUID,
         selectedSheetType: ReferenceSheetType, imageData: Data? = nil) {
        self.id = id
        self.characterID = characterID
        self.selectedSheetType = selectedSheetType
        self.imageData = imageData
    }
}

struct StyleReference: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var imageData: Data

    init(id: UUID = UUID(), label: String, imageData: Data) {
        self.id = id
        self.label = label
        self.imageData = imageData
    }
}

struct RenderPackage: Identifiable, Codable {
    let id: UUID
    let sceneID: UUID
    var prompt: String
    var sceneCompositionImage: Data?
    var characterReferences: [CharacterReference]
    var styleReferences: [StyleReference]
    var model: ImageModel
    var aspectRatio: AspectRatio
    var lastRenderedAt: Date?

    init(id: UUID = UUID(),
         sceneID: UUID,
         prompt: String = "",
         sceneCompositionImage: Data? = nil,
         characterReferences: [CharacterReference] = [],
         styleReferences: [StyleReference] = [],
         model: ImageModel = .nanoBanana2,
         aspectRatio: AspectRatio = .widescreen16x9,
         lastRenderedAt: Date? = nil) {
        self.id = id
        self.sceneID = sceneID
        self.prompt = prompt
        self.sceneCompositionImage = sceneCompositionImage
        self.characterReferences = characterReferences
        self.styleReferences = styleReferences
        self.model = model
        self.aspectRatio = aspectRatio
        self.lastRenderedAt = lastRenderedAt
    }

    var totalReferenceImageCount: Int {
        (sceneCompositionImage == nil ? 0 : 1)
        + characterReferences.count
        + styleReferences.count
    }

    var remainingReferenceSlots: Int {
        max(0, model.maxReferenceImages - totalReferenceImageCount)
    }
}

// MARK: - Prompt Builder
//
// Pure, deterministic function that composes a Nano Banana 2 prompt from the
// current scene + project character roster. Users get a seeded prompt they can
// freely edit; hitting "Re-seed from scene" recomposes.

enum PromptBuilder {
    static func buildPrompt(scene: FilmScene, characters: [LabCharacter]) -> String {
        var lines: [String] = []

        // Scene establishing line
        let venue = scene.isInterior ? "interior" : "exterior"
        lines.append("A cinematic \(scene.shotType.rawValue.lowercased()) of a \(venue) scene at \(scene.location.lowercased()), \(scene.timeOfDay.rawValue.lowercased()).")

        // Mood & lighting
        let moodLine = "\(scene.lightingMood.rawValue.lowercased()) lighting with key light from \(scene.keyLight.rawValue.lowercased())"
        lines.append(moodLine + ".")

        // Background mood
        if let bg = scene.background {
            lines.append("Setting: \(bg.name) — \(bg.tag).")
        }

        // Characters
        if !scene.characters.isEmpty {
            let charLines = scene.characters.compactMap { ref -> String? in
                let labMatch = characters.first(where: { $0.name == ref.name })
                let descriptor = labMatch?.description ?? ref.role
                let position = positionLabel(xRatio: ref.xRatio, yRatio: ref.yRatio)
                let depth = depthLabel(ref.depthLayer)
                return "\(ref.name) (\(descriptor)) in \(depth) \(position)"
            }
            lines.append("Cast: " + charLines.joined(separator: "; ") + ".")
        }

        // Props
        if !scene.props.isEmpty {
            let propNames = scene.props.map { $0.name.lowercased() }.joined(separator: ", ")
            lines.append("Props: \(propNames).")
        }

        // Composition hints
        if !scene.activeGuides.isEmpty {
            let guides = scene.activeGuides
                .map { $0.rawValue.lowercased() }
                .sorted()
                .joined(separator: ", ")
            lines.append("Composition: \(guides).")
        }

        // Finishing cinematic cues
        lines.append("35mm anamorphic look, film grain, balanced exposure, sharp focus on primary subject, production-quality framing.")

        return lines.joined(separator: " ")
    }

    private static func positionLabel(xRatio: CGFloat, yRatio: CGFloat) -> String {
        let horizontal: String
        switch xRatio {
        case ..<0.33: horizontal = "frame left"
        case 0.33..<0.66: horizontal = "center frame"
        default: horizontal = "frame right"
        }
        let vertical: String
        switch yRatio {
        case ..<0.33: vertical = "upper"
        case 0.33..<0.66: vertical = ""
        default: vertical = "lower"
        }
        return vertical.isEmpty ? horizontal : "\(vertical) \(horizontal)"
    }

    private static func depthLabel(_ layer: DepthLayer) -> String {
        switch layer {
        case .foreground: return "foreground"
        case .midground: return "midground"
        case .background: return "background"
        }
    }
}

// MARK: - Image Generation Service
//
// Protocol so the UI depends on an abstraction, not on Gemini directly.
// `StubImageGenerationService` simulates the remote call for development —
// real Nano Banana 2 wiring lands in a follow-up PR.

protocol ImageGenerationService: Sendable {
    func generate(package: RenderPackage) async throws -> Data
}

struct StubImageGenerationService: ImageGenerationService {
    var simulatedLatencySeconds: Double = 2.0

    func generate(package: RenderPackage) async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatencySeconds * 1_000_000_000))
        // Return an empty PNG-like placeholder; Scene Builder shows the existing
        // programmatic canvas while the stub is in place.
        return Data()
    }
}

enum ImageGenerationError: LocalizedError {
    case missingPrompt
    case tooManyReferenceImages(Int, max: Int)

    var errorDescription: String? {
        switch self {
        case .missingPrompt: return "Prompt is empty — add a description before rendering."
        case .tooManyReferenceImages(let count, let max):
            return "Reference images (\(count)) exceed the model's cap of \(max)."
        }
    }
}

// MARK: - Samples

enum SceneBuilderSamples {
    static let backgrounds: [SceneBackground] = [
        .init(name: "Rain-slick Alley", tag: "noir · ext", gradientColors: [Color(red: 0.10, green: 0.12, blue: 0.20), Color(red: 0.30, green: 0.35, blue: 0.55)], symbol: "cloud.rain.fill"),
        .init(name: "Neon Tokyo Street", tag: "cyberpunk · ext", gradientColors: [Color(red: 0.35, green: 0.08, blue: 0.45), Color(red: 0.92, green: 0.35, blue: 0.62)], symbol: "building.2.fill"),
        .init(name: "Warehouse Interior", tag: "industrial · int", gradientColors: [Color(red: 0.15, green: 0.15, blue: 0.18), Color(red: 0.45, green: 0.35, blue: 0.25)], symbol: "shippingbox.fill"),
        .init(name: "Coastal Cliff", tag: "drama · ext", gradientColors: [Color(red: 0.08, green: 0.22, blue: 0.30), Color(red: 0.28, green: 0.78, blue: 0.82)], symbol: "water.waves"),
        .init(name: "Candlelit Study", tag: "period · int", gradientColors: [Color(red: 0.20, green: 0.10, blue: 0.05), Color(red: 1.0, green: 0.72, blue: 0.29)], symbol: "books.vertical.fill"),
        .init(name: "Desert Highway", tag: "western · ext", gradientColors: [Color(red: 0.35, green: 0.18, blue: 0.08), Color(red: 0.98, green: 0.65, blue: 0.35)], symbol: "road.lanes"),
        .init(name: "Hospital Corridor", tag: "thriller · int", gradientColors: [Color(red: 0.12, green: 0.18, blue: 0.22), Color(red: 0.55, green: 0.72, blue: 0.78)], symbol: "cross.case.fill"),
        .init(name: "Forest Clearing", tag: "fantasy · ext", gradientColors: [Color(red: 0.08, green: 0.22, blue: 0.15), Color(red: 0.42, green: 0.72, blue: 0.35)], symbol: "tree.fill")
    ]

    static let props: [SceneProp] = [
        .init(name: "Antique Lantern", category: "Lighting", tint: Theme.accent, symbol: "lightbulb.fill"),
        .init(name: "Revolver", category: "Weapon", tint: Theme.magenta, symbol: "scope"),
        .init(name: "Leather Journal", category: "Handheld", tint: Color(red: 0.7, green: 0.45, blue: 0.25), symbol: "book.closed.fill"),
        .init(name: "Vintage Telephone", category: "Tech", tint: Theme.teal, symbol: "phone.fill"),
        .init(name: "Pocket Watch", category: "Handheld", tint: Theme.accent, symbol: "clock.fill"),
        .init(name: "Whiskey Tumbler", category: "Drink", tint: Color(red: 0.85, green: 0.55, blue: 0.25), symbol: "wineglass.fill"),
        .init(name: "Photograph", category: "Handheld", tint: Color.white.opacity(0.8), symbol: "photo.fill"),
        .init(name: "Umbrella", category: "Wardrobe", tint: Theme.violet, symbol: "umbrella.fill"),
        .init(name: "Briefcase", category: "Handheld", tint: Color(red: 0.45, green: 0.30, blue: 0.20), symbol: "briefcase.fill"),
        .init(name: "Cigarette Case", category: "Handheld", tint: Color.white.opacity(0.7), symbol: "rectangle.fill")
    ]

    static let characters: [SceneCharacterRef] = [
        .init(name: "Elena", role: "Protagonist", tint: Theme.magenta, xRatio: 0.35, yRatio: 0.55, gazeDegrees: 10, depthLayer: .foreground),
        .init(name: "Marcus", role: "Antagonist", tint: Theme.accent, xRatio: 0.68, yRatio: 0.58, gazeDegrees: -170, depthLayer: .midground)
    ]

    static let scenes: [FilmScene] = [
        FilmScene(
            number: 1,
            title: "The Confrontation",
            location: "Warehouse",
            isInterior: true,
            timeOfDay: .night,
            lightingMood: .highContrast,
            keyLight: .leftSide,
            shotType: .medium,
            background: backgrounds[2],
            props: [props[1], props[5]],
            characters: characters,
            activeGuides: [.ruleOfThirds, .axis180],
            frameApproved: false,
            projectTitle: "Neon Requiem"
        ),
        FilmScene(
            number: 2,
            title: "Elena's Arrival",
            location: "Tokyo Street",
            isInterior: false,
            timeOfDay: .night,
            lightingMood: .cold,
            keyLight: .backlit,
            shotType: .wide,
            background: backgrounds[1],
            props: [props[7]],
            characters: [characters[0]],
            activeGuides: [.ruleOfThirds],
            frameApproved: true,
            projectTitle: "Neon Requiem"
        ),
        FilmScene(
            number: 3,
            title: "The Letter",
            location: "Candlelit Study",
            isInterior: true,
            timeOfDay: .night,
            lightingMood: .warm,
            keyLight: .rightSide,
            shotType: .closeUp,
            background: backgrounds[4],
            props: [props[2], props[0]],
            characters: [characters[0]],
            activeGuides: [.ruleOfThirds, .headroom],
            frameApproved: false,
            projectTitle: "The Lantern Keeper"
        ),
        FilmScene(
            number: 4,
            title: "Edge of the World",
            location: "Coastal Cliff",
            isInterior: false,
            timeOfDay: .goldenHour,
            lightingMood: .warm,
            keyLight: .frontal,
            shotType: .wide,
            background: backgrounds[3],
            props: [],
            characters: [characters[0]],
            activeGuides: [.goldenRatio, .headroom],
            frameApproved: false,
            projectTitle: "Tide & Bone"
        )
    ]
}
