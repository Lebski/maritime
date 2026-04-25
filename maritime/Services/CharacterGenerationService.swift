import Foundation

/// Turns (name, role, backstory, which fields to fill) into concrete
/// Want/Need/Ghost/Flaw/Stakes/Voice strings via Claude.
struct CharacterGenerationService {

    struct Request {
        var name: String
        var role: String
        var backstory: String
        /// Non-empty values the author has already written. Passed to Claude as context
        /// but never overwritten.
        var existing: [StoryCharacterField: String]
        /// Fields Claude should fill. Fields already present in `existing` are dropped.
        var fieldsToFill: Set<StoryCharacterField>
    }

    struct Result {
        var fields: [StoryCharacterField: String]
    }

    enum GenerationError: Error, LocalizedError {
        case client(AnthropicClient.ClientError)
        case noFieldsRequested
        case parseFailed(String)

        var errorDescription: String? {
            switch self {
            case .client(let err): return err.errorDescription
            case .noFieldsRequested: return "All six fields already have content."
            case .parseFailed(let detail): return "Claude's response wasn't valid JSON: \(detail)"
            }
        }
    }

    var client: AnthropicClient

    // MARK: - Public

    func generate(_ request: Request) async throws -> Result {
        let fillable = request.fieldsToFill.subtracting(
            request.existing
                .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .keys
                .map { $0 }
        ).intersection(Set(StoryCharacterField.psychologyFields))

        guard !fillable.isEmpty else { throw GenerationError.noFieldsRequested }

        let system = Self.systemPrompt
        let userMessage = Self.userPrompt(for: request, fieldsToFill: fillable)

        let response: AnthropicClient.Response
        do {
            response = try await client.send(.init(
                system: system,
                messages: [.init(role: .user, content: userMessage)],
                maxTokens: 800,
                model: nil
            ))
        } catch let err as AnthropicClient.ClientError {
            throw GenerationError.client(err)
        }

        if let parsed = Self.parse(response.text, expected: fillable) {
            return Result(fields: parsed)
        }

        // One retry with a stricter reminder.
        let retry: AnthropicClient.Response
        do {
            retry = try await client.send(.init(
                system: system,
                messages: [
                    .init(role: .user, content: userMessage),
                    .init(role: .assistant, content: response.text),
                    .init(role: .user, content: "That was not valid JSON. Respond with ONLY the JSON object, no prose, no markdown fences.")
                ],
                maxTokens: 800,
                model: nil
            ))
        } catch let err as AnthropicClient.ClientError {
            throw GenerationError.client(err)
        }

        if let parsed = Self.parse(retry.text, expected: fillable) {
            return Result(fields: parsed)
        }

        throw GenerationError.parseFailed(String(retry.text.prefix(160)))
    }

    // MARK: - Prompts

    private static let systemPrompt = """
    You are a story consultant helping filmmakers develop character psychology using the Want / Need / Ghost / Flaw / Stakes / Voice framework (Robert McKee, John Truby, Blake Snyder).

    Conventions for every field you generate:
    - ONE concrete sentence. Present tense. No hedging.
    - Specific nouns and verbs, not categories. "She wants to find her missing sister in the flooded district" beats "She wants to find a lost loved one."
    - If a backstory is provided, at least one detail in each generated field must echo a specific fact from it.
    - Avoid cliche, therapy-speak, and generic trait words ("brave", "determined", "complex").
    - Voice is behavioral — a verbal tic, rhythm, or physical tell — not an adjective.

    Output format: RETURN ONLY a single JSON object. No markdown fences. No prose before or after. Keys must be lowercase and drawn exactly from: want, need, ghost, flaw, stakes, voice. Include ONLY the keys the user asks you to fill. Values are strings.
    """

    private static func userPrompt(for request: Request,
                                   fieldsToFill: Set<StoryCharacterField>) -> String {
        let name = request.name.isEmpty ? "(unnamed)" : request.name
        let role = request.role.isEmpty ? "Supporting character" : request.role
        let backstory = request.backstory.trimmingCharacters(in: .whitespacesAndNewlines)

        let existingLines = request.existing
            .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted(by: { $0.key.rawValue < $1.key.rawValue })
            .map { "- \($0.key.rawValue): \($0.value)" }
            .joined(separator: "\n")

        let orderedKeys = StoryCharacterField.psychologyFields
            .filter { fieldsToFill.contains($0) }
            .map { $0.rawValue }
        let keyList = orderedKeys.map { "\"\($0)\"" }.joined(separator: ", ")

        return """
        Character: \(name)
        Role: \(role)
        Backstory: \(backstory.isEmpty ? "(none provided — extrapolate from name and role)" : backstory)

        Already written by the author (keep these consistent, do not overwrite):
        \(existingLines.isEmpty ? "(nothing yet)" : existingLines)

        Generate these fields and only these fields: [\(keyList)]

        Return a single JSON object with exactly those keys.
        """
    }

    // MARK: - Parsing

    private static func parse(_ text: String,
                              expected: Set<StoryCharacterField>) -> [StoryCharacterField: String]? {
        guard let jsonSlice = extractJSONObject(from: text) else { return nil }
        guard let data = jsonSlice.data(using: .utf8) else { return nil }
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        var result: [StoryCharacterField: String] = [:]
        for field in expected {
            if let value = raw[field.rawValue] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    result[field] = trimmed
                }
            }
        }
        return result.isEmpty ? nil : result
    }

    /// Tolerates Claude occasionally wrapping JSON in markdown fences or prose.
    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        return String(text[start...end])
    }
}
