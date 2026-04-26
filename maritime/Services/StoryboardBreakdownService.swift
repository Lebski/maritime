import Foundation
import SwiftUI

// MARK: - Storyboard Breakdown Service
//
// Two-stage AI pipeline for turning a Story Forge SceneBreakdown into a
// pencil-sketch storyboard:
//
//   1. `planShots(_:)` calls Claude to break the scene into 3–6 shots
//      (shot type, camera movement, action, dialogue, duration, reasoning).
//   2. `renderSketch(plan:characterRefs:moodRefs:)` calls Nano Banana 2 with
//      a "loose graphite storyboard" prompt + character/mood reference images
//      and returns PNG bytes.
//
// The driver (StoryboardComposerViewModel.generateBreakdown) sequences the two
// stages and persists the results into the project.

struct StoryboardBreakdownService {

    struct Request {
        var scene: SceneBreakdown
        var bible: StoryBible
        var characters: [LabCharacter]
        var moodboard: ProjectMoodboard
    }

    struct ShotPlan: Identifiable {
        var id = UUID()
        var number: Int
        var shotType: CameraShotType
        var cameraMovement: CameraMovement
        var duration: Double
        var actionNote: String
        var dialogue: String
        var editingPriority: EditingPriority
        var characterDraftIDs: [UUID]
        var reasoning: String
        var sketchPrompt: String
    }

    enum BreakdownError: Error, LocalizedError {
        case anthropic(AnthropicClient.ClientError)
        case fal(FalaiClient.ClientError)
        case parseFailed(String)
        case truncated

        var errorDescription: String? {
            switch self {
            case .anthropic(let err): return err.errorDescription
            case .fal(let err):       return err.errorDescription
            case .parseFailed(let detail): return "Claude's response wasn't valid JSON: \(detail)"
            case .truncated:          return "Output got cut off. Try a shorter scene description, or switch to Opus 4.7 for higher capacity."
            }
        }
    }

    var anthropic: AnthropicClient
    var fal: FalaiClient

    private static let maxRefImages = 14

    // MARK: Phase 1 — Claude shot planner

    func planShots(_ request: Request) async throws -> [ShotPlan] {
        let system = Self.systemPrompt
        let userMessage = Self.userPrompt(for: request)

        let response: AnthropicClient.Response
        do {
            response = try await anthropic.send(.init(
                system: system,
                messages: [.init(role: .user, content: userMessage)],
                maxTokens: 4000,
                model: nil
            ), label: "Storyboard breakdown")
        } catch let err as AnthropicClient.ClientError {
            throw BreakdownError.anthropic(err)
        }

        if response.stopReason == "max_tokens" {
            throw BreakdownError.truncated
        }

        if let plans = Self.parse(response.text, request: request), !plans.isEmpty {
            return plans
        }

        let retry: AnthropicClient.Response
        do {
            retry = try await anthropic.send(.init(
                system: system,
                messages: [
                    .init(role: .user, content: userMessage),
                    .init(role: .assistant, content: response.text),
                    .init(role: .user, content: "That was not valid JSON. Respond with ONLY the JSON object — no prose, no markdown fences, no commentary.")
                ],
                maxTokens: 4000,
                model: nil
            ), label: "Storyboard breakdown (retry)")
        } catch let err as AnthropicClient.ClientError {
            throw BreakdownError.anthropic(err)
        }

        if retry.stopReason == "max_tokens" {
            throw BreakdownError.truncated
        }

        if let plans = Self.parse(retry.text, request: request), !plans.isEmpty {
            return plans
        }

        throw BreakdownError.parseFailed(String(retry.text.prefix(160)))
    }

    // MARK: Phase 2 — Nano Banana 2 sketch render

    func renderSketch(plan: ShotPlan,
                      characterRefs: [Data],
                      moodRefs: [Data]) async throws -> Data {
        var imageURLs: [String] = []
        for ref in characterRefs.prefix(Self.maxRefImages - 2) {
            imageURLs.append(dataURIForImage(ref))
        }
        for ref in moodRefs.prefix(max(0, Self.maxRefImages - imageURLs.count)) {
            imageURLs.append(dataURIForImage(ref))
        }

        let payload = FalaiClient.GenerateRequest(
            prompt: plan.sketchPrompt,
            image_urls: imageURLs.isEmpty ? nil : imageURLs,
            num_images: 1,
            aspect_ratio: "16:9",
            output_format: "png",
            resolution: "1K"
        )

        do {
            return try await fal.generateAndFetch(
                payload,
                edit: !imageURLs.isEmpty,
                label: "Storyboard sketch — Shot \(plan.number)"
            )
        } catch let err as FalaiClient.ClientError {
            throw BreakdownError.fal(err)
        }
    }

