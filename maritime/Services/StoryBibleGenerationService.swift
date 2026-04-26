import Foundation
import SwiftUI

/// Turns a free-form pitch into a complete `StoryBible` (project meta, characters,
/// structure with annotated beats, scenes, theme) via one Claude call.
struct StoryBibleGenerationService {

    struct Request {
        var pitch: String
        var projectTitle: String?
        var genre: String?
        var tone: String?
        var preferredTemplate: StoryStructureTemplate?
    }

    struct Output {
        var projectTitle: String
        var logline: String
        var characters: [StoryCharacterDraft]
        var structure: StoryStructureDraft
        var scenes: [SceneBreakdown]
        var theme: ThemeTracker
    }

    enum GenerationError: Error, LocalizedError {
        case client(AnthropicClient.ClientError)
        case emptyPitch
        case parseFailed(String)
        case truncated

        var errorDescription: String? {
            switch self {
            case .client(let err): return err.errorDescription
            case .emptyPitch:      return "Add a few sentences describing your story before generating."
            case .parseFailed(let detail): return "Claude's response wasn't valid JSON: \(detail)"
            case .truncated:       return "Output got cut off. Try a shorter pitch, or switch to Opus 4.7 for higher capacity."
            }
        }
    }

    var client: AnthropicClient

    // MARK: - Public

    func generate(_ request: Request) async throws -> Output {
        let pitch = request.pitch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pitch.isEmpty else { throw GenerationError.emptyPitch }

        let system = Self.systemPrompt
        let userMessage = Self.userPrompt(for: request)

        let response: AnthropicClient.Response
        do {
            response = try await client.send(.init(
                system: system,
                messages: [.init(role: .user, content: userMessage)],
                maxTokens: 8000,
                model: nil
            ), label: "Story Bible")
        } catch let err as AnthropicClient.ClientError {
            throw GenerationError.client(err)
        }

        if response.stopReason == "max_tokens" {
            throw GenerationError.truncated
        }

        if let parsed = Self.parse(response.text, request: request) {
            return parsed
        }

        let retry: AnthropicClient.Response
        do {
            retry = try await client.send(.init(
                system: system,
                messages: [
                    .init(role: .user, content: userMessage),
                    .init(role: .assistant, content: response.text),
                    .init(role: .user, content: "That was not valid JSON. Respond with ONLY the JSON object — no prose, no markdown fences, no commentary.")
                ],
                maxTokens: 8000,
                model: nil
            ), label: "Story Bible (retry)")
        } catch let err as AnthropicClient.ClientError {
            throw GenerationError.client(err)
        }

        if retry.stopReason == "max_tokens" {
            throw GenerationError.truncated
        }

        if let parsed = Self.parse(retry.text, request: request) {
            return parsed
        }

        throw GenerationError.parseFailed(String(retry.text.prefix(160)))
    }

    // MARK: - Prompts

