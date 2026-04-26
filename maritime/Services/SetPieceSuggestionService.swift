import Foundation

/// Turns a free-text set description plus optional context (set type,
/// interior/exterior, era) into a list of starter `SetPiece` suggestions
/// the user can review and apply in Set Design onboarding.
struct SetPieceSuggestionService {

    struct Request {
        var description: String
        var setType: String?
        var interiorExterior: String?
        var era: String?
        var projectTitle: String
        var desiredCount: Int = 6
    }

    struct Suggestion {
        var name: String
        var category: SetPieceCategory
        var description: String
        var promptSeed: String
        var tags: [String]
    }

    struct Result {
        var suggestions: [Suggestion]
    }

    enum GenerationError: Error, LocalizedError {
        case client(AnthropicClient.ClientError)
        case parseFailed(String)
        case empty

        var errorDescription: String? {
            switch self {
            case .client(let err): return err.errorDescription
            case .parseFailed(let detail): return "Claude's response wasn't valid JSON: \(detail)"
            case .empty: return "Claude didn't return any usable set pieces."
            }
        }
    }

    var client: AnthropicClient

    // MARK: - Public

    func suggest(_ request: Request) async throws -> Result {
        let system = Self.systemPrompt
        let userMessage = Self.userPrompt(for: request)

        let response: AnthropicClient.Response
        do {
            response = try await client.send(.init(
                system: system,
                messages: [.init(role: .user, content: userMessage)],
                maxTokens: 1500,
                model: nil
            ), label: "Set piece suggestions")
        } catch let err as AnthropicClient.ClientError {
            throw GenerationError.client(err)
        }

        if let parsed = Self.parse(response.text), !parsed.isEmpty {
            return Result(suggestions: parsed)
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
                maxTokens: 1500,
                model: nil
            ), label: "Set piece suggestions (retry)")
        } catch let err as AnthropicClient.ClientError {
            throw GenerationError.client(err)
        }

        if let parsed = Self.parse(retry.text) {
            if parsed.isEmpty { throw GenerationError.empty }
            return Result(suggestions: parsed)
        }

        throw GenerationError.parseFailed(String(retry.text.prefix(160)))
    }

    // MARK: - Prompts

    private static let systemPrompt = """
    You are a production designer helping the user assemble a starter set of physical objects and environment fragments for a project. The project may be a film, an advertising shoot, an editorial photo set, a music video, or anything else — adapt to the brief without forcing it into a movie-set frame.

    Conventions for every suggestion:
    - name: a specific noun phrase, at most 4 words. "Weathered Oak Lantern" beats "A lantern".
    - category: choose exactly one of: furniture, architecture, prop, vegetation, vehicle, other. Don't pad with "other".
    - description: ONE concrete sentence describing what the piece is and the texture/feel that makes it specific. Present tense. No hedging.
    - prompt_seed: a single image-generation prompt for the piece on its own (think product shot or hero shot), with materials, lighting, and backdrop. 1–2 sentences.
    - tags: 2–5 short lowercase tokens (single words or short hyphenated phrases).

    Avoid clichés, generic adjectives ("beautiful", "amazing"), and pieces that are too abstract to photograph. Lean into the user's free-text description if they gave one — at least one detail in each suggestion should echo something specific they wrote. If they gave none, propose a small, versatile starter set that fits the project type.

    Aim for 4–8 suggestions, balanced across categories where the brief supports it.

    Output format: RETURN ONLY a single JSON object. No markdown fences. No prose before or after. Schema:
    {
      "pieces": [
        { "name": "...", "category": "...", "description": "...", "prompt_seed": "...", "tags": ["...", "..."] }
      ]
    }
    """

    private static func userPrompt(for request: Request) -> String {
        let title = request.projectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = request.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let setType = request.setType?.trimmingCharacters(in: .whitespacesAndNewlines)
        let inOut = request.interiorExterior?.trimmingCharacters(in: .whitespacesAndNewlines)
        let era = request.era?.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        Project: \(title.isEmpty ? "(untitled)" : title)
        Set type: \(setType?.isEmpty == false ? setType! : "(unspecified)")
        Interior or exterior: \(inOut?.isEmpty == false ? inOut! : "(unspecified)")
        Era / period: \(era?.isEmpty == false ? era! : "(unspecified)")

        Description of the set:
        \(desc.isEmpty ? "(none provided — propose a small versatile starter set that fits the set type and era)" : desc)

        Suggest about \(request.desiredCount) set pieces. Return a single JSON object with the schema described in your instructions.
        """
    }

    // MARK: - Parsing

    private static func parse(_ text: String) -> [Suggestion]? {
        guard let jsonSlice = extractJSONObject(from: text) else { return nil }
        guard let data = jsonSlice.data(using: .utf8) else { return nil }
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let pieces = raw["pieces"] as? [[String: Any]] else { return nil }

        var out: [Suggestion] = []
        for entry in pieces {
            let name = (entry["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let promptSeed = (entry["prompt_seed"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if name.isEmpty || promptSeed.isEmpty { continue }

            let categoryRaw = (entry["category"] as? String)?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let category = SetPieceCategory(rawValue: categoryRaw) ?? .other

            let description = (entry["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let tags: [String]
            if let arr = entry["tags"] as? [String] {
                tags = arr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    .filter { !$0.isEmpty }
            } else {
                tags = []
            }

            out.append(Suggestion(
                name: name,
                category: category,
                description: description,
                promptSeed: promptSeed,
                tags: tags
            ))
        }
        return out
    }

    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        return String(text[start...end])
    }
}
