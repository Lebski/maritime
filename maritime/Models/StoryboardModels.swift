import SwiftUI

// MARK: - Storyboard Models
//
// A StoryboardSequence is an ordered list of StoryboardPanels that plans a
// scene's shot coverage. Sequences can originate from a Story Forge
// SceneBreakdown (via sceneBreakdownID) or be authored fresh.
//
// Panels describe shot type, camera movement, duration, action note, dialogue,
// and the editing priority driving the cut (Murch's simplified triad:
// emotion / story / rhythm). A panel can be promoted into Scene Builder as
// a FilmScene — the stamp is kept on promotedFilmSceneID.

enum CameraMovement: String, CaseIterable, Identifiable, Hashable {
    case `static` = "Static"
    case pan      = "Pan"
    case tilt     = "Tilt"
    case zoomIn   = "Zoom In"
    case zoomOut  = "Zoom Out"
    case dolly    = "Dolly"
    case tracking = "Tracking"
    case handheld = "Handheld"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .static:   return "LOCKED"
        case .pan:      return "PAN"
        case .tilt:     return "TILT"
        case .zoomIn:   return "ZOOM IN"
        case .zoomOut:  return "ZOOM OUT"
        case .dolly:    return "DOLLY"
        case .tracking: return "TRACK"
        case .handheld: return "HH"
        }
    }

    var icon: String {
        switch self {
        case .static:   return "viewfinder"
        case .pan:      return "arrow.left.and.right"
        case .tilt:     return "arrow.up.and.down"
        case .zoomIn:   return "plus.magnifyingglass"
        case .zoomOut:  return "minus.magnifyingglass"
        case .dolly:    return "arrow.forward"
        case .tracking: return "figure.walk.motion"
        case .handheld: return "hand.raised.fill"
        }
    }

    var description: String {
        switch self {
        case .static:   return "Locked-off frame. The composition does the work."
        case .pan:      return "Horizontal sweep from a fixed pivot. Reveals geography."
        case .tilt:     return "Vertical sweep from a fixed pivot. Reveals scale."
        case .zoomIn:   return "Optical push. Tightens emotion without moving the body."
        case .zoomOut:  return "Optical pull. Places the subject in a wider context."
        case .dolly:    return "Camera body moves through space. Changes perspective, not just magnification."
        case .tracking: return "Follows the subject. Kept steady parallel to motion."
        case .handheld: return "Operator-carried. Urgency, subjectivity, breath in the frame."
        }
    }
}

enum EditingPriority: String, CaseIterable, Identifiable, Hashable {
    case emotion = "Emotion"
    case story   = "Story"
    case rhythm  = "Rhythm"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .emotion: return Theme.magenta
        case .story:   return Theme.teal
        case .rhythm:  return Theme.accent
        }
    }

    var icon: String {
        switch self {
        case .emotion: return "heart.fill"
        case .story:   return "text.alignleft"
        case .rhythm:  return "metronome.fill"
        }
    }

    var explanation: String {
        switch self {
        case .emotion:
            return "Cut on how the audience should feel. Murch's first rule — if the emotion is right, the rest usually forgives itself."
        case .story:
            return "Cut to advance story. Each frame must move plot, relationship, or knowledge forward."
        case .rhythm:
            return "Cut on pacing. Match the scene's breath — staccato for panic, sustained for dread."
        }
    }
}

// MARK: - Panel

struct StoryboardPanel: Identifiable, Hashable {
    let id: UUID
    var number: Int
    var shotType: CameraShotType
    var cameraMovement: CameraMovement
    var duration: Double              // seconds
    var actionNote: String
    var dialogue: String
    var timeOfDay: TimeOfDay
    var editingPriority: EditingPriority
    var characterDraftIDs: [UUID]
    var thumbnailSymbol: String       // SF Symbol for atmospheric backdrop
    var thumbnailColors: [Color]      // gradient stops for the thumbnail background
    var promotedFilmSceneID: UUID?

