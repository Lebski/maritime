import SwiftUI

// MARK: - Story Forge Models
//
// Story Forge captures the narrative skeleton of a film before any visuals
// are created. It produces a Story Bible composed of four facets:
//   1. Character psychology (Want / Need / Ghost / Flaw / Stakes / Voice)
//   2. Structure (chosen template + beat annotations)
//   3. Scene breakdowns (one row per scene)
//   4. Theme & motifs (central statement + recurring imagery + palette)
//
// Drafts here are explicitly separate from domain objects in other modules.
// Promotion is a one-way action: "Promote to Character Lab" creates a
// LabCharacter; "Send to Scene Builder" creates a FilmScene. This keeps
// modules independently usable.

enum StoryForgeSection: String, CaseIterable, Identifiable, Hashable {
    case characters, structure, scenes, theme
    var id: String { rawValue }

    var title: String {
        switch self {
        case .characters: return "Character Builder"
        case .structure:  return "Structure"
        case .scenes:     return "Scene Breakdown"
        case .theme:      return "Theme & Motifs"
        }
    }

    var shortTitle: String {
        switch self {
        case .characters: return "Characters"
        case .structure:  return "Structure"
        case .scenes:     return "Scenes"
        case .theme:      return "Theme"
        }
    }

    var icon: String {
        switch self {
        case .characters: return "person.text.rectangle.fill"
        case .structure:  return "chart.bar.xaxis"
        case .scenes:     return "rectangle.stack.fill"
        case .theme:      return "paintpalette.fill"
        }
    }
}

// MARK: - Character Draft

enum StoryCharacterField: String, CaseIterable, Identifiable, Hashable {
    case backstory, want, need, ghost, flaw, stakes, voice
    var id: String { rawValue }

    /// Fields that describe character psychology. Backstory is author-provided context,
    /// not a psychology pillar, so AI generation fills only these six.
    static var psychologyFields: [StoryCharacterField] {
        [.want, .need, .ghost, .flaw, .stakes, .voice]
    }

    var label: String {
        switch self {
        case .backstory: return "Backstory"
        case .want:   return "Want"
        case .need:   return "Need"
        case .ghost:  return "Ghost / Wound"
        case .flaw:   return "Flaw"
        case .stakes: return "Stakes"
        case .voice:  return "Voice"
        }
    }

    var subtitle: String {
        switch self {
        case .backstory: return "What shaped them before page one"
        case .want:   return "External goal — what they pursue on-screen"
        case .need:   return "Internal truth — what they actually require"
        case .ghost:  return "Past wound shaping present behaviour"
        case .flaw:   return "The blind spot that must break before they grow"
        case .stakes: return "What they lose if they fail"
        case .voice:  return "How they speak, move, and react"
        }
    }

    var icon: String {
        switch self {
        case .backstory: return "book.closed.fill"
        case .want:   return "target"
        case .need:   return "heart.fill"
        case .ghost:  return "moon.stars.fill"
        case .flaw:   return "bolt.trianglebadge.exclamationmark.fill"
        case .stakes: return "flame.fill"
        case .voice:  return "waveform"
        }
    }

    var tint: Color {
        switch self {
        case .backstory: return Theme.textSecondary
        case .want:   return Theme.accent
        case .need:   return Theme.magenta
        case .ghost:  return Theme.violet
        case .flaw:   return Theme.lime
        case .stakes: return Color(red: 0.95, green: 0.45, blue: 0.25)
        case .voice:  return Theme.teal
        }
    }

    var whyItMatters: String {
        switch self {
        case .backstory:
            return "A sentence or two of backstory gives every psychology field something concrete to echo. The more specific you are here, the less generic the rest becomes."
        case .want:
            return "Every protagonist must want something visible. Want is what the camera can photograph — a goal, an object, a destination. Without a clear want, scenes drift."
        case .need:
            return "The need is the lesson the story teaches the protagonist. It often contradicts the want. The gap between them is the character arc."
        case .ghost:
            return "The ghost explains why your character has the flaw. It's the unhealed wound driving their behavior. Every present-tense choice echoes it."
        case .flaw:
            return "Flaws make characters human and create obstacles that aren't just external. The protagonist's worst enemy should be themselves."
        case .stakes:
            return "Without stakes there's no tension. Make them specific, personal, and visible. Abstract stakes don't move audiences."
        case .voice:
            return "Voice is the signature — word choice, rhythm, body language. If a line could come from any mouth, it's too generic."
        }
    }

    var examples: [String] {
        switch self {
        case .backstory:
            return [
                "A medic who lost her brother during a refugee crossing she helped organize.",
                "A disgraced cartographer redrawing maps of a country that no longer exists.",
                "A retired dancer teaching children the steps she's no longer strong enough to perform."
            ]
        case .want:
            return [
                "Michael Corleone wants to protect his family without becoming his father.",
                "Mattie Ross (True Grit) wants the man who killed her father.",
                "Nemo's father wants his son back, safe, at home."
            ]
        case .need:
            return [
                "Michael needs to accept that family and crime cannot coexist.",
                "Mattie needs to learn the cost of vengeance.",
                "Marlin needs to trust Nemo enough to let him go."
            ]
        case .ghost:
            return [
                "Rick's ghost (Casablanca): Ilsa left him in Paris without explanation.",
                "Will Hunting's ghost: abandonment and abuse survived by armoring himself with genius.",
                "The Joker's ghost: whichever version of the mother story he tells tonight."
            ]
        case .flaw:
            return [
                "Tony Stark — arrogance disguised as confidence.",
                "Elsa — terror of her own power.",
                "Walter White — pride, cosplaying as provision."
            ]
        case .stakes:
            return [
                "If Indy fails: the Ark ends up with the Nazis.",
                "If Andy fails to escape: another decade in Shawshank.",
                "If Frodo fails: Middle-earth falls."
            ]
        case .voice:
            return [
                "Juno's hyperverbal deflection: \"honest to blog?\"",
                "Sam Spade's clipped noir — punchline where a paragraph should be.",
                "Fleabag's direct-to-camera asides that break the fourth wall on purpose."
            ]
        }
    }
}

struct StoryCharacterDraft: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var role: String
    var backstory: String = ""
    var want: String = ""
    var need: String = ""
    var ghost: String = ""
    var flaw: String = ""
    var stakes: String = ""
    var voice: String = ""
    var promotedLabCharacterID: UUID?

    init(id: UUID = UUID(),
         name: String,
         role: String,
         backstory: String = "",
         want: String = "",
         need: String = "",
         ghost: String = "",
         flaw: String = "",
         stakes: String = "",
         voice: String = "",
         promotedLabCharacterID: UUID? = nil) {
        self.id = id
        self.name = name
        self.role = role
        self.backstory = backstory
        self.want = want
        self.need = need
        self.ghost = ghost
        self.flaw = flaw
        self.stakes = stakes
        self.voice = voice
        self.promotedLabCharacterID = promotedLabCharacterID
    }

    func value(for field: StoryCharacterField) -> String {
        switch field {
        case .backstory: return backstory
        case .want:   return want
        case .need:   return need
        case .ghost:  return ghost
        case .flaw:   return flaw
        case .stakes: return stakes
        case .voice:  return voice
        }
    }

    mutating func setValue(_ text: String, for field: StoryCharacterField) {
        switch field {
        case .backstory: backstory = text
        case .want:   want = text
        case .need:   need = text
        case .ghost:  ghost = text
        case .flaw:   flaw = text
        case .stakes: stakes = text
        case .voice:  voice = text
        }
    }

    /// Psychology completion (Want…Voice). Backstory is not counted — it's an input, not a pillar.
    var completion: Double {
        let all: [String] = [want, need, ghost, flaw, stakes, voice]
        let filled = all.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        return Double(filled) / Double(all.count)
    }

    var isPromoted: Bool { promotedLabCharacterID != nil }
}