    // MARK: Prompt assembly

    private static let systemPrompt = """
    You are a storyboard supervisor breaking a film scene into 3–6 shots. Each shot is one continuous camera setup. Cover the scene's emotional arc: an establishing/entrance shot, one or two beats that develop the conflict or action, a climactic shot at the apex, and an exit/transition shot.

    Required JSON shape (return ONLY this object — no markdown fences, no prose):
    {
      "shots": [
        {
          "number": 1,
          "shotType": "Extreme Close-up | Close-up | Medium Shot | Full Shot | Wide / Establishing | Over-the-Shoulder | POV | Dutch Angle | Low Angle | High Angle",
          "cameraMovement": "Static | Pan | Tilt | Zoom In | Zoom Out | Dolly | Tracking | Handheld",
          "duration": 2.5,
          "actionNote": "string — concrete action visible in this shot, present tense",
          "dialogue": "string — single line of dialogue or empty",
          "editingPriority": "Emotion | Story | Rhythm",
          "characterIndices": [0],
          "reasoning": "string — one sentence on why this shot is here, what it earns, how it sets up the next",
          "sketchPrompt": "string — visual description for the artist: framing, composition, lighting key, mood, blocking. Do NOT mention the words 'storyboard', 'sketch', or 'pencil' — that styling is added later."
        }
      ]
    }

    Rules:
    - 3 to 6 shots. Number consecutively from 1.
    - Durations are in seconds. They should roughly sum to the scene's natural runtime (a 90-second scene with one wide and four close-ups is fine; do not pad).
    - shotType MUST be exactly one of the listed strings (case-sensitive).
    - cameraMovement MUST be exactly one of the listed strings.
    - editingPriority follows Murch's triad — Emotion (how should the audience feel), Story (advance plot), Rhythm (control pacing). Pick the one this cut serves most.
    - characterIndices reference the provided character roster by zero-based position. Empty array if no character is on-camera.
    - dialogue is at most one short line per shot. Don't invent dialogue not implied by the scene's emotional beat.
    - reasoning is for the director — explicit, concrete, no mush.
    - sketchPrompt is a single paragraph that an illustrator could draw from cold. It should describe: subject + framing, body language, light direction, environment cues, mood. No camera-jargon. No styling directives.

    Output: a single JSON object with key "shots" — no markdown, no commentary.
    """

    private static func userPrompt(for request: Request) -> String {
        let scene = request.scene
        let bible = request.bible

        var lines: [String] = []
        lines.append("Project: \(bible.projectTitle)")
        if !bible.logline.isEmpty {
            lines.append("Logline: \(bible.logline)")
        }
        if !bible.theme.themeStatement.isEmpty {
            lines.append("Theme: \(bible.theme.themeStatement)")
        }
        if !bible.theme.motifs.isEmpty {
            let motifLabels = bible.theme.motifs.map(\.label).joined(separator: ", ")
            lines.append("Motifs: \(motifLabels)")
        }

        lines.append("")
        lines.append("Scene \(scene.number) — \(scene.title)")
        lines.append("\(scene.isInterior ? "INT." : "EXT.") \(scene.location) — \(scene.timeOfDay.rawValue)")
        if !scene.sceneGoal.isEmpty {
            lines.append("Goal: \(scene.sceneGoal)")
        }
        if !scene.conflict.isEmpty {
            lines.append("Conflict: \(scene.conflict)")
        }
        if !scene.emotionalBeat.isEmpty {
            lines.append("Emotional beat: \(scene.emotionalBeat)")
        }
        if !scene.visualMetaphor.isEmpty {
            lines.append("Visual metaphor: \(scene.visualMetaphor)")
        }
        if !scene.transitionNote.isEmpty {
            lines.append("Transition: \(scene.transitionNote)")
        }

        let onScreen = scene.characterDraftIDs.compactMap { id -> Int? in
            bible.characterDrafts.firstIndex(where: { $0.id == id })
        }
        if !bible.characterDrafts.isEmpty {
            lines.append("")
            lines.append("Character roster (use these zero-based indices in characterIndices):")
            for (idx, draft) in bible.characterDrafts.enumerated() {
                let onSceneMark = onScreen.contains(idx) ? " (in scene)" : ""
                lines.append("  [\(idx)] \(draft.name) — \(draft.role)\(onSceneMark)")
            }
        }

        lines.append("")
        lines.append("Return ONLY the JSON object described in the system prompt.")
        return lines.joined(separator: "\n")
    }

