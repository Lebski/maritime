import SwiftUI

// MARK: - Storyboard Models
//
// Panels describe shot type, camera movement, duration, action note, dialogue,
// and the editing priority driving the cut (Murch's simplified triad:
// emotion / story / rhythm). Panels are the unit of "shot": each one carries
// its own clip-time metadata (motion + approval) and a 1:N list of Frame IDs
// for keyframes. Panels that originated from a Story Forge SceneBreakdown
// carry the source ID on sceneBreakdownID so the UI can group by scene.

// MARK: - AI shot-breakdown plan
//
// Tracks AI generation state for a scene's shot breakdown. Panels still belong
// to the scene via `sceneBreakdownID`; the plan stores plumbing for the
// Storyboard "Generate breakdown" action.

enum AIBreakdownStatus: String, Codable, Hashable {
    case empty, generating, ready, failed
}

struct SceneShotPlan: Identifiable, Codable, Hashable {
    let id: UUID
    var sceneBreakdownID: UUID
    var status: AIBreakdownStatus
    var lastError: String?
    var lastGeneratedAt: Date?

    init(id: UUID = UUID(),
         sceneBreakdownID: UUID,
         status: AIBreakdownStatus = .empty,
         lastError: String? = nil,
         lastGeneratedAt: Date? = nil) {
        self.id = id
        self.sceneBreakdownID = sceneBreakdownID
        self.status = status
        self.lastError = lastError
        self.lastGeneratedAt = lastGeneratedAt
    }
}

enum CameraMovement: String, CaseIterable, Identifiable, Hashable, Codable {
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

enum EditingPriority: String, CaseIterable, Identifiable, Hashable, Codable {
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

struct StoryboardPanel: Identifiable, Hashable, Codable {
    let id: UUID
    var number: Int
    var shotType: CameraShotType
    var cameraMovement: CameraMovement
    var duration: Double              // seconds — drives the rendered clip length
    var actionNote: String
    var dialogue: String
    var timeOfDay: TimeOfDay
    var editingPriority: EditingPriority
    var characterDraftIDs: [UUID]
    var thumbnailSymbol: String       // SF Symbol for atmospheric backdrop
    var thumbnailColors: [Color]      // gradient stops for the thumbnail background
    var sceneBreakdownID: UUID?
    var pencilSketchAssetID: UUID?
    var aiBreakdownReasoning: String?
    var frameIDs: [UUID]              // 1:N keyframes — start, end, holds
    var clipMotion: MotionIntensity
    var clipApproved: Bool

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
         sceneBreakdownID: UUID? = nil,
         pencilSketchAssetID: UUID? = nil,
         aiBreakdownReasoning: String? = nil,
         frameIDs: [UUID] = [],
         clipMotion: MotionIntensity = .subtle,
         clipApproved: Bool = false) {
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
        self.sceneBreakdownID = sceneBreakdownID
        self.pencilSketchAssetID = pencilSketchAssetID
        self.aiBreakdownReasoning = aiBreakdownReasoning
        self.frameIDs = frameIDs
        self.clipMotion = clipMotion
        self.clipApproved = clipApproved
    }

    var hasFrames: Bool { !frameIDs.isEmpty }

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

// MARK: - Panel collection metrics

extension Array where Element == StoryboardPanel {
    var totalRuntime: Double {
        map(\.duration).reduce(0, +)
    }

    var averageShotLength: Double {
        guard !isEmpty else { return 0 }
        return totalRuntime / Double(count)
    }

    var runtimeLabel: String {
        let total = Int(totalRuntime.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    var completion: Double {
        guard !isEmpty else { return 0 }
        return map(\.completion).reduce(0, +) / Double(count)
    }

    var promotedCount: Int {
        filter(\.hasFrames).count
    }

    var unpromotedCount: Int {
        count - promotedCount
    }

    var shotTypeHistogram: [(CameraShotType, Int)] {
        let grouped = Dictionary(grouping: self, by: \.shotType)
        return CameraShotType.allCases.compactMap { type in
            guard let group = grouped[type], !group.isEmpty else { return nil }
            return (type, group.count)
        }
    }

    var priorityHistogram: [(EditingPriority, Int)] {
        let grouped = Dictionary(grouping: self, by: \.editingPriority)
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

    static let lanternKeeperPanels: [StoryboardPanel] = {
        let duskValley: [Color]    = [Color(red: 0.22, green: 0.12, blue: 0.32), Color(red: 0.85, green: 0.45, blue: 0.35)]
        let lanternGlow: [Color]   = [Color(red: 0.35, green: 0.15, blue: 0.05), Color(red: 1.0, green: 0.72, blue: 0.29)]
        let dawnShore: [Color]     = [Color(red: 0.12, green: 0.20, blue: 0.35), Color(red: 0.95, green: 0.75, blue: 0.55)]
        let valleyDay: [Color]     = [Color(red: 0.18, green: 0.25, blue: 0.35), Color(red: 0.65, green: 0.75, blue: 0.80)]
        let ferryTwilight: [Color] = [Color(red: 0.06, green: 0.10, blue: 0.20), Color(red: 0.38, green: 0.28, blue: 0.55)]

        return [
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
    }()
}