// MARK: - Structure

enum StoryStructureTemplate: String, CaseIterable, Identifiable, Hashable, Codable {
    case threeAct        = "Three-Act Structure"
    case saveTheCat      = "Save the Cat"
    case herosJourney    = "Hero's Journey"
    case kishotenketsu   = "Kishotenketsu"
    case inMediasRes     = "In Medias Res"

    var id: String { rawValue }

    var tagline: String {
        switch self {
        case .threeAct:      return "Classic Setup · Confrontation · Resolution"
        case .saveTheCat:    return "15 beats — Blake Snyder's commercial spine"
        case .herosJourney:  return "12 stages — Campbell's monomyth"
        case .kishotenketsu: return "4 acts, no conflict — Japanese narrative"
        case .inMediasRes:   return "Start mid-action, layer context"
        }
    }

    var filmExamples: [String] {
        switch self {
        case .threeAct:      return ["The Shawshank Redemption", "Casablanca", "Back to the Future"]
        case .saveTheCat:    return ["Legally Blonde", "Miss Congeniality", "Whiplash"]
        case .herosJourney:  return ["Star Wars: A New Hope", "The Matrix", "The Lion King"]
        case .kishotenketsu: return ["My Neighbor Totoro", "Lost in Translation", "Paterson"]
        case .inMediasRes:   return ["Fight Club", "Memento", "Pulp Fiction"]
        }
    }

    var beatCount: Int { defaultBeats.count }

    var defaultBeats: [StoryBeat] {
        StoryForgeSamples.beats(for: self)
    }
}

struct StoryBeat: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var actLabel: String
    var timingPercent: Double      // 0...1 horizontal position on the timeline
    var defaultPrompt: String
    var filmExample: String
    var emotionalValence: Double   // -1 (despair) ... +1 (elation), drives arc curve
    var userNotes: String

    init(id: UUID = UUID(),
         name: String,
         actLabel: String,
         timingPercent: Double,
         defaultPrompt: String,
         filmExample: String,
         emotionalValence: Double,
         userNotes: String = "") {
        self.id = id
        self.name = name
        self.actLabel = actLabel
        self.timingPercent = timingPercent
        self.defaultPrompt = defaultPrompt
        self.filmExample = filmExample
        self.emotionalValence = emotionalValence
        self.userNotes = userNotes
    }

    var actTint: Color {
        switch actLabel {
        case "Act 1": return Theme.teal
        case "Act 2": return Theme.accent
        case "Act 2A": return Theme.accent
        case "Act 2B": return Color(red: 0.95, green: 0.45, blue: 0.25)
        case "Act 3": return Theme.magenta
        case "Act 4": return Theme.violet
        default: return Theme.violet
        }
    }
}

struct StoryStructureDraft: Hashable, Codable {
    var template: StoryStructureTemplate
    var beats: [StoryBeat]

    init(template: StoryStructureTemplate) {
        self.template = template
        self.beats = template.defaultBeats
    }

    init(template: StoryStructureTemplate, beats: [StoryBeat]) {
        self.template = template
        self.beats = beats
    }

    var completion: Double {
        guard !beats.isEmpty else { return 0 }
        let annotated = beats.filter { !$0.userNotes.trimmingCharacters(in: .whitespaces).isEmpty }.count
        return Double(annotated) / Double(beats.count)
    }
}

// MARK: - Scene Breakdown

struct SceneBreakdown: Identifiable, Hashable, Codable {
    let id: UUID
    var number: Int
    var title: String
    var location: String
    var isInterior: Bool
    var timeOfDay: TimeOfDay
    var characterDraftIDs: [UUID]
    var sceneGoal: String
    var conflict: String
    var emotionalBeat: String
    var visualMetaphor: String
    var transitionNote: String
    var promotedFilmSceneID: UUID?

    init(id: UUID = UUID(),
         number: Int,
         title: String,
         location: String,
         isInterior: Bool,
         timeOfDay: TimeOfDay,
         characterDraftIDs: [UUID] = [],
         sceneGoal: String = "",
         conflict: String = "",
         emotionalBeat: String = "",
         visualMetaphor: String = "",
         transitionNote: String = "",
         promotedFilmSceneID: UUID? = nil) {
        self.id = id
        self.number = number
        self.title = title
        self.location = location
        self.isInterior = isInterior
        self.timeOfDay = timeOfDay
        self.characterDraftIDs = characterDraftIDs
        self.sceneGoal = sceneGoal
        self.conflict = conflict
        self.emotionalBeat = emotionalBeat
        self.visualMetaphor = visualMetaphor
        self.transitionNote = transitionNote
        self.promotedFilmSceneID = promotedFilmSceneID
    }

    var locationLabel: String {
        (isInterior ? "INT." : "EXT.") + " " + location.uppercased() + " — " + timeOfDay.rawValue.uppercased()
    }

    var completion: Double {
        let fields: [String] = [sceneGoal, conflict, emotionalBeat]
        let filled = fields.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        return Double(filled) / Double(fields.count)
    }

    var isPromoted: Bool { promotedFilmSceneID != nil }
}

// MARK: - Theme & Motifs

struct VisualMotif: Identifiable, Hashable, Codable {
    let id: UUID
    var label: String
    var symbol: String        // SF Symbol name
    var tint: Color
    var frequency: Int        // rough count of scenes referencing it

    init(id: UUID = UUID(), label: String, symbol: String, tint: Color, frequency: Int = 1) {
        self.id = id
        self.label = label
        self.symbol = symbol
        self.tint = tint
        self.frequency = frequency
    }
}

struct ColorPaletteSwatch: Identifiable, Hashable, Codable {
    let id: UUID
    var hex: String
    var color: Color
    var role: String          // e.g. "Protagonist", "Act 1", "World"

    init(id: UUID = UUID(), hex: String, color: Color, role: String) {
        self.id = id
        self.hex = hex
        self.color = color
        self.role = role
    }
}

struct ThemeTracker: Hashable, Codable {
    var themeStatement: String
    var motifs: [VisualMotif]
    var palette: [ColorPaletteSwatch]

    init(themeStatement: String = "", motifs: [VisualMotif] = [], palette: [ColorPaletteSwatch] = []) {
        self.themeStatement = themeStatement
        self.motifs = motifs
        self.palette = palette
    }

    var completion: Double {
        var score = 0.0
        if !themeStatement.trimmingCharacters(in: .whitespaces).isEmpty { score += 0.5 }
        if !motifs.isEmpty { score += 0.25 }
        if !palette.isEmpty { score += 0.25 }
        return score
    }
}

// MARK: - Story Bible

struct StoryBible: Identifiable, Hashable, Codable {
    let id: UUID
    var projectTitle: String
    var logline: String
    var pitch: String
    var lastUpdated: Date
    var characterDrafts: [StoryCharacterDraft]
    var structure: StoryStructureDraft
    var sceneBreakdowns: [SceneBreakdown]
    var theme: ThemeTracker
    var posterColors: [Color]