    private static let systemPrompt = """
    You are a story consultant helping a filmmaker turn a one-paragraph pitch into a complete Story Bible. The bible has five facets: project meta, characters, structure, scenes, and theme.

    Required JSON shape (return ONLY this object — no markdown fences, no prose before or after):
    {
      "projectTitle": "string — short, evocative",
      "logline": "string — one sentence, present tense, names the protagonist and the central want/conflict",
      "characters": [
        {
          "name": "string",
          "role": "Protagonist | Antagonist | Mentor | Ally | Love Interest | Foil | Supporting",
          "backstory": "string — one or two concrete sentences with specific nouns",
          "want": "string", "need": "string", "ghost": "string",
          "flaw": "string", "stakes": "string", "voice": "string — a behavioral tic, not an adjective"
        }
      ],
      "structure": {
        "template": "Three-Act Structure | Save the Cat | Hero's Journey | Kishotenketsu | In Medias Res",
        "beatNotes": ["one note per canonical beat, in order"]
      },
      "scenes": [
        {
          "number": 1,
          "title": "string",
          "location": "string — concrete place, no INT/EXT prefix",
          "isInterior": true,
          "timeOfDay": "Dawn | Day | Golden Hour | Dusk | Night",
          "characterIndices": [0, 1],
          "sceneGoal": "string — what the protagonist is trying to do",
          "conflict": "string — what stands in the way",
          "emotionalBeat": "string — the feeling at the apex of the scene",
          "visualMetaphor": "string — MUST reference one of the theme.motifs by label OR echo the theme.statement",
          "transitionNote": "string — short hint about the cut to the next scene"
        }
      ],
      "theme": {
        "statement": "string — one sentence, no hedging",
        "motifs": [{ "label": "string", "symbol": "valid SF Symbol name", "tint": "magenta|teal|violet|accent|lime|coral" }],
        "palette": [{ "hex": "#RRGGBB", "role": "string — e.g. Protagonist, Act 2, World" }]
      }
    }

    Counts and rules:
    - 2 to 4 characters. Always include a Protagonist. Use names, not placeholders like "the woman".
    - Beat counts (must produce one note per beat, in canonical order):
      * Three-Act Structure: 8 beats — Opening Image, Inciting Incident, Plot Point 1, Rising Action, Midpoint, Crisis, Climax, Resolution.
      * Save the Cat: 15 beats — Opening Image, Theme Stated, Setup, Catalyst, Debate, Break into Two, B Story, Fun and Games, Midpoint, Bad Guys Close In, All Is Lost, Dark Night of the Soul, Break into Three, Finale, Final Image.
      * Hero's Journey: 12 beats — Ordinary World, Call to Adventure, Refusal of the Call, Meeting the Mentor, Crossing the Threshold, Tests Allies Enemies, Approach the Inmost Cave, Ordeal, Reward, The Road Back, Resurrection, Return with the Elixir.
      * Kishotenketsu: 4 beats — Ki, Shō, Ten, Ketsu.
      * In Medias Res: 6 beats — Mid-Action Opening, Context Flashback, Escalation Toward Opening, Catching Up to the Open, Reveal, Resolution Beyond.
    - 8 to 14 scenes. Number consecutively starting at 1. characterIndices reference characters[] by zero-based position.
    - 2 to 5 motifs. 3 to 6 palette swatches. Hex must be a valid #RRGGBB string.
    - visualMetaphor on every scene MUST contain a motif label verbatim OR a substring of the theme statement. This is how the theme is made visible.
    - All field values are concrete sentences. No therapy-speak. No abstract trait words ("brave", "complex", "determined"). Behavioral specifics over labels.

    Output format: a single JSON object. No markdown fences. No commentary. No trailing prose.
    """

    private static func userPrompt(for request: Request) -> String {
        let pitch = request.pitch.trimmingCharacters(in: .whitespacesAndNewlines)

        var lines: [String] = []
        lines.append("Pitch:")
        lines.append(pitch)
        lines.append("")

        if let title = request.projectTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            lines.append("Suggested project title: \(title) (you may refine, but stay close).")
        }
        if let genre = request.genre?.trimmingCharacters(in: .whitespacesAndNewlines), !genre.isEmpty {
            lines.append("Genre / register: \(genre).")
        }
        if let tone = request.tone?.trimmingCharacters(in: .whitespacesAndNewlines), !tone.isEmpty {
            lines.append("Tone: \(tone).")
        }
        if let template = request.preferredTemplate {
            lines.append("Use the \(template.rawValue) template. Produce exactly \(template.beatCount) beats in canonical order.")
        } else {
            lines.append("Pick whichever structure template fits this story best, and explain the choice nowhere — just commit to it in the JSON.")
        }