    init(id: UUID = UUID(),
         number: Int,
         shotType: CameraShotType,
         cameraMovement: CameraMovement = .static,
         duration: Double = 2.5,
         actionNote: String = "",
         dialogue: String = "",
         timeOfDay: TimeOfDay = .day,
         editingPriority: EditingPriority = .emotion,
         characterDraftIDs: [UUID] = [],
         thumbnailSymbol: String = "square.grid.3x2",
         thumbnailColors: [Color] = [Theme.violet, Theme.magenta],
         promotedFilmSceneID: UUID? = nil) {
        self.id = id
        self.number = number
        self.shotType = shotType
        self.cameraMovement = cameraMovement
        self.duration = duration
        self.actionNote = actionNote
        self.dialogue = dialogue
        self.timeOfDay = timeOfDay
        self.editingPriority = editingPriority
        self.characterDraftIDs = characterDraftIDs
        self.thumbnailSymbol = thumbnailSymbol
        self.thumbnailColors = thumbnailColors
        self.promotedFilmSceneID = promotedFilmSceneID
    }

    var isPromoted: Bool { promotedFilmSceneID != nil }

    var durationLabel: String {
        String(format: "%.1fs", duration)
    }

    /// Completion score — action note + reasonable duration + at least one character assigned.
    var completion: Double {
        var score = 0.0
        if !actionNote.trimmingCharacters(in: .whitespaces).isEmpty { score += 0.5 }
        if duration >= 0.5 { score += 0.25 }
        if !characterDraftIDs.isEmpty { score += 0.25 }
        return score
    }
}

// MARK: - Sequence

struct StoryboardSequence: Identifiable, Hashable {
    let id: UUID
    var title: String
    var bibleID: UUID?
    var sceneBreakdownID: UUID?
    var projectTitle: String
    var posterColors: [Color]
    var panels: [StoryboardPanel]
    var lastUpdated: Date

    init(id: UUID = UUID(),
         title: String,
         bibleID: UUID? = nil,
         sceneBreakdownID: UUID? = nil,
         projectTitle: String,
         posterColors: [Color] = [Theme.violet, Theme.magenta],
         panels: [StoryboardPanel] = [],
         lastUpdated: Date = Date()) {
        self.id = id
        self.title = title
        self.bibleID = bibleID
        self.sceneBreakdownID = sceneBreakdownID
        self.projectTitle = projectTitle
        self.posterColors = posterColors
        self.panels = panels
        self.lastUpdated = lastUpdated
    }

    var totalRuntime: Double {
        panels.map(\.duration).reduce(0, +)
    }

    var averageShotLength: Double {
        guard !panels.isEmpty else { return 0 }
        return totalRuntime / Double(panels.count)
    }

