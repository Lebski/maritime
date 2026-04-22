import SwiftUI

// MARK: - Shot Types

enum ShotSize: String, CaseIterable, Identifiable {
    case establishing = "Establishing"
    case wide = "Wide"
    case full = "Full"
    case medium = "Medium"
    case closeUp = "Close-up"
    case extremeCloseUp = "Extreme Close-up"
    case overTheShoulder = "OTS"
    case pov = "POV"
    case insert = "Insert"
    case twoShot = "Two-Shot"
    case dutch = "Dutch"
    case aerial = "Aerial"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .establishing: return "EST"
        case .wide: return "WS"
        case .full: return "FS"
        case .medium: return "MS"
        case .closeUp: return "CU"
        case .extremeCloseUp: return "ECU"
        case .overTheShoulder: return "OTS"
        case .pov: return "POV"
        case .insert: return "INS"
        case .twoShot: return "2S"
        case .dutch: return "DUT"
        case .aerial: return "AER"
        }
    }

    var icon: String {
        switch self {
        case .establishing: return "mountain.2.fill"
        case .wide: return "rectangle.landscape.rotate"
        case .full: return "figure.stand"
        case .medium: return "person.fill"
        case .closeUp: return "face.smiling.fill"
        case .extremeCloseUp: return "eye.fill"
        case .overTheShoulder: return "person.2.fill"
        case .pov: return "eye.circle.fill"
        case .insert: return "cursorarrow.and.square.on.square.dashed"
        case .twoShot: return "person.2.crop.square.stack.fill"
        case .dutch: return "rotate.3d.fill"
        case .aerial: return "airplane"
        }
    }

    var description: String {
        switch self {
        case .establishing: return "Sets the scene."
        case .wide: return "Full environment, small subject."
        case .full: return "Subject head-to-toe."
        case .medium: return "Waist up. Conversational."
        case .closeUp: return "Head and shoulders."
        case .extremeCloseUp: return "Eyes, details."
        case .overTheShoulder: return "Back of one, face of the other."
        case .pov: return "What the character sees."
        case .insert: return "Isolated object detail."
        case .twoShot: return "Two subjects in frame."
        case .dutch: return "Tilted horizon. Unease."
        case .aerial: return "Bird's eye view."
        }
    }
}

// MARK: - Panel

struct StoryboardPanel: Identifiable, Hashable {
    let id = UUID()
    var number: Int
    var shot: ShotSize
    var title: String
    var description: String
    var duration: Double        // seconds
    var gradientSeed: Int       // for stable color
    var isKey: Bool = false

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

// MARK: - Samples

enum StoryboardSamples {
    static let panels: [StoryboardPanel] = [
        .init(number: 1, shot: .establishing, title: "Rain on the city",
              description: "Camera drifts over neon skyline at 3AM.",
              duration: 4.0, gradientSeed: 0, isKey: true),
        .init(number: 2, shot: .wide, title: "Alley reveal",
              description: "Elena steps into frame, silhouetted by headlights.",
              duration: 3.0, gradientSeed: 1),
        .init(number: 3, shot: .medium, title: "Elena at the door",
              description: "She hesitates, hand on the knob.",
              duration: 2.5, gradientSeed: 2),
        .init(number: 4, shot: .overTheShoulder, title: "Inside the bar",
              description: "Over Elena's shoulder — Kade looks up.",
              duration: 2.0, gradientSeed: 3),
        .init(number: 5, shot: .closeUp, title: "Recognition",
              description: "Elena's face — the smallest smile.",
              duration: 1.8, gradientSeed: 0, isKey: true),
        .init(number: 6, shot: .extremeCloseUp, title: "Photo on the table",
              description: "Blurred edges. A name underlined.",
              duration: 1.2, gradientSeed: 4)
    ]
}