        lines.append("")
        lines.append("Return ONLY the JSON object described in the system prompt.")
        return lines.joined(separator: "\n")
    }

    // MARK: - Parsing

    private static func parse(_ text: String, request: Request) -> Output? {
        guard let jsonSlice = extractJSONObject(from: text),
              let data = jsonSlice.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let projectTitle = (raw["projectTitle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? request.projectTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "Untitled"
        let logline = (raw["logline"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let characters = parseCharacters(raw["characters"] as? [[String: Any]] ?? [])
        guard !characters.isEmpty else { return nil }

        let structure = parseStructure(raw["structure"] as? [String: Any] ?? [:],
                                       fallback: request.preferredTemplate ?? .threeAct)

        let scenes = parseScenes(raw["scenes"] as? [[String: Any]] ?? [],
                                 characters: characters)
        guard !scenes.isEmpty else { return nil }

        let theme = parseTheme(raw["theme"] as? [String: Any] ?? [:])

        return Output(
            projectTitle: projectTitle.isEmpty ? "Untitled" : projectTitle,
            logline: logline,
            characters: characters,
            structure: structure,
            scenes: scenes,
            theme: theme
        )
    }

    private static func parseCharacters(_ rows: [[String: Any]]) -> [StoryCharacterDraft] {
        rows.compactMap { row -> StoryCharacterDraft? in
            let name = (row["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return nil }
            let role = (row["role"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return StoryCharacterDraft(
                name: name,
                role: (role?.isEmpty == false) ? role! : "Supporting",
                backstory: (row["backstory"] as? String) ?? "",
                want: (row["want"] as? String) ?? "",
                need: (row["need"] as? String) ?? "",
                ghost: (row["ghost"] as? String) ?? "",
                flaw: (row["flaw"] as? String) ?? "",
                stakes: (row["stakes"] as? String) ?? "",
                voice: (row["voice"] as? String) ?? ""
            )
        }
    }

    private static func parseStructure(_ row: [String: Any],
                                       fallback: StoryStructureTemplate) -> StoryStructureDraft {
        let templateRaw = (row["template"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let template = StoryStructureTemplate.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(templateRaw) == .orderedSame
        }) ?? fallback

        var beats = template.defaultBeats
        let notes = row["beatNotes"] as? [String] ?? []
        for (i, note) in notes.enumerated() where i < beats.count {
            beats[i].userNotes = note.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return StoryStructureDraft(template: template, beats: beats)
    }

    private static func parseScenes(_ rows: [[String: Any]],
                                    characters: [StoryCharacterDraft]) -> [SceneBreakdown] {
        rows.enumerated().compactMap { (index, row) -> SceneBreakdown? in
            let title = (row["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let location = (row["location"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else { return nil }

            let number = (row["number"] as? Int) ?? (index + 1)
            let isInterior = (row["isInterior"] as? Bool) ?? true
            let timeOfDay = parseTimeOfDay(row["timeOfDay"] as? String)

            let indices = (row["characterIndices"] as? [Int]) ?? []
            let draftIDs = indices
                .filter { $0 >= 0 && $0 < characters.count }
                .map { characters[$0].id }

            return SceneBreakdown(
                number: number,
                title: title,
                location: location.isEmpty ? "Untitled Location" : location,
                isInterior: isInterior,
                timeOfDay: timeOfDay,
                characterDraftIDs: draftIDs,
                sceneGoal: (row["sceneGoal"] as? String) ?? "",
                conflict: (row["conflict"] as? String) ?? "",
                emotionalBeat: (row["emotionalBeat"] as? String) ?? "",
                visualMetaphor: (row["visualMetaphor"] as? String) ?? "",
                transitionNote: (row["transitionNote"] as? String) ?? ""
            )
        }
    }

    private static func parseTimeOfDay(_ raw: String?) -> TimeOfDay {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return .day
        }
        if let match = TimeOfDay.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            return match
        }
        if let match = TimeOfDay.allCases.first(where: { String(describing: $0).caseInsensitiveCompare(raw) == .orderedSame }) {
            return match
        }
        return .day
    }

    private static func parseTheme(_ row: [String: Any]) -> ThemeTracker {
        let statement = (row["statement"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let motifs: [VisualMotif] = (row["motifs"] as? [[String: Any]] ?? []).compactMap { m in
            let label = (m["label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !label.isEmpty else { return nil }
            let symbol = (m["symbol"] as? String) ?? "sparkles"
            let tint = motifTint(named: m["tint"] as? String)
            return VisualMotif(label: label, symbol: symbol, tint: tint, frequency: 1)
        }

        let palette: [ColorPaletteSwatch] = (row["palette"] as? [[String: Any]] ?? []).compactMap { p in
            let hex = (p["hex"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let role = (p["role"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let color = colorFromHex(hex) else { return nil }
            return ColorPaletteSwatch(hex: hex, color: color, role: role.isEmpty ? "Untitled" : role)
        }

        return ThemeTracker(themeStatement: statement, motifs: motifs, palette: palette)
    }

    private static func motifTint(named raw: String?) -> Color {
        switch raw?.lowercased() {
        case "magenta": return Theme.magenta
        case "teal":    return Theme.teal
        case "violet":  return Theme.violet
        case "accent", "amber": return Theme.accent
        case "lime":    return Theme.lime
        case "coral":   return Theme.coral
        default:        return Theme.magenta
        }
    }

    private static func colorFromHex(_ raw: String) -> Color? {
        var hex = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    /// Tolerates Claude wrapping JSON in markdown fences or prose.
    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        return String(text[start...end])
    }
}