    var runtimeLabel: String {
        let total = Int(totalRuntime.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    var completion: Double {
        guard !panels.isEmpty else { return 0 }
        return panels.map(\.completion).reduce(0, +) / Double(panels.count)
    }

    var promotedCount: Int {
        panels.filter(\.isPromoted).count
    }

    var unpromotedCount: Int {
        panels.count - promotedCount
    }

    var shotTypeHistogram: [(CameraShotType, Int)] {
        let grouped = Dictionary(grouping: panels, by: \.shotType)
        return CameraShotType.allCases.compactMap { type in
            guard let group = grouped[type], !group.isEmpty else { return nil }
            return (type, group.count)
        }
    }

    var priorityHistogram: [(EditingPriority, Int)] {
        let grouped = Dictionary(grouping: panels, by: \.editingPriority)
        return EditingPriority.allCases.map { priority in
            (priority, grouped[priority]?.count ?? 0)
        }
    }
}

// MARK: - Shot Type Reference

extension CameraShotType {
    var description: String {
        switch self {
        case .extremeCloseUp:
            return "Fills the frame with a single feature — an eye, a mouth, a hand. Withholds context so the audience is forced to feel."
        case .closeUp:
            return "Head-and-shoulders isolation. The workhorse of emotion — faces, reactions, the private moment."
        case .medium:
            return "Waist-up. The conversational shot. Body language and face share the frame."
        case .full:
            return "Head-to-toe. Body language reads as clearly as the setting."
        case .wide:
            return "Geography shot. Places characters inside their world. Works as an establisher or as release after intensity."
        case .overTheShoulder:
            return "Anchors a conversation in two bodies. One shoulder foregrounded, the other face framed. Implies relationship."
        case .pov:
            return "What the character sees. The audience rides inside their eyes — intimate or menacing depending on what's shown."
        case .dutchAngle:
            return "Tilted horizon. Unease, disorientation, a world slightly off its axis."
        case .lowAngle:
            return "Camera below eye-level, looking up. Confers power, menace, grandeur."
        case .highAngle:
            return "Camera above, looking down. Diminishes, observes, isolates."
        }
    }

    var filmExample: String {
        switch self {
        case .extremeCloseUp: return "Once Upon a Time in the West — Henry Fonda's eyes filling the scope frame."
        case .closeUp:        return "The Godfather — Michael's face before the restaurant shooting."
        case .medium:         return "Pulp Fiction — the diner booth, Vincent and Jules mid-argument."
        case .full:           return "Saturday Night Fever — Tony's walk down the Brooklyn sidewalk."
        case .wide:           return "Lawrence of Arabia — the match-cut sunrise over the dunes."
        case .overTheShoulder:return "Heat — Pacino and De Niro across the diner table."
        case .pov:            return "Jaws — the underwater POV stalking the swimmer."
        case .dutchAngle:     return "The Third Man — Harry Lime under the ferris-wheel."
        case .lowAngle:       return "There Will Be Blood — Daniel Plainview at the pulpit."
        case .highAngle:      return "The Shining — the hedge maze from above."
        }
    }

    var icon: String {
        switch self {
        case .extremeCloseUp:  return "eye.fill"
        case .closeUp:         return "person.crop.circle.fill"
        case .medium:          return "person.fill"
        case .full:            return "figure.stand"
        case .wide:            return "mountain.2.fill"
        case .overTheShoulder: return "person.2.fill"
        case .pov:             return "scope"
        case .dutchAngle:      return "angle"
        case .lowAngle:        return "arrow.up"
        case .highAngle:       return "arrow.down"
        }
    }
}

// MARK: - Sample Data

enum StoryboardSamples {

    // ---------- The Lantern Keeper — 9 panels (exact, matches SampleData.activity) ----------

    static let lanternKeeperSequence: StoryboardSequence = {
        let nightValley: [Color]   = [Color(red: 0.08, green: 0.12, blue: 0.22), Color(red: 0.25, green: 0.32, blue: 0.55)]
        let duskValley: [Color]    = [Color(red: 0.22, green: 0.12, blue: 0.32), Color(red: 0.85, green: 0.45, blue: 0.35)]
        let lanternGlow: [Color]   = [Color(red: 0.35, green: 0.15, blue: 0.05), Color(red: 1.0, green: 0.72, blue: 0.29)]
        let dawnShore: [Color]     = [Color(red: 0.12, green: 0.20, blue: 0.35), Color(red: 0.95, green: 0.75, blue: 0.55)]
        let underwater: [Color]    = [Color(red: 0.03, green: 0.08, blue: 0.18), Color(red: 0.15, green: 0.45, blue: 0.55)]
        let valleyDay: [Color]     = [Color(red: 0.18, green: 0.25, blue: 0.35), Color(red: 0.65, green: 0.75, blue: 0.80)]
        let ferryTwilight: [Color] = [Color(red: 0.06, green: 0.10, blue: 0.20), Color(red: 0.38, green: 0.28, blue: 0.55)]

        let panels: [StoryboardPanel] = [
            StoryboardPanel(number: 1,
                            shotType: .wide,
                            cameraMovement: .dolly,
                            duration: 4.5,
                            actionNote: "Nan lights the attic lantern. The flame catches and holds. Outside the shutter, first dusk.",
                            dialogue: "",
                            timeOfDay: .dusk,
                            editingPriority: .emotion,
                            thumbnailSymbol: "flame.fill",
                            thumbnailColors: lanternGlow),
            StoryboardPanel(number: 2,
                            shotType: .closeUp,
                            cameraMovement: .static,
                            duration: 2.8,
                            actionNote: "Macro of the flame — it shivers once, settles, casts light across her face.",
                            dialogue: "",
                            timeOfDay: .dusk,
                            editingPriority: .emotion,
                            thumbnailSymbol: "flame.fill",
                            thumbnailColors: lanternGlow),
            StoryboardPanel(number: 3,
                            shotType: .overTheShoulder,
                            cameraMovement: .static,
                            duration: 2.2,
                            actionNote: "OTS on Nan as she opens the cottage door. A messenger stands in the gold-hour wind.",
                            dialogue: "I was told to ask for Wren.",
                            timeOfDay: .goldenHour,
                            editingPriority: .story,
                            thumbnailSymbol: "door.left.hand.open",
                            thumbnailColors: duskValley),
            StoryboardPanel(number: 4,
                            shotType: .medium,
                            cameraMovement: .pan,
                            duration: 3.0,
                            actionNote: "Messenger's coat bears Wren's mother's crest. Nan recognizes it. Pan lands on the crest.",
                            dialogue: "",
                            timeOfDay: .goldenHour,
                            editingPriority: .story,
                            thumbnailSymbol: "seal.fill",
                            thumbnailColors: duskValley),
            StoryboardPanel(number: 5,
                            shotType: .pov,
                            cameraMovement: .tracking,
                            duration: 3.5,
                            actionNote: "Wren's POV walking to the village well. Her feet crunching. The valley framed in the bucket-rope.",
                            dialogue: "",
                            timeOfDay: .day,
                            editingPriority: .rhythm,
                            thumbnailSymbol: "scope",
                            thumbnailColors: valleyDay),
            StoryboardPanel(number: 6,
                            shotType: .lowAngle,
                            cameraMovement: .static,
                            duration: 2.5,
                            actionNote: "Low wide — Nan and Wren argue at the well. The stone rim dwarfs them against a high sky.",
                            dialogue: "Duty doesn't travel.",
                            timeOfDay: .day,
                            editingPriority: .story,
                            thumbnailSymbol: "figure.2",
                            thumbnailColors: valleyDay),
            StoryboardPanel(number: 7,
                            shotType: .extremeCloseUp,
                            cameraMovement: .zoomIn,
                            duration: 1.8,
                            actionNote: "ECU — Nan's weathered hand places the small lantern into Wren's palm. Flame reflected in Wren's eye.",
                            dialogue: "",
                            timeOfDay: .night,
                            editingPriority: .emotion,
                            thumbnailSymbol: "hand.raised.fill",
                            thumbnailColors: lanternGlow),
            StoryboardPanel(number: 8,
                            shotType: .dutchAngle,
                            cameraMovement: .handheld,
                            duration: 2.1,
                            actionNote: "Dutch on the ferry. Water sloshes. Wren grips the rail; the lantern in her other hand dims.",
                            dialogue: "",
                            timeOfDay: .dusk,
                            editingPriority: .rhythm,
                            thumbnailSymbol: "ferry.fill",
                            thumbnailColors: ferryTwilight),
            StoryboardPanel(number: 9,
                            shotType: .highAngle,
                            cameraMovement: .zoomOut,
                            duration: 3.8,
                            actionNote: "High wide — Wren on the far shore at dawn, lantern relit, Nan behind her leaning on the boat rail.",
                            dialogue: "",
                            timeOfDay: .dawn,
                            editingPriority: .emotion,
                            thumbnailSymbol: "sunrise.fill",
                            thumbnailColors: dawnShore)
        ]
        // Deliberately don't reference underwater/nightValley here — kept for future panels.
        _ = nightValley
        _ = underwater

        return StoryboardSequence(
            title: "Act I — The Keeping Passes",
            projectTitle: "The Lantern Keeper",
            posterColors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.35, green: 0.65, blue: 0.75)],
            panels: panels,
            lastUpdated: Date().addingTimeInterval(-3600)
        )
    }()

