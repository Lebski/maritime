import Foundation

/// Re-proposes a scene breakdown after the user changes the structure template.
/// Inputs: pitch, characters, old + new structure, the existing scene list, and the
/// theme tracker. Output is a fresh scene list intended to be reviewed via a diff sheet
/// rather than applied wholesale — so the service produces *proposals*, not authoritative state.
struct SceneRegenerationService {

    struct Request {
        var pitch: String
        var logline: String
        var characters: [StoryCharacterDraft]
        var oldTemplate: StoryStructureTemplate
        var newTemplate: StoryStructureTemplate
        var oldBeats: [StoryBeat]
        var newBeats: [StoryBeat]
        var oldScenes: [SceneBreakdown]
        var theme: ThemeTracker
    }

    struct Output {
        var scenes: [SceneBreakdown]
    }

    enum GenerationError: Error, LocalizedError {
        case client(AnthropicClient.ClientError)
        case parseFailed(String)
        case truncated

        var errorDescription: String? {
            switch self {
            case .client(let err): return err.errorDescription
            case .parseFailed(let detail): return "Claude's response wasn't valid JSON: \(detail)"
            case .truncated: return "Output got cut off. Try Opus 4.7 or shorten the existing scene list."
            }
        }
    }

    var client: AnthropicClient

    // MARK: - Public

    func generate(_ request: Request) async throws -> Output {
        let system = Self.systemPrompt
        let userMessage = Self.userPrompt(for: request)

        let response: AnthropicClient.Response
        do {
            response = try await client.send(.init(
                system: system,
                messages: [.init(role: .user, content: userMessage)],
                maxTokens: 6000,
                model: nil
            ), label: "Scene regen (template swap)")
        } catch let err as AnthropicClient.ClientError {
            throw GenerationError.client(err)
        }

        if response.stopReason == "max_tokens" {
            throw GenerationError.truncated
        }

        if let parsed = Self.parse(response.text, characters: request.characters) {
            return parsed
        }

        let retry: AnthropicClient.Response
        do {
            retry = try await client.send(.init(
                system: system,
                messages: [
                    .init(role: .user, content: userMessage),
                    .init(role: .assistant, content: response.text),
                    .init(role: .user, content: "That was not valid JSON. Respond with ONLY the JSON object — no prose, no markdown fences.")
                ],
                maxTokens: 6000,
                model: nil
            ), label: "Scene regen (retry)")
        } catch let err as AnthropicClient.ClientError {
            throw GenerationError.client(err)
        }

        if retry.stopReason == "max_tokens" {
            throw GenerationError.truncated
        }

        if let parsed = Self.parse(retry.text, characters: request.characters) {
            return parsed
        }

        throw GenerationError.parseFailed(String(retry.text.prefix(160)))
    }

    // MARK: - Prompts

    private static let systemPrompt = """
    You are revising a film's scene breakdown because its structure template has changed. The author already has a pitch, characters, an old template, an old scene list, and a theme tracker. Re-fit the existing dramatic material to the new template's beat order. Preserve scene titles where the corresponding dramatic beat survives; rewrite where the new template demands a different rhythm.

    Required JSON shape (return ONLY this object — no markdown fences, no commentary):
    {
      "scenes": [
        {
          "number": 1,
          "title": "string",
          "location": "string — concrete place, no INT/EXT prefix",
          "isInterior": true,
          "timeOfDay": "Dawn | Day | Golden Hour | Dusk | Night",
          "characterIndices": [0, 1],
          "sceneGoal": "string",
          "conflict": "string",
          "emotionalBeat": "string",
          "visualMetaphor": "string — MUST reference one of the supplied motif labels OR echo the theme statement",
          "transitionNote": "string"
        }
      ]
    }

    Rules:
    - Number scenes consecutively from 1.
    - characterIndices reference the supplied characters[] by zero-based position.
    - 8 to 14 scenes total.
    - Every visualMetaphor MUST contain a motif label verbatim or echo the theme statement. If the motifs list is empty, every visualMetaphor must echo the theme statement.
    - Carry over a scene only if its dramatic function survives in the new template. Otherwise rewrite — but keep proper nouns from the original characters and pitch.
    - Concrete sentences. No therapy-speak. Behavioral specifics over labels.

    Output: a single JSON object. No markdown fences. No prose.
    """

    private static func userPrompt(for request: Request) -> String {
        var lines: [String] = []
        lines.append("Pitch:")
        lines.append(request.pitch.trimmingCharacters(in: .whitespacesAndNewlines))
        if !request.logline.isEmpty {
            lines.append("")
            lines.append("Logline: \(request.logline)")
        }

        lines.append("")
        lines.append("Characters (zero-indexed for characterIndices):")
        for (i, c) in request.characters.enumerated() {
            let role = c.role.isEmpty ? "Supporting" : c.role
            lines.append("[\(i)] \(c.name) — \(role)")
            if !c.want.isEmpty   { lines.append("    Want: \(c.want)") }
            if !c.flaw.isEmpty   { lines.append("    Flaw: \(c.flaw)") }
            if !c.stakes.isEmpty { lines.append("    Stakes: \(c.stakes)") }
        }

        lines.append("")
        lines.append("Theme statement: \(request.theme.themeStatement.isEmpty ? "(none — invent one if you need it)" : request.theme.themeStatement)")
        if !request.theme.motifs.isEmpty {
            let motifList = request.theme.motifs.map { $0.label }.joined(separator: ", ")
            lines.append("Motif labels (every visualMetaphor must reference one of these): \(motifList)")
        } else {
            lines.append("No motifs supplied. Make every visualMetaphor echo the theme statement.")
        }

        lines.append("")
        lines.append("OLD template: \(request.oldTemplate.rawValue)")
        lines.append("OLD beats (in order):")
        for beat in request.oldBeats {
            lines.append("- \(beat.name) (\(beat.actLabel))")
        }

        lines.append("")
        lines.append("NEW template: \(request.newTemplate.rawValue) — produce scenes that hit these beats in order:")
        for beat in request.newBeats {
            lines.append("- \(beat.name) (\(beat.actLabel)) — \(beat.defaultPrompt)")
        }

        lines.append("")
        lines.append("Existing scene list (rewrite, keep, or drop as needed — preserve dramatic material that survives the structure change):")
        for s in request.oldScenes {
            lines.append("- #\(s.number) \(s.title) @ \(s.location), \(s.isInterior ? "INT" : "EXT") \(s.timeOfDay.rawValue)")
            if !s.sceneGoal.isEmpty      { lines.append("    Goal: \(s.sceneGoal)") }
            if !s.conflict.isEmpty       { lines.append("    Conflict: \(s.conflict)") }
            if !s.emotionalBeat.isEmpty  { lines.append("    Beat: \(s.emotionalBeat)") }
            if !s.visualMetaphor.isEmpty { lines.append("    Metaphor: \(s.visualMetaphor)") }
        }

        lines.append("")
        lines.append("Return ONLY the JSON object described in the system prompt.")
        return lines.joined(separator: "\n")
    }

    // MARK: - Parsing

    private static func parse(_ text: String,
                              characters: [StoryCharacterDraft]) -> Output? {
        guard let jsonSlice = extractJSONObject(from: text),
              let data = jsonSlice.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = raw["scenes"] as? [[String: Any]] else {
            return nil
        }

        let scenes: [SceneBreakdown] = rows.enumerated().compactMap { (index, row) -> SceneBreakdown? in
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

        return scenes.isEmpty ? nil : Output(scenes: scenes)
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

    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        return String(text[start...end])
    }
}