    init(id: UUID = UUID(),
         projectTitle: String,
         logline: String,
         pitch: String = "",
         lastUpdated: Date = Date(),
         characterDrafts: [StoryCharacterDraft] = [],
         structure: StoryStructureDraft,
         sceneBreakdowns: [SceneBreakdown] = [],
         theme: ThemeTracker = ThemeTracker(),
         posterColors: [Color] = [Theme.magenta, Theme.violet]) {
        self.id = id
        self.projectTitle = projectTitle
        self.logline = logline
        self.pitch = pitch
        self.lastUpdated = lastUpdated
        self.characterDrafts = characterDrafts
        self.structure = structure
        self.sceneBreakdowns = sceneBreakdowns
        self.theme = theme
        self.posterColors = posterColors
    }

    private enum CodingKeys: String, CodingKey {
        case id, projectTitle, logline, pitch, lastUpdated
        case characterDrafts, structure, sceneBreakdowns, theme, posterColors
    }

    /// `pitch` was added after the v2 schema; default to "" when missing so
    /// existing `.mblaze` files keep loading without a schema bump.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id              = try c.decode(UUID.self, forKey: .id)
        self.projectTitle    = try c.decode(String.self, forKey: .projectTitle)
        self.logline         = try c.decode(String.self, forKey: .logline)
        self.pitch           = (try c.decodeIfPresent(String.self, forKey: .pitch)) ?? ""
        self.lastUpdated     = try c.decode(Date.self, forKey: .lastUpdated)
        self.characterDrafts = try c.decode([StoryCharacterDraft].self, forKey: .characterDrafts)
        self.structure       = try c.decode(StoryStructureDraft.self, forKey: .structure)
        self.sceneBreakdowns = try c.decode([SceneBreakdown].self, forKey: .sceneBreakdowns)
        self.theme           = try c.decode(ThemeTracker.self, forKey: .theme)
        self.posterColors    = try c.decode([Color].self, forKey: .posterColors)
    }

    var characterCompletion: Double {
        guard !characterDrafts.isEmpty else { return 0 }
        return characterDrafts.map(\.completion).reduce(0, +) / Double(characterDrafts.count)
    }

    var sceneCompletion: Double {
        guard !sceneBreakdowns.isEmpty else { return 0 }
        return sceneBreakdowns.map(\.completion).reduce(0, +) / Double(sceneBreakdowns.count)
    }

    func completion(for section: StoryForgeSection) -> Double {
        switch section {
        case .characters: return characterCompletion
        case .structure:  return structure.completion
        case .scenes:     return sceneCompletion
        case .theme:      return theme.completion
        }
    }

    var overallCompletion: Double {
        let parts = StoryForgeSection.allCases.map { completion(for: $0) }
        return parts.reduce(0, +) / Double(parts.count)
    }

    /// True when the user hasn't touched any facet of the bible. Used to
    /// auto-present the onboarding wizard.
    var isEmpty: Bool {
        projectTitle.trimmingCharacters(in: .whitespaces).isEmpty
            && logline.trimmingCharacters(in: .whitespaces).isEmpty
            && pitch.trimmingCharacters(in: .whitespaces).isEmpty
            && characterDrafts.isEmpty
            && sceneBreakdowns.isEmpty
            && structure.beats.allSatisfy { $0.userNotes.trimmingCharacters(in: .whitespaces).isEmpty }
            && theme.themeStatement.trimmingCharacters(in: .whitespaces).isEmpty
            && theme.motifs.isEmpty
            && theme.palette.isEmpty
    }

    func mapLabRole(for draft: StoryCharacterDraft) -> String {
        draft.role.isEmpty ? "Supporting" : draft.role
    }

    /// Build a prose description for promoting this draft to the Character Lab.
    /// Combines physical/voice hints so the lab has something to render.
    func labDescription(for draft: StoryCharacterDraft) -> String {
        let parts: [String] = [
            draft.voice.isEmpty ? nil : draft.voice,
            draft.flaw.isEmpty ? nil : "Flaw: \(draft.flaw)",
            draft.want.isEmpty ? nil : "Wants: \(draft.want)"
        ].compactMap { $0 }
        return parts.isEmpty ? "\(draft.name) · \(draft.role)" : parts.joined(separator: " · ")
    }
}

// MARK: - Sample Data

enum StoryForgeSamples {

    // ---- Template beat libraries ----

    static func beats(for template: StoryStructureTemplate) -> [StoryBeat] {
        switch template {
        case .threeAct:      return threeAct
        case .saveTheCat:    return saveTheCat
        case .herosJourney:  return herosJourney
        case .kishotenketsu: return kishotenketsu
        case .inMediasRes:   return inMediasRes
        }
    }

    private static let threeAct: [StoryBeat] = [
        StoryBeat(name: "Opening Image", actLabel: "Act 1", timingPercent: 0.02,
                  defaultPrompt: "A visual snapshot of the protagonist's world before change.",
                  filmExample: "Shawshank — the cemetery-grey exterior of the prison.",
                  emotionalValence: 0.0),
        StoryBeat(name: "Inciting Incident", actLabel: "Act 1", timingPercent: 0.12,
                  defaultPrompt: "The event that disrupts equilibrium and launches the story.",
                  filmExample: "Shawshank — Andy is convicted.",
                  emotionalValence: -0.3),
        StoryBeat(name: "Plot Point 1", actLabel: "Act 1", timingPercent: 0.25,
                  defaultPrompt: "Protagonist crosses a threshold they cannot return from.",
                  filmExample: "Shawshank — Andy arrives inside Shawshank.",
                  emotionalValence: -0.5),
        StoryBeat(name: "Rising Action", actLabel: "Act 2", timingPercent: 0.45,
                  defaultPrompt: "Escalating obstacles, learning the rules of the new world.",
                  filmExample: "Shawshank — the library, the rooftop beer, the rock hammer.",
                  emotionalValence: 0.2),
        StoryBeat(name: "Midpoint", actLabel: "Act 2", timingPercent: 0.50,
                  defaultPrompt: "A twist that raises stakes and shifts the protagonist's goal.",
                  filmExample: "Shawshank — Andy plays the opera over the PA.",
                  emotionalValence: 0.4),
        StoryBeat(name: "Crisis", actLabel: "Act 2", timingPercent: 0.70,
                  defaultPrompt: "The darkest moment — all seems lost.",
                  filmExample: "Shawshank — Tommy is murdered.",
                  emotionalValence: -0.8),
        StoryBeat(name: "Climax", actLabel: "Act 3", timingPercent: 0.87,
                  defaultPrompt: "The confrontation that resolves the central conflict.",
                  filmExample: "Shawshank — Andy crawls to freedom.",
                  emotionalValence: 0.9),
        StoryBeat(name: "Resolution", actLabel: "Act 3", timingPercent: 0.97,
                  defaultPrompt: "The new equilibrium — the world after change.",
                  filmExample: "Shawshank — Red meets Andy on the beach.",
                  emotionalValence: 0.7)
    ]