    // ---------- Neon Requiem — 12 panels, noir opening ----------

    static let neonRequiemSequence: StoryboardSequence = {
        let rainAlley: [Color]   = [Color(red: 0.05, green: 0.08, blue: 0.18), Color(red: 0.25, green: 0.32, blue: 0.55)]
        let neonPink: [Color]    = [Color(red: 0.22, green: 0.05, blue: 0.28), Color(red: 0.92, green: 0.35, blue: 0.62)]
        let noodleStall: [Color] = [Color(red: 0.20, green: 0.08, blue: 0.12), Color(red: 0.95, green: 0.62, blue: 0.35)]
        let morgue: [Color]      = [Color(red: 0.08, green: 0.12, blue: 0.18), Color(red: 0.45, green: 0.58, blue: 0.65)]

        let panels: [StoryboardPanel] = [
            StoryboardPanel(number: 1, shotType: .wide, cameraMovement: .dolly, duration: 4.0,
                            actionNote: "Slow push down rain-slick Shibuya alley. Neon bleeds into the puddles.",
                            timeOfDay: .night, editingPriority: .rhythm,
                            thumbnailSymbol: "cloud.rain.fill", thumbnailColors: rainAlley),
            StoryboardPanel(number: 2, shotType: .medium, cameraMovement: .static, duration: 2.5,
                            actionNote: "Elena at the noodle stall, eating alone. Steam rises past her face.",
                            timeOfDay: .night, editingPriority: .emotion,
                            thumbnailSymbol: "fork.knife", thumbnailColors: noodleStall),
            StoryboardPanel(number: 3, shotType: .extremeCloseUp, cameraMovement: .static, duration: 1.5,
                            actionNote: "ECU on her eyes — they flick to something off-frame.",
                            timeOfDay: .night, editingPriority: .emotion,
                            thumbnailSymbol: "eye.fill", thumbnailColors: noodleStall),
            StoryboardPanel(number: 4, shotType: .pov, cameraMovement: .tracking, duration: 3.2,
                            actionNote: "Her POV — a body is being loaded into a coroner's van two blocks down.",
                            timeOfDay: .night, editingPriority: .story,
                            thumbnailSymbol: "scope", thumbnailColors: rainAlley),
            StoryboardPanel(number: 5, shotType: .wide, cameraMovement: .handheld, duration: 2.2,
                            actionNote: "She's walking fast now. Neon signs smear as she passes them.",
                            timeOfDay: .night, editingPriority: .rhythm,
                            thumbnailSymbol: "figure.walk", thumbnailColors: neonPink),
            StoryboardPanel(number: 6, shotType: .overTheShoulder, cameraMovement: .static, duration: 2.8,
                            actionNote: "OTS at the morgue doors. Marcus in frame, hands in pockets.",
                            timeOfDay: .night, editingPriority: .story,
                            thumbnailSymbol: "person.2.fill", thumbnailColors: morgue),
            StoryboardPanel(number: 7, shotType: .closeUp, cameraMovement: .static, duration: 2.0,
                            actionNote: "CU on Marcus. He doesn't quite meet her eyes.",
                            dialogue: "You shouldn't be here.",
                            timeOfDay: .night, editingPriority: .emotion,
                            thumbnailSymbol: "person.crop.circle.fill", thumbnailColors: morgue),
            StoryboardPanel(number: 8, shotType: .closeUp, cameraMovement: .static, duration: 2.0,
                            actionNote: "CU on Elena. She doesn't answer.",
                            timeOfDay: .night, editingPriority: .emotion,
                            thumbnailSymbol: "person.crop.circle.fill", thumbnailColors: morgue),
            StoryboardPanel(number: 9, shotType: .dutchAngle, cameraMovement: .pan, duration: 2.5,
                            actionNote: "Dutch across the body bag. Tag reads her partner's name.",
                            timeOfDay: .night, editingPriority: .story,
                            thumbnailSymbol: "tag.fill", thumbnailColors: morgue),
            StoryboardPanel(number: 10, shotType: .extremeCloseUp, cameraMovement: .zoomIn, duration: 1.8,
                            actionNote: "ECU — the name tag. Pull focus from tag to her hand hovering over it.",
                            timeOfDay: .night, editingPriority: .emotion,
                            thumbnailSymbol: "hand.raised.fill", thumbnailColors: morgue),
            StoryboardPanel(number: 11, shotType: .dutchAngle, cameraMovement: .handheld, duration: 2.3,
                            actionNote: "Dutch on her face as she steadies herself against the cold slab.",
                            timeOfDay: .night, editingPriority: .emotion,
                            thumbnailSymbol: "person.fill", thumbnailColors: morgue),
            StoryboardPanel(number: 12, shotType: .wide, cameraMovement: .zoomOut, duration: 4.2,
                            actionNote: "Pull back through the morgue doors. Rain starts again behind glass. Smash to title.",
                            timeOfDay: .night, editingPriority: .rhythm,
                            thumbnailSymbol: "cloud.rain.fill", thumbnailColors: rainAlley)
        ]

        return StoryboardSequence(
            title: "Cold Open — Empty Partner",
            projectTitle: "Neon Requiem",
            posterColors: [Color(red: 0.55, green: 0.15, blue: 0.35), Color(red: 0.95, green: 0.45, blue: 0.25)],
            panels: panels,
            lastUpdated: Date().addingTimeInterval(-9_000)
        )
    }()

