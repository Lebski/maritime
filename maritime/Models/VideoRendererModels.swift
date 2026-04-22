import SwiftUI

// MARK: - Motion

enum MotionIntensity: String, CaseIterable, Identifiable {
    case locked = "Locked"
    case subtle = "Subtle"
    case dynamic = "Dynamic"
    case kinetic = "Kinetic"

    var id: String { rawValue }
    var magnitude: Double {
        switch self {
        case .locked: return 0.0
        case .subtle: return 0.3
        case .dynamic: return 0.65
        case .kinetic: return 1.0
        }
    }
    var icon: String {
        switch self {
        case .locked: return "lock.fill"
        case .subtle: return "wind"
        case .dynamic: return "waveform.path.ecg"
        case .kinetic: return "bolt.fill"
        }
    }
}

// MARK: - Clip

struct VideoClip: Identifiable, Hashable {
    let id = UUID()
    var number: Int
    var title: String
    var sceneNumber: Int
    var duration: Double
    var motion: MotionIntensity
    var gradientSeed: Int
    var isApproved: Bool

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

// MARK: - Cut Suggestion (Rule of Six)

enum CutPriority: String, CaseIterable {
    case emotion = "Emotion"
    case story = "Story"
    case rhythm = "Rhythm"
    case eyeTrace = "Eye Trace"
    case axis = "180° Axis"
    case space = "3D Space"

    var tint: Color {
        switch self {
        case .emotion: return Theme.magenta
        case .story: return Theme.accent
        case .rhythm: return Theme.lime
        case .eyeTrace: return Theme.teal
        case .axis: return Theme.violet
        case .space: return Color.white.opacity(0.6)
        }
    }

    var weight: String {
        switch self {
        case .emotion: return "51%"
        case .story: return "23%"
        case .rhythm: return "10%"
        case .eyeTrace: return "7%"
        case .axis: return "5%"
        case .space: return "4%"
        }
    }
}

struct CutSuggestion: Identifiable, Hashable {
    let id = UUID()
    var afterClipNumber: Int
    var priority: CutPriority
    var rationale: String
    var applied: Bool = false
}

// MARK: - Samples

enum VideoRendererSamples {
    static let clips: [VideoClip] = [
        .init(number: 1, title: "Neon skyline drift", sceneNumber: 1, duration: 4.0, motion: .subtle, gradientSeed: 0, isApproved: true),
        .init(number: 2, title: "Alley reveal", sceneNumber: 1, duration: 3.0, motion: .dynamic, gradientSeed: 1, isApproved: true),
        .init(number: 3, title: "Elena at the door", sceneNumber: 2, duration: 2.5, motion: .locked, gradientSeed: 2, isApproved: false),
        .init(number: 4, title: "Into the bar", sceneNumber: 2, duration: 2.0, motion: .subtle, gradientSeed: 3, isApproved: false),
        .init(number: 5, title: "Recognition", sceneNumber: 2, duration: 1.8, motion: .locked, gradientSeed: 0, isApproved: false),
        .init(number: 6, title: "Photo insert", sceneNumber: 2, duration: 1.2, motion: .kinetic, gradientSeed: 4, isApproved: false)
    ]

    static let cuts: [CutSuggestion] = [
        .init(afterClipNumber: 1, priority: .emotion, rationale: "Cut to close-up after skyline to anchor viewer in Elena's emotion."),
        .init(afterClipNumber: 2, priority: .rhythm, rationale: "Shorten by 0.5s — keeps pulse aligned with previous beat."),
        .init(afterClipNumber: 3, priority: .story, rationale: "Hold one beat longer. Audience needs to register her hesitation."),
        .init(afterClipNumber: 5, priority: .eyeTrace, rationale: "Eyes land on photo naturally — cut matches gaze direction."),
        .init(afterClipNumber: 5, priority: .axis, rationale: "Watch the 180° line — Kade's position flips unless reversed.")
    ]
}