    private static let saveTheCat: [StoryBeat] = [
        StoryBeat(name: "Opening Image", actLabel: "Act 1", timingPercent: 0.01,
                  defaultPrompt: "Before-picture of the protagonist's world. Tone-setter.",
                  filmExample: "Legally Blonde — Elle's pink, perfect sorority life.",
                  emotionalValence: 0.2),
        StoryBeat(name: "Theme Stated", actLabel: "Act 1", timingPercent: 0.05,
                  defaultPrompt: "Someone states the lesson the protagonist must learn.",
                  filmExample: "Legally Blonde — \"What, like it's hard?\"",
                  emotionalValence: 0.1),
        StoryBeat(name: "Setup", actLabel: "Act 1", timingPercent: 0.08,
                  defaultPrompt: "Introduce the world, the flaw, the 'A' story cast.",
                  filmExample: "Legally Blonde — Warner, Vivian, the engagement hopes.",
                  emotionalValence: 0.1),
        StoryBeat(name: "Catalyst", actLabel: "Act 1", timingPercent: 0.12,
                  defaultPrompt: "Life-changing event. Status quo ends.",
                  filmExample: "Legally Blonde — Warner dumps Elle.",
                  emotionalValence: -0.6),
        StoryBeat(name: "Debate", actLabel: "Act 1", timingPercent: 0.18,
                  defaultPrompt: "Should they take the journey? Brief hesitation.",
                  filmExample: "Legally Blonde — she cries, then gets the LSAT books.",
                  emotionalValence: -0.3),
        StoryBeat(name: "Break into Two", actLabel: "Act 2A", timingPercent: 0.25,
                  defaultPrompt: "Protagonist chooses the adventure. New world begins.",
                  filmExample: "Legally Blonde — Elle arrives at Harvard.",
                  emotionalValence: 0.2),
        StoryBeat(name: "B Story", actLabel: "Act 2A", timingPercent: 0.30,
                  defaultPrompt: "Introduce the subplot that carries the theme.",
                  filmExample: "Legally Blonde — Paulette at the salon.",
                  emotionalValence: 0.3),
        StoryBeat(name: "Fun and Games", actLabel: "Act 2A", timingPercent: 0.40,
                  defaultPrompt: "The promise of the premise. Trailer moments.",
                  filmExample: "Legally Blonde — pink laptop in class, bend-and-snap.",
                  emotionalValence: 0.5),
        StoryBeat(name: "Midpoint", actLabel: "Act 2A", timingPercent: 0.50,
                  defaultPrompt: "False victory or false defeat. Raises stakes.",
                  filmExample: "Legally Blonde — Elle gets the internship.",
                  emotionalValence: 0.6),
        StoryBeat(name: "Bad Guys Close In", actLabel: "Act 2B", timingPercent: 0.60,
                  defaultPrompt: "External opposition grows. Internal doubts surface.",
                  filmExample: "Legally Blonde — Callahan harasses her.",
                  emotionalValence: -0.2),
        StoryBeat(name: "All Is Lost", actLabel: "Act 2B", timingPercent: 0.75,
                  defaultPrompt: "The darkest moment. A 'whiff of death'.",
                  filmExample: "Legally Blonde — Elle packs to quit law.",
                  emotionalValence: -0.85),
        StoryBeat(name: "Dark Night of the Soul", actLabel: "Act 2B", timingPercent: 0.80,
                  defaultPrompt: "Protagonist confronts what they've lost. Grieves.",
                  filmExample: "Legally Blonde — the pink hoodie scene with Paulette.",
                  emotionalValence: -0.5),
        StoryBeat(name: "Break into Three", actLabel: "Act 3", timingPercent: 0.85,
                  defaultPrompt: "Epiphany. Protagonist finds the solution.",
                  filmExample: "Legally Blonde — she returns to court, in her voice.",
                  emotionalValence: 0.3),
        StoryBeat(name: "Finale", actLabel: "Act 3", timingPercent: 0.92,
                  defaultPrompt: "Storm the castle. Apply the lesson learned.",
                  filmExample: "Legally Blonde — the perm cross-examination.",
                  emotionalValence: 0.85),
        StoryBeat(name: "Final Image", actLabel: "Act 3", timingPercent: 0.99,
                  defaultPrompt: "After-picture — opposite of the opening.",
                  filmExample: "Legally Blonde — valedictorian speech at graduation.",
                  emotionalValence: 0.9)
    ]

    private static let herosJourney: [StoryBeat] = [
        StoryBeat(name: "Ordinary World", actLabel: "Act 1", timingPercent: 0.03,
                  defaultPrompt: "The hero's pre-adventure life. Establish flaw, want, daily rhythm.",
                  filmExample: "Star Wars — Luke on the Lars moisture farm.",
                  emotionalValence: 0.0),
        StoryBeat(name: "Call to Adventure", actLabel: "Act 1", timingPercent: 0.10,
                  defaultPrompt: "A challenge arrives that breaks the ordinary.",
                  filmExample: "Star Wars — Leia's holographic message.",
                  emotionalValence: 0.1),
        StoryBeat(name: "Refusal of the Call", actLabel: "Act 1", timingPercent: 0.15,
                  defaultPrompt: "The hero hesitates, from fear, obligation, or disbelief.",
                  filmExample: "Star Wars — Luke: \"I can't get involved.\"",
                  emotionalValence: -0.2),
        StoryBeat(name: "Meeting the Mentor", actLabel: "Act 1", timingPercent: 0.20,
                  defaultPrompt: "A guide provides tools, advice, or magic.",
                  filmExample: "Star Wars — Obi-Wan gives Luke the lightsaber.",
                  emotionalValence: 0.3),
        StoryBeat(name: "Crossing the Threshold", actLabel: "Act 1", timingPercent: 0.25,
                  defaultPrompt: "Enter the special world. No turning back.",
                  filmExample: "Star Wars — Tatooine cantina, then the Falcon.",
                  emotionalValence: 0.4),
        StoryBeat(name: "Tests, Allies, Enemies", actLabel: "Act 2", timingPercent: 0.40,
                  defaultPrompt: "The hero learns the rules of the new world. Forms a fellowship.",
                  filmExample: "Star Wars — escaping Alderaan, meeting Han.",
                  emotionalValence: 0.2),
        StoryBeat(name: "Approach the Inmost Cave", actLabel: "Act 2", timingPercent: 0.55,
                  defaultPrompt: "The hero nears the central ordeal. Last preparations.",
                  filmExample: "Star Wars — Death Star tractor beam.",
                  emotionalValence: -0.1),
        StoryBeat(name: "Ordeal", actLabel: "Act 2", timingPercent: 0.65,
                  defaultPrompt: "The central life-or-death challenge. A symbolic death.",
                  filmExample: "Star Wars — Obi-Wan's death.",
                  emotionalValence: -0.7),
        StoryBeat(name: "Reward", actLabel: "Act 2", timingPercent: 0.72,
                  defaultPrompt: "The hero seizes the sword/elixir. Celebration shadowed by cost.",
                  filmExample: "Star Wars — Leia rescued, plans recovered.",
                  emotionalValence: 0.5),
        StoryBeat(name: "The Road Back", actLabel: "Act 3", timingPercent: 0.82,
                  defaultPrompt: "Return to the ordinary world — pursued, changed.",
                  filmExample: "Star Wars — flight back to the Rebel base.",
                  emotionalValence: 0.2),
        StoryBeat(name: "Resurrection", actLabel: "Act 3", timingPercent: 0.90,
                  defaultPrompt: "The climactic test. The hero applies everything learned.",
                  filmExample: "Star Wars — the Death Star trench run.",
                  emotionalValence: 0.85),
        StoryBeat(name: "Return with the Elixir", actLabel: "Act 3", timingPercent: 0.98,
                  defaultPrompt: "The hero returns, transformed, with wisdom/tools for the world.",
                  filmExample: "Star Wars — the medal ceremony.",
                  emotionalValence: 0.9)
    ]