    // ---------- Tide & Bone — 7 panels, dawn discovery ----------

    static let tideAndBoneSequence: StoryboardSequence = {
        let dawnSea: [Color]    = [Color(red: 0.12, green: 0.20, blue: 0.30), Color(red: 0.72, green: 0.82, blue: 0.78)]
        let tidePool: [Color]   = [Color(red: 0.10, green: 0.28, blue: 0.32), Color(red: 0.55, green: 0.72, blue: 0.65)]
        let sandGold: [Color]   = [Color(red: 0.35, green: 0.30, blue: 0.22), Color(red: 0.85, green: 0.78, blue: 0.55)]

        let panels: [StoryboardPanel] = [
            StoryboardPanel(number: 1, shotType: .wide, cameraMovement: .static, duration: 4.8,
                            actionNote: "Wide — Harrow Cove at first light. Tide receding. Mara's silhouette on the ridge.",
                            timeOfDay: .dawn, editingPriority: .rhythm,
                            thumbnailSymbol: "water.waves", thumbnailColors: dawnSea),
            StoryboardPanel(number: 2, shotType: .medium, cameraMovement: .tracking, duration: 2.6,
                            actionNote: "Tracking Mara as she walks the beach. Her eyes scan the pools.",
                            timeOfDay: .dawn, editingPriority: .story,
                            thumbnailSymbol: "figure.walk", thumbnailColors: sandGold),
            StoryboardPanel(number: 3, shotType: .pov, cameraMovement: .tilt, duration: 2.0,
                            actionNote: "Her POV — she tilts down into a pool. Something white under kelp.",
                            timeOfDay: .dawn, editingPriority: .story,
                            thumbnailSymbol: "scope", thumbnailColors: tidePool),
            StoryboardPanel(number: 4, shotType: .closeUp, cameraMovement: .static, duration: 2.2,
                            actionNote: "CU on her face — the professional mask drops for half a second.",
                            timeOfDay: .dawn, editingPriority: .emotion,
                            thumbnailSymbol: "person.crop.circle.fill", thumbnailColors: dawnSea),
            StoryboardPanel(number: 5, shotType: .highAngle, cameraMovement: .static, duration: 2.8,
                            actionNote: "High angle over the pool. She kneels, moves the kelp aside.",
                            timeOfDay: .dawn, editingPriority: .rhythm,
                            thumbnailSymbol: "arrow.down", thumbnailColors: tidePool),
            StoryboardPanel(number: 6, shotType: .extremeCloseUp, cameraMovement: .zoomIn, duration: 1.6,
                            actionNote: "ECU — teeth-marks on a rib bone. Old. Not animal.",
                            timeOfDay: .dawn, editingPriority: .story,
                            thumbnailSymbol: "staroflife.fill", thumbnailColors: sandGold),
            StoryboardPanel(number: 7, shotType: .wide, cameraMovement: .zoomOut, duration: 3.5,
                            actionNote: "Slow pull back — she alone with the bones, sea rising again behind her.",
                            timeOfDay: .dawn, editingPriority: .emotion,
                            thumbnailSymbol: "water.waves", thumbnailColors: dawnSea)
        ]

        return StoryboardSequence(
            title: "Tide Pool Discovery",
            projectTitle: "Tide & Bone",
            posterColors: [Color(red: 0.08, green: 0.22, blue: 0.30), Color(red: 0.25, green: 0.78, blue: 0.82)],
            panels: panels,
            lastUpdated: Date().addingTimeInterval(-43_200)
        )
    }()

    // ---------- Paper Moon 2049 — empty, for empty-state showcase ----------

    static let paperMoonSequence: StoryboardSequence = StoryboardSequence(
        title: "Lunar Arrival (unplanned)",
        projectTitle: "Paper Moon 2049",
        posterColors: [Color(red: 0.2, green: 0.1, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.85)],
        panels: [],
        lastUpdated: Date().addingTimeInterval(-604_800)
    )

    static let sequences: [StoryboardSequence] = [
        lanternKeeperSequence,
        neonRequiemSequence,
        tideAndBoneSequence,
        paperMoonSequence
    ]
}