    // MARK: Parsing

    private static func parse(_ text: String, request: Request) -> [ShotPlan]? {
        guard let jsonSlice = extractJSONObject(from: text),
              let data = jsonSlice.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let rows = raw["shots"] as? [[String: Any]] ?? []
        guard !rows.isEmpty else { return nil }

        let bibleDrafts = request.bible.characterDrafts
        var plans: [ShotPlan] = []
        for (index, row) in rows.enumerated() {
            let number = (row["number"] as? Int) ?? (index + 1)
            let shotType = parseShotType(row["shotType"] as? String) ?? .medium
            let movement = parseMovement(row["cameraMovement"] as? String) ?? .static
            let duration = (row["duration"] as? Double) ?? 2.5
            let actionNote = (row["actionNote"] as? String)?.trimmed ?? ""
            let dialogue = (row["dialogue"] as? String)?.trimmed ?? ""
            let priority = parsePriority(row["editingPriority"] as? String) ?? .emotion
            let indices = (row["characterIndices"] as? [Int]) ?? []
            let draftIDs = indices
                .filter { $0 >= 0 && $0 < bibleDrafts.count }
                .map { bibleDrafts[$0].id }
            let reasoning = (row["reasoning"] as? String)?.trimmed ?? ""
            let prompt = (row["sketchPrompt"] as? String)?.trimmed ?? actionNote

            plans.append(ShotPlan(
                number: number,
                shotType: shotType,
                cameraMovement: movement,
                duration: max(0.5, duration),
                actionNote: actionNote,
                dialogue: dialogue,
                editingPriority: priority,
                characterDraftIDs: draftIDs,
                reasoning: reasoning,
                sketchPrompt: Self.decoratedSketchPrompt(prompt, shotType: shotType, movement: movement)
            ))
        }
        return plans
    }

    /// Wraps the artist-facing description with the loose-graphite storyboard
    /// styling so Nano Banana 2 produces a consistent monochrome sketch look.
    private static func decoratedSketchPrompt(_ raw: String,
                                              shotType: CameraShotType,
                                              movement: CameraMovement) -> String {
        let core = raw.isEmpty ? "Cinematic storyboard panel." : raw
        return """
        Loose graphite storyboard panel, monochrome pencil sketch on cream paper, rough hatching, no color, hand-drawn rough lines. Shot: \(shotType.rawValue), \(movement.rawValue). \(core) Aspect 16:9.
        """
    }

    private static func parseShotType(_ raw: String?) -> CameraShotType? {
        guard let raw = raw?.trimmed, !raw.isEmpty else { return nil }
        if let match = CameraShotType.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            return match
        }
        if let match = CameraShotType.allCases.first(where: { String(describing: $0).caseInsensitiveCompare(raw) == .orderedSame }) {
            return match
        }
        return nil
    }

    private static func parseMovement(_ raw: String?) -> CameraMovement? {
        guard let raw = raw?.trimmed, !raw.isEmpty else { return nil }
        if let match = CameraMovement.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            return match
        }
        if let match = CameraMovement.allCases.first(where: { String(describing: $0).caseInsensitiveCompare(raw) == .orderedSame }) {
            return match
        }
        return nil
    }

    private static func parsePriority(_ raw: String?) -> EditingPriority? {
        guard let raw = raw?.trimmed, !raw.isEmpty else { return nil }
        return EditingPriority.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame
        })
    }

    /// Tolerates Claude wrapping JSON in markdown fences or prose.
    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        return String(text[start...end])
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