    private static let kishotenketsu: [StoryBeat] = [
        StoryBeat(name: "Ki — Introduction", actLabel: "Act 1", timingPercent: 0.05,
                  defaultPrompt: "Establish characters and their world. Gentle, observational.",
                  filmExample: "Totoro — Satsuki and Mei move into the countryside house.",
                  emotionalValence: 0.2),
        StoryBeat(name: "Shō — Development", actLabel: "Act 2", timingPercent: 0.35,
                  defaultPrompt: "Deepen the world. Expand character rhythms. No escalation.",
                  filmExample: "Totoro — exploring the house, dust sprites, the forest.",
                  emotionalValence: 0.4),
        StoryBeat(name: "Ten — Twist", actLabel: "Act 3", timingPercent: 0.65,
                  defaultPrompt: "A new element arrives and recontextualizes what we've seen.",
                  filmExample: "Totoro — Mei discovers the forest spirit.",
                  emotionalValence: 0.7),
        StoryBeat(name: "Ketsu — Conclusion", actLabel: "Act 4", timingPercent: 0.95,
                  defaultPrompt: "Synthesis. The pieces harmonize. No 'winner', only resonance.",
                  filmExample: "Totoro — Catbus, the hospital, the smiling corn.",
                  emotionalValence: 0.8)
    ]

    private static let inMediasRes: [StoryBeat] = [
        StoryBeat(name: "Mid-Action Opening", actLabel: "Act 1", timingPercent: 0.02,
                  defaultPrompt: "Start at a high-tension moment — the audience is catching up.",
                  filmExample: "Fight Club — gun in mouth, staring down the elevator shaft.",
                  emotionalValence: -0.5),
        StoryBeat(name: "Context Flashback", actLabel: "Act 1", timingPercent: 0.15,
                  defaultPrompt: "Flash back to earlier. Plant who, where, why.",
                  filmExample: "Fight Club — \"I can't sleep.\"",
                  emotionalValence: -0.2),
        StoryBeat(name: "Escalation Toward Opening", actLabel: "Act 2", timingPercent: 0.45,
                  defaultPrompt: "Story marches forward toward the moment we opened on.",
                  filmExample: "Fight Club — Project Mayhem scales up.",
                  emotionalValence: 0.1),
        StoryBeat(name: "Catching Up to the Open", actLabel: "Act 2", timingPercent: 0.70,
                  defaultPrompt: "Audience arrives at the opening scene — now with context.",
                  filmExample: "Fight Club — we return to the elevator shaft.",
                  emotionalValence: -0.6),
        StoryBeat(name: "Reveal", actLabel: "Act 3", timingPercent: 0.82,
                  defaultPrompt: "The twist or truth the whole flashback was preparing.",
                  filmExample: "Fight Club — \"I am Jack's complete lack of surprise.\"",
                  emotionalValence: -0.8),
        StoryBeat(name: "Resolution Beyond", actLabel: "Act 3", timingPercent: 0.96,
                  defaultPrompt: "Story pushes past the opening moment to a new ending.",
                  filmExample: "Fight Club — \"You met me at a very strange time in my life.\"",
                  emotionalValence: 0.3)
    ]

    // ---- Bible library ----

    static let bibles: [StoryBible] = [
        neonRequiem,
        lanternKeeper,
        paperMoon,
        tideAndBone
    ]

