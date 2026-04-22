import SwiftUI

// MARK: - Structure Templates

enum StructureTemplate: String, CaseIterable, Identifiable {
    case saveTheCat = "Save the Cat"
    case heroJourney = "Hero's Journey"
    case threeAct = "3-Act Structure"
    case fiveAct = "5-Act Structure"
    case freytag = "Freytag's Pyramid"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .saveTheCat: return "15 beats · Blake Snyder"
        case .heroJourney: return "12 stages · Campbell"
        case .threeAct: return "3 acts · Setup → Confrontation → Resolution"
        case .fiveAct: return "5 acts · Classical"
        case .freytag: return "Pyramid · Exposition → Dénouement"
        }
    }

    var icon: String {
        switch self {
        case .saveTheCat: return "cat.fill"
        case .heroJourney: return "figure.walk.circle.fill"
        case .threeAct: return "rectangle.split.3x1.fill"
        case .fiveAct: return "rectangle.split.3x3.fill"
        case .freytag: return "triangle.fill"
        }
    }

    var seedBeats: [Beat] {
        switch self {
        case .saveTheCat:
            return [
                .init(name: "Opening Image", pct: 0.01, summary: "A visual snapshot of the protagonist's world before change."),
                .init(name: "Theme Stated", pct: 0.05, summary: "A character hints at the story's thematic argument."),
                .init(name: "Set-Up", pct: 0.10, summary: "Introduce protagonist, world, and what must change."),
                .init(name: "Catalyst", pct: 0.12, summary: "The inciting incident interrupts the status quo."),
                .init(name: "Debate", pct: 0.20, summary: "Should the protagonist respond to the call?"),
                .init(name: "Break into Two", pct: 0.25, summary: "Protagonist commits to the new world."),
                .init(name: "B Story", pct: 0.30, summary: "A relationship subplot carrying the theme."),
                .init(name: "Fun & Games", pct: 0.50, summary: "The 'promise of the premise' plays out."),
                .init(name: "Midpoint", pct: 0.55, summary: "A false victory or false defeat raises stakes."),
                .init(name: "Bad Guys Close In", pct: 0.65, summary: "Internal and external pressure escalates."),
                .init(name: "All Is Lost", pct: 0.75, summary: "Protagonist hits rock bottom."),
                .init(name: "Dark Night of the Soul", pct: 0.80, summary: "A moment of reflection before the final push."),
                .init(name: "Break into Three", pct: 0.85, summary: "A new idea unites A and B stories."),
                .init(name: "Finale", pct: 0.95, summary: "The climax resolves the conflict."),
                .init(name: "Final Image", pct: 0.99, summary: "A mirror of the opening, showing transformation.")
            ]
        case .heroJourney:
            return [
                .init(name: "Ordinary World", pct: 0.05, summary: "The hero's status quo before adventure."),
                .init(name: "Call to Adventure", pct: 0.10, summary: "A challenge is presented."),
                .init(name: "Refusal", pct: 0.15, summary: "Hero hesitates or refuses the call."),
                .init(name: "Meeting the Mentor", pct: 0.20, summary: "Wisdom or gifts are given."),
                .init(name: "Crossing the Threshold", pct: 0.25, summary: "Hero commits to the special world."),
                .init(name: "Tests, Allies, Enemies", pct: 0.40, summary: "Hero learns the rules of the new world."),
                .init(name: "Approach the Cave", pct: 0.55, summary: "Preparation for the central ordeal."),
                .init(name: "The Ordeal", pct: 0.65, summary: "A life-or-death moment."),
                .init(name: "Reward", pct: 0.75, summary: "A prize or revelation is seized."),
                .init(name: "The Road Back", pct: 0.85, summary: "Hero faces consequences of the reward."),
                .init(name: "Resurrection", pct: 0.92, summary: "A final, highest-stakes test."),
                .init(name: "Return with Elixir", pct: 0.98, summary: "Hero returns transformed, with a boon.")
            ]
        case .threeAct:
            return [
                .init(name: "Act I — Setup", pct: 0.10, summary: "Introduce world, protagonist, and status quo."),
                .init(name: "Inciting Incident", pct: 0.20, summary: "The event that forces the story to begin."),
                .init(name: "Plot Point 1", pct: 0.25, summary: "Protagonist commits to the goal."),
                .init(name: "Act II — Confrontation", pct: 0.50, summary: "Obstacles, setbacks, and rising stakes."),
                .init(name: "Midpoint", pct: 0.55, summary: "A reversal that changes the trajectory."),
                .init(name: "Plot Point 2", pct: 0.75, summary: "Setup for the final confrontation."),
                .init(name: "Act III — Resolution", pct: 0.90, summary: "The climax and fallout."),
                .init(name: "Denouement", pct: 0.98, summary: "Show the new equilibrium.")
            ]
        case .fiveAct:
            return [
                .init(name: "Exposition", pct: 0.10, summary: "Setting, characters, and tone are introduced."),
                .init(name: "Rising Action", pct: 0.30, summary: "Complications multiply."),
                .init(name: "Climax", pct: 0.55, summary: "The turning point."),
                .init(name: "Falling Action", pct: 0.75, summary: "Consequences unfold."),
                .init(name: "Dénouement", pct: 0.95, summary: "Resolution and closure.")
            ]
        case .freytag:
            return [
                .init(name: "Exposition", pct: 0.10, summary: "Establish the world."),
                .init(name: "Inciting Moment", pct: 0.20, summary: "A spark that ignites tension."),
                .init(name: "Rising Action", pct: 0.40, summary: "Conflict intensifies."),
                .init(name: "Climax", pct: 0.55, summary: "Peak of the pyramid."),
                .init(name: "Falling Action", pct: 0.75, summary: "Tension releases."),
                .init(name: "Resolution", pct: 0.92, summary: "The tragic or comedic ending.")
            ]
        }
    }
}

// MARK: - Beat

struct Beat: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var pct: Double          // 0...1 position on the timeline
    var summary: String
    var notes: String = ""
    var isDone: Bool = false
}

// MARK: - Want vs Need

struct WantNeedEntry: Identifiable, Hashable {
    let id = UUID()
    var character: String
    var want: String
    var need: String
}

// MARK: - Theme / Motif

struct Motif: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var tint: Color

    static func == (lhs: Motif, rhs: Motif) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Samples

enum StoryForgeSamples {
    static let wantNeed: [WantNeedEntry] = [
        .init(character: "Elena Voss", want: "Solve the vanishing case to be reinstated.", need: "Accept that some mysteries live inside herself."),
        .init(character: "Kade Ortiz", want: "Protect his sister from the syndicate.", need: "Stop carrying guilt for his father's death."),
        .init(character: "Dr. Hale", want: "Publish the discovery first.", need: "Rediscover why he loved the work.")
    ]

    static let motifs: [Motif] = [
        .init(label: "Rain-slicked streets", tint: Theme.teal),
        .init(label: "Neon through fog", tint: Theme.magenta),
        .init(label: "Broken clocks", tint: Theme.violet),
        .init(label: "Mothers & daughters", tint: Theme.accent),
        .init(label: "Thresholds & doors", tint: Theme.lime)
    ]

    static let themeLines: [String] = [
        "Identity survives what's taken.",
        "Memory is a form of mercy.",
        "The city keeps its promises."
    ]
}