    // MARK: Neon Requiem — 100%, Save the Cat
    static let neonRequiem: StoryBible = {
        let elena = StoryCharacterDraft(
            name: "Elena",
            role: "Protagonist",
            want: "Find out who erased her partner's memory.",
            need: "Accept that some things can't be recovered — only mourned.",
            ghost: "Her sister vanished during a memory-black-market raid a decade ago. Elena was holding her hand.",
            flaw: "Treats every case like a second chance to save someone already lost.",
            stakes: "If she fails: the whole precinct's records get wiped by morning.",
            voice: "Clipped, observational, half-sentences trailing into smoke."
        )
        let marcus = StoryCharacterDraft(
            name: "Marcus",
            role: "Antagonist",
            want: "Keep the memory cartel's ledger out of police hands.",
            need: "Face that he became the very thing his old partner warned him about.",
            ghost: "Let a witness die to protect a source. Never told anyone.",
            flaw: "Mistakes loyalty for ethics.",
            stakes: "If Elena gets the ledger, his family is the next erasure.",
            voice: "Low, patient, lets silences do most of the work."
        )
        let drafts = [elena, marcus]
        let structure = StoryStructureDraft(template: .saveTheCat, beats: StoryStructureTemplate.saveTheCat.defaultBeats.annotated([
            "Rain on neon, detective Elena alone at the noodle stall.",
            "Marcus to a young cop: \"Memory's just a story you tell yourself enough.\"",
            "Introduce the memory-erasure market. Elena's apartment wallpapered with open cases.",
            "Elena's old partner is found with his memory wiped clean.",
            "She almost walks away — then hears her own name on his last logged voice memo.",
            "She goes off-book. Breaks into the Saigon archive.",
            "Meets Yuki, the black-market archivist who stole a backup copy.",
            "Running chase through the arcade arcology.",
            "Elena finds a personal file she doesn't remember writing.",
            "Marcus closes ranks. Internal Affairs pulls her badge.",
            "Yuki is killed. The backup is burned.",
            "Elena sits with the ashes, understands what she's been doing for ten years.",
            "She reconstructs the file from her own unreliable memory.",
            "Confrontation with Marcus in the flooded server room.",
            "Elena walks out into dawn without the answer, but lighter."
        ]))
        let scenes: [SceneBreakdown] = [
            SceneBreakdown(number: 1, title: "Rain-slick Alley", location: "Shibuya Alley", isInterior: false, timeOfDay: .night,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Establish Elena, the city, the rules.",
                           conflict: "An internal one — she's stalling on a case she can't explain.",
                           emotionalBeat: "Lonely competence.",
                           visualMetaphor: "Neon reflections fragment her face across puddles.",
                           transitionNote: "Hard cut to the morgue — continuity of wet surfaces."),
            SceneBreakdown(number: 2, title: "The Empty Partner", location: "Precinct Morgue", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [elena.id, marcus.id],
                           sceneGoal: "Elena discovers her partner has been memory-wiped.",
                           conflict: "Marcus officially closes the case in front of her.",
                           emotionalBeat: "Vertigo, suppressed rage.",
                           visualMetaphor: "Fluorescent flicker synced to her pulse.",
                           transitionNote: "Smash cut to her apartment — from public mask to private chaos."),
            SceneBreakdown(number: 3, title: "Wallpaper of Ghosts", location: "Elena's Apartment", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Reveal the decade-long pattern. Seed the sister.",
                           conflict: "Past self vs. present self.",
                           emotionalBeat: "Obsession, barely contained.",
                           visualMetaphor: "Case threads form a rough constellation — but one star is missing.",
                           transitionNote: "L-cut — her breath carries into the next scene."),
            SceneBreakdown(number: 4, title: "Ledger Descent", location: "Saigon Archive", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Break-in to steal the cartel's ledger.",
                           conflict: "Archive's own security vs. her improvised methods.",
                           emotionalBeat: "Adrenaline as meditation.",
                           visualMetaphor: "Every drawer she opens is another version of herself.",
                           transitionNote: "Match cut on a slamming drawer → Yuki's door opening."),
            SceneBreakdown(number: 5, title: "Yuki's Workshop", location: "Back-alley Workshop", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Meet ally. Learn a backup exists.",
                           conflict: "Yuki wants payment Elena can't pay.",
                           emotionalBeat: "Tentative trust.",
                           visualMetaphor: "Two reflections of Elena — in Yuki's glasses and in a monitor.",
                           transitionNote: "Dissolve — time compression into the midpoint chase."),
            SceneBreakdown(number: 6, title: "Arcology Chase", location: "Arcade Arcology", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [elena.id, marcus.id],
                           sceneGoal: "Cartel thugs pursue Elena and Yuki.",
                           conflict: "Geometry of the arcology vs. Elena's speed.",
                           emotionalBeat: "Panic that sharpens into focus.",
                           visualMetaphor: "Escalators running the wrong way.",
                           transitionNote: "Cut on flash of white — into the personal file."),
            SceneBreakdown(number: 7, title: "The File With Her Name", location: "Safehouse", isInterior: true, timeOfDay: .dawn,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Discover she authored and wiped her own file.",
                           conflict: "Elena vs. Elena.",
                           emotionalBeat: "A cold, perfect horror.",
                           visualMetaphor: "Dawn light turning her handwriting into someone else's.",
                           transitionNote: "Linger on the page; audio carries to precinct."),
            SceneBreakdown(number: 8, title: "Badge on the Desk", location: "Marcus's Office", isInterior: true, timeOfDay: .day,
                           characterDraftIDs: [elena.id, marcus.id],
                           sceneGoal: "Marcus pulls her off the case and her badge.",
                           conflict: "Institutional loyalty vs. truth.",
                           emotionalBeat: "Controlled fury.",
                           visualMetaphor: "Marcus's photo of his family — blurred, almost erased.",
                           transitionNote: "Slow push-in on the empty holster clip."),
            SceneBreakdown(number: 9, title: "Yuki's Last Call", location: "Yuki's Workshop", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Yuki is killed; backup is destroyed.",
                           conflict: "Elena arrives moments too late.",
                           emotionalBeat: "Guilt that tastes like iron.",
                           visualMetaphor: "A monitor still blinking the word PLAY.",
                           transitionNote: "Jump cut across three failed attempts to revive the drive."),
            SceneBreakdown(number: 10, title: "Ashes", location: "Rooftop", isInterior: false, timeOfDay: .dusk,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Elena sits with the loss. The dark night of the soul.",
                           conflict: "Wanting to quit vs. wanting to know.",
                           emotionalBeat: "Grief distilled.",
                           visualMetaphor: "City smoke and her cigarette smoke — same grey.",
                           transitionNote: "Slow fade to black. Ambient city dies."),
            SceneBreakdown(number: 11, title: "Reconstruction", location: "Elena's Apartment", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Rebuild the file from memory — knowing it will be partial.",
                           conflict: "Perfection vs. enough.",
                           emotionalBeat: "Discipline replacing rage.",
                           visualMetaphor: "Every crossed-out line becomes a landmark.",
                           transitionNote: "Wipe — left to right, page to corridor."),
            SceneBreakdown(number: 12, title: "Server Flood", location: "Precinct Sublevel", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [elena.id, marcus.id],
                           sceneGoal: "Final confrontation with Marcus.",
                           conflict: "Truth vs. the cost of revealing it.",
                           emotionalBeat: "A long, cold satisfaction.",
                           visualMetaphor: "Rising water reflecting server blinkenlights like stars.",
                           transitionNote: "Match cut — water → sunlight."),
            SceneBreakdown(number: 13, title: "Dawn", location: "Precinct Rooftop", isInterior: false, timeOfDay: .dawn,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Resolution — she walks out lighter, unanswered.",
                           conflict: "None. Acceptance.",
                           emotionalBeat: "Open hand.",
                           visualMetaphor: "Her shadow finally attached to her feet again.",
                           transitionNote: "Hard cut to black. End title with a distant siren."),
            SceneBreakdown(number: 14, title: "Coda", location: "Noodle Stall", isInterior: false, timeOfDay: .night,
                           characterDraftIDs: [elena.id],
                           sceneGoal: "Mirror of the opening image. Changed, quietly.",
                           conflict: "Absent.",
                           emotionalBeat: "Warmth.",
                           visualMetaphor: "Steam rising where rain fell in scene 1.",
                           transitionNote: "End.")
        ]
        let theme = ThemeTracker(
            themeStatement: "Memory is the only thing you can lose twice.",
            motifs: [
                VisualMotif(label: "Rain & Reflection", symbol: "cloud.rain.fill", tint: Theme.teal, frequency: 8),
                VisualMotif(label: "Neon Through Fog", symbol: "lightbulb.led.fill", tint: Theme.magenta, frequency: 6),
                VisualMotif(label: "Hands Holding Paper", symbol: "hand.raised.fill", tint: Theme.accent, frequency: 5),
                VisualMotif(label: "Erased Photographs", symbol: "photo", tint: Theme.violet, frequency: 4)
            ],
            palette: [
                ColorPaletteSwatch(hex: "#0C1324", color: Color(red: 0.05, green: 0.07, blue: 0.14), role: "World"),
                ColorPaletteSwatch(hex: "#481656", color: Color(red: 0.28, green: 0.09, blue: 0.34), role: "Antagonist"),
                ColorPaletteSwatch(hex: "#D94F7B", color: Color(red: 0.85, green: 0.31, blue: 0.48), role: "Protagonist"),
                ColorPaletteSwatch(hex: "#F3B249", color: Color(red: 0.95, green: 0.70, blue: 0.29), role: "Act 1"),
                ColorPaletteSwatch(hex: "#2F8E8A", color: Color(red: 0.18, green: 0.56, blue: 0.54), role: "Act 2"),
                ColorPaletteSwatch(hex: "#EAE4CF", color: Color(red: 0.92, green: 0.89, blue: 0.81), role: "Act 3")
            ]
        )
        return StoryBible(
            projectTitle: "Neon Requiem",
            logline: "A cybernetic detective chases a ghost through a city that never sleeps.",
            pitch: """
            Elena's a memory-detective in a rain-drenched city where erasure is for sale on the black market. When her old partner is found memory-wiped on her watch, she breaks every rule trying to recover his last moments — and stumbles into a personal file she doesn't remember writing. The closer she gets to the cartel's ledger, the more she realizes the only way to know who she is is to face what she chose to forget.
            """,
            lastUpdated: Date().addingTimeInterval(-7200),
            characterDrafts: [elena, marcus],
            structure: structure,
            sceneBreakdowns: scenes,
            theme: theme,
            posterColors: [Color(red: 0.55, green: 0.15, blue: 0.35), Color(red: 0.95, green: 0.45, blue: 0.25)]
        )
    }()

    // MARK: The Lantern Keeper — 65%, Hero's Journey through "Ordeal"
    static let lanternKeeper: StoryBible = {
        let nan = StoryCharacterDraft(
            name: "Nan",
            role: "Protagonist",
            want: "Keep the last flame of memory burning through the long winter.",
            need: "Pass the keeping on before she's gone — even if the heir isn't ready.",
            ghost: "She let her daughter leave the valley decades ago. Never heard back.",
            flaw: "Confuses stewardship with ownership.",
            stakes: "If the flame goes out: the village forgets its own name by spring.",
            voice: ""
        )
        let wren = StoryCharacterDraft(
            name: "Wren",
            role: "Reluctant Heir",
            want: "Leave the valley and find where stories are still written down.",
            need: "Understand that memory is a practice, not an escape.",
            ghost: "",
            flaw: "Mistakes movement for growth.",
            stakes: "If she refuses the keeping: everyone loses her mother's name first.",
            voice: "Wry, interrupts herself. Apologizes mid-sentence, then doesn't."
        )
        var structure = StoryStructureDraft(template: .herosJourney)
        // Annotate through "Ordeal" (index 7)
        let annotations: [String] = [
            "Nan lights the lantern in the attic, as she has every dusk for fifty years.",
            "A traveler arrives from beyond the pass, asking for Wren by name.",
            "Wren refuses to hear it — she's already packed for the coast.",
            "Nan finds her at the well. Gives her the smallest lantern, not the big one.",
            "They leave together at first light. The valley recedes.",
            "First test: a town that has already forgotten its own stories. Wren is unsettled.",
            "They reach the old ferry that only runs for lantern-keepers.",
            "The crossing — the lantern goes dark. Wren must relight it, alone, underwater."
        ]
        for (i, note) in annotations.enumerated() where i < structure.beats.count {
            structure.beats[i].userNotes = note
        }
        let scenes: [SceneBreakdown] = [
            SceneBreakdown(number: 1, title: "Attic Flame", location: "Nan's Cottage", isInterior: true, timeOfDay: .dusk,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "Open on the keeping ritual. Establish the world's rule.",
                           conflict: "Quiet — only the wind at the shutters.",
                           emotionalBeat: "Reverence, loneliness.",
                           visualMetaphor: "",
                           transitionNote: ""),
            SceneBreakdown(number: 2, title: "Visitor at the Gate", location: "Valley Road", isInterior: false, timeOfDay: .goldenHour,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "A messenger arrives asking for Wren.",
                           conflict: "Nan recognizes the messenger's coat.",
                           emotionalBeat: "",
                           visualMetaphor: "",
                           transitionNote: ""),
            SceneBreakdown(number: 3, title: "The Argument at the Well", location: "Village Well", isInterior: false, timeOfDay: .day,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "Wren refuses the keeping.",
                           conflict: "Duty vs. ambition.",
                           emotionalBeat: "",
                           visualMetaphor: "",
                           transitionNote: ""),
            SceneBreakdown(number: 4, title: "Small Lantern", location: "Nan's Cottage", isInterior: true, timeOfDay: .night,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "Nan passes the small lantern. Not a promise — a chance.",
                           conflict: "",
                           emotionalBeat: "",
                           visualMetaphor: "",
                           transitionNote: ""),
            SceneBreakdown(number: 5, title: "The Road Out", location: "Pass Road", isInterior: false, timeOfDay: .dawn,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "They leave. Nan tells a story Wren's mother loved.",
                           conflict: "",
                           emotionalBeat: "",
                           visualMetaphor: "",
                           transitionNote: ""),
            SceneBreakdown(number: 6, title: "The Forgetting Town", location: "Outer Market", isInterior: false, timeOfDay: .day,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "Wren sees what happens when keepers vanish.",
                           conflict: "",
                           emotionalBeat: "",
                           visualMetaphor: "",
                           transitionNote: ""),
            SceneBreakdown(number: 7, title: "The Ferry", location: "Black-Water Crossing", isInterior: false, timeOfDay: .dusk,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "Board the keeper-only ferry.",
                           conflict: "",
                           emotionalBeat: "",
                           visualMetaphor: "",
                           transitionNote: ""),
            SceneBreakdown(number: 8, title: "Underwater Light", location: "The Black Crossing", isInterior: false, timeOfDay: .night,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "Wren relights the lantern alone, submerged.",
                           conflict: "Fear vs. inheritance.",
                           emotionalBeat: "",
                           visualMetaphor: "",
                           transitionNote: ""),
            SceneBreakdown(number: 9, title: "Dry Shore", location: "Far Bank", isInterior: false, timeOfDay: .dawn,
                           characterDraftIDs: [nan.id],
                           sceneGoal: "They survive. Nan is weaker. Wren changes.",
                           conflict: "",
                           emotionalBeat: "",
                           visualMetaphor: "",
                           transitionNote: "")
        ]
        let theme = ThemeTracker(
            themeStatement: "Stewardship is practice, not ownership.",
            motifs: [
                VisualMotif(label: "Lantern Flame", symbol: "flame.fill", tint: Theme.accent, frequency: 9),
                VisualMotif(label: "Wool & Hand-Knit", symbol: "circle.grid.cross.fill", tint: Theme.teal, frequency: 4),
                VisualMotif(label: "Thresholds", symbol: "door.left.hand.open", tint: Theme.violet, frequency: 5)
            ],
            palette: [
                ColorPaletteSwatch(hex: "#0F1F2C", color: Color(red: 0.06, green: 0.12, blue: 0.17), role: "Valley Night"),
                ColorPaletteSwatch(hex: "#2F6E70", color: Color(red: 0.18, green: 0.43, blue: 0.44), role: "Water"),
                ColorPaletteSwatch(hex: "#C6A269", color: Color(red: 0.78, green: 0.64, blue: 0.41), role: "Lantern"),
                ColorPaletteSwatch(hex: "#E5D8B6", color: Color(red: 0.90, green: 0.85, blue: 0.71), role: "Protagonist")
            ]
        )
        return StoryBible(
            projectTitle: "The Lantern Keeper",
            logline: "An old woman guards the last flame of memory in a world turning to silence.",
            pitch: """
            In a remote valley where keeping a small flame alive is the only thing standing between a community and forgetting its own name, an old keeper named Nan has guarded the lantern for fifty years. When a messenger arrives asking for her estranged granddaughter Wren — who's already packed for the coast — Nan takes the small lantern off the shelf and walks Wren toward the black-water crossing where the keeping is passed on, or not.
            """,
            lastUpdated: Date().addingTimeInterval(-86_400),
            characterDrafts: [nan, wren],
            structure: structure,
            sceneBreakdowns: scenes,
            theme: theme,
            posterColors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.35, green: 0.65, blue: 0.75)]
        )
    }()

    // MARK: Paper Moon 2049 — 25%, theme + 2 drafts + Save the Cat selected
    static let paperMoon: StoryBible = {
        let ines = StoryCharacterDraft(
            name: "Inés",
            role: "Protagonist",
            want: "Trade dreams for oxygen credits.",
            need: "",
            ghost: "",
            flaw: "",
            stakes: "",
            voice: ""
        )
        let oskar = StoryCharacterDraft(
            name: "Oskar",
            role: "Dream Courier",
            want: "Quit the route and go silent.",
            need: "",
            ghost: "",
            flaw: "",
            stakes: "",
            voice: ""
        )
        let theme = ThemeTracker(
            themeStatement: "What we trade away defines us more than what we keep.",
            motifs: [
                VisualMotif(label: "Paper Currency", symbol: "banknote.fill", tint: Theme.lime, frequency: 3),
                VisualMotif(label: "Moon Through Glass", symbol: "moon.fill", tint: Theme.violet, frequency: 2)
            ],
            palette: []
        )
        return StoryBible(
            projectTitle: "Paper Moon 2049",
            logline: "Two strangers exchange dreams across a decaying lunar colony.",
            pitch: """
            On a decaying lunar colony where oxygen is currency and dreams are too, a courier named Oskar wants out of the route and a trader named Inés wants out of her debts. Both are about to discover that what they're trading away has been quietly defining who they are — and the colony's last functioning dreambox is about to make them a final offer.
            """,
            lastUpdated: Date().addingTimeInterval(-259_200),
            characterDrafts: [ines, oskar],
            structure: StoryStructureDraft(template: .saveTheCat),
            sceneBreakdowns: [],
            theme: theme,
            posterColors: [Color(red: 0.2, green: 0.1, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.85)]
        )
    }()

    // MARK: Tide & Bone — 100%, Three-Act
    static let tideAndBone: StoryBible = {
        let mara = StoryCharacterDraft(
            name: "Mara",
            role: "Protagonist",
            want: "Identify the skeleton in the tide pool before the village council can bury it.",
            need: "Forgive the coast that raised her for what it took.",
            ghost: "Her brother drowned off this beach when she was twelve. She told him the tide was safe.",
            flaw: "Confuses investigation with atonement.",
            stakes: "If she's wrong: a crime gets buried and her credibility with it.",
            voice: "Patient, methodical, uses the wrong technical term on purpose to catch out liars."
        )
        let ewan = StoryCharacterDraft(
            name: "Ewan",
            role: "Village Historian",
            want: "Protect the village from outside scrutiny.",
            need: "Accept that silence is what let the first wound happen.",
            ghost: "He knew about the body for decades.",
            flaw: "Mistakes loyalty for protection.",
            stakes: "If Mara succeeds, his father's name goes in the paper.",
            voice: "Over-precise, apologetic, but watch the eyes."
        )
        let structure = StoryStructureDraft(template: .threeAct, beats: StoryStructureTemplate.threeAct.defaultBeats.annotated([
            "Mara returns to Harrow Cove. The beach looks the way her brother last saw it.",
            "A storm surfaces bones in the tide pool. Not her brother — someone older.",
            "She files to keep the remains. The council files to bury them.",
            "Teeth-marks on the ribs don't match any local predator. She starts asking.",
            "A photograph in Ewan's study names a sailor missing since 1971.",
            "Her key evidence disappears from the cottage. Ewan is found on the rocks.",
            "Mara names the killer at the council hearing — not Ewan.",
            "The tide comes in. She doesn't try to stop it."
        ]))
        let sceneTitles: [(String, String, TimeOfDay)] = [
            ("Return to Harrow Cove", "Harrow Cove", .dusk),
            ("The Tide Pool", "Harrow Cove", .dawn),
            ("Council Meeting", "Village Hall", .day),
            ("Teeth & Ribs", "Mara's Cottage Lab", .night),
            ("Ewan's Study", "Ewan's House", .night),
            ("Pub Conversation", "The Pelican Pub", .night),
            ("The Missing Sailor", "Archive Basement", .day),
            ("Storm Warning", "Coast Road", .dusk),
            ("Break-In", "Mara's Cottage Lab", .night),
            ("Ewan on the Rocks", "Harrow Cove", .dawn),
            ("Funeral Without a Name", "Village Cemetery", .day),
            ("Sea Caves", "Black Stacks", .night),
            ("Conversation at the Light", "Lighthouse", .night),
            ("Council Hearing", "Village Hall", .day),
            ("Naming the Killer", "Village Hall", .day),
            ("Walk to the Water", "Harrow Cove", .dusk),
            ("Tide Rising", "Harrow Cove", .night),
            ("After", "Cottage Porch", .dawn)
        ]
        let scenes: [SceneBreakdown] = sceneTitles.enumerated().map { (i, t) in
            SceneBreakdown(
                number: i + 1,
                title: t.0,
                location: t.1,
                isInterior: t.1.lowercased().contains("cottage") || t.1.lowercased().contains("hall") || t.1.lowercased().contains("house") || t.1.lowercased().contains("pub") || t.1.lowercased().contains("archive") || t.1.lowercased().contains("lab") || t.1.lowercased().contains("lighthouse"),
                timeOfDay: t.2,
                characterDraftIDs: [mara.id],
                sceneGoal: "Beat \(i + 1) of Mara's reckoning with the coast.",
                conflict: "Truth vs. the village's quiet.",
                emotionalBeat: "Tidal — withholding and release.",
                visualMetaphor: "",
                transitionNote: ""
            )
        }
        let theme = ThemeTracker(
            themeStatement: "The coast keeps what you hand it, in its own time.",
            motifs: [
                VisualMotif(label: "Tide Line", symbol: "water.waves", tint: Theme.teal, frequency: 11),
                VisualMotif(label: "Bones in Sand", symbol: "staroflife.fill", tint: Color(red: 0.85, green: 0.78, blue: 0.55), frequency: 4),
                VisualMotif(label: "Lighthouse Beam", symbol: "light.beacon.max.fill", tint: Theme.accent, frequency: 5)
            ],
            palette: [
                ColorPaletteSwatch(hex: "#0E2832", color: Color(red: 0.05, green: 0.16, blue: 0.20), role: "Sea"),
                ColorPaletteSwatch(hex: "#3EA5B0", color: Color(red: 0.24, green: 0.65, blue: 0.69), role: "Act 1"),
                ColorPaletteSwatch(hex: "#B6A178", color: Color(red: 0.71, green: 0.63, blue: 0.47), role: "Sand"),
                ColorPaletteSwatch(hex: "#E8E2CC", color: Color(red: 0.91, green: 0.88, blue: 0.80), role: "Protagonist"),
                ColorPaletteSwatch(hex: "#8A2A2A", color: Color(red: 0.54, green: 0.16, blue: 0.16), role: "Act 3")
            ]
        )
        return StoryBible(
            projectTitle: "Tide & Bone",
            logline: "A biologist uncovers something ancient buried beneath her childhood beach.",
            pitch: """
            A biologist returns to the cove where her brother drowned, intent on identifying the skeleton a storm has surfaced in the tide pool before the village council can bury it. The teeth-marks don't match any local predator, and the deeper she digs, the clearer it becomes that the village's quiet has been holding something — and someone — for decades.
            """,
            lastUpdated: Date(),
            characterDrafts: [mara, ewan],
            structure: structure,
            sceneBreakdowns: scenes,
            theme: theme,
            posterColors: [Color(red: 0.08, green: 0.22, blue: 0.30), Color(red: 0.25, green: 0.78, blue: 0.82)]
        )
    }()
}

// MARK: - Helpers

private extension Array where Element == StoryBeat {
    /// Attach user notes in order. Extra notes are ignored; missing notes leave existing notes intact.
    func annotated(_ notes: [String]) -> [StoryBeat] {
        enumerated().map { (i, beat) in
            guard i < notes.count else { return beat }
            var b = beat
            b.userNotes = notes[i]
            return b
        }
    }
}
