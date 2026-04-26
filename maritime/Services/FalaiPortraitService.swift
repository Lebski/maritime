import Foundation

/// Input the Character Lab passes to the portrait service.
struct PortraitGenerationRequest {
    var name: String
    var role: String
    var description: String
    var answers: CharacterSetupAnswers
    var count: Int
}

/// Abstraction so the Character Lab can be tested without hitting the network.
protocol PortraitGenerationService {
    func generate(request: PortraitGenerationRequest) async throws -> [PortraitVariation]
    func composedPrompt(for request: PortraitGenerationRequest) -> String
}

/// Concrete portrait generator backed by fal.ai's recraft-v4. Reads the fal
/// API key from Keychain at call time so it always sees the latest value the
/// user has saved in Preferences.
struct FalaiPortraitService: PortraitGenerationService {

    /// recraft-v4-pro produces one image per submission, so we fan out N
    /// parallel queue jobs (capped) and gather them as they finish.
    private static let maxConcurrency = 5

    func generate(request: PortraitGenerationRequest) async throws -> [PortraitVariation] {
        let key = KeychainStore.get(account: .fal) ?? ""
        let client = RecraftClient(apiKey: key)

        let prompt = composedPrompt(for: request)
        let count = max(1, min(20, request.count))
        let payload = RecraftClient.GenerateRequest(
            prompt: prompt,
            image_size: "portrait_4_3",
            enable_safety_checker: true
        )

        let concurrency = min(Self.maxConcurrency, count)

        return try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            var nextIndex = 0
            for _ in 0..<concurrency {
                let i = nextIndex
                nextIndex += 1
                group.addTask {
                    try await Self.runOne(index: i, total: count, client: client, payload: payload)
                }
            }
            var out: [PortraitVariation] = []
            out.reserveCapacity(count)
            while let (index, bytes) = try await group.next() {
                out.append(PortraitVariation(index: index, imageData: bytes, seed: nil))
                if nextIndex < count {
                    let i = nextIndex
                    nextIndex += 1
                    group.addTask {
                        try await Self.runOne(index: i, total: count, client: client, payload: payload)
                    }
                }
            }
            return out.sorted { $0.index < $1.index }
        }
    }

    private static func runOne(index: Int,
                               total: Int,
                               client: RecraftClient,
                               payload: RecraftClient.GenerateRequest) async throws -> (Int, Data) {
        let label = "Character portrait \(index + 1)/\(total)"
        let response = try await client.submitAndAwait(payload, label: label)
        guard let first = response.images.first else {
            throw RecraftClient.ClientError.empty
        }
        let bytes = try await client.downloadImage(url: first.url)
        return (index, bytes)
    }

    /// Compose a single prompt string for recraft-v4. The user's free-form
    /// description leads; non-empty guided answers append as comma-joined
    /// modifiers; a trailing photographic suffix nails framing and lighting.
    func composedPrompt(for request: PortraitGenerationRequest) -> String {
        let description = request.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let role = request.role.trimmingCharacters(in: .whitespacesAndNewlines)

        var parts: [String] = []
        if !description.isEmpty {
            parts.append(description)
        } else {
            parts.append("a \(role.lowercased()) character")
        }

        let modifiers = request.answers.promptFragments
        if !modifiers.isEmpty {
            parts.append(modifiers.joined(separator: ", "))
        }

        parts.append(
            "studio portrait photo, head and shoulders, neutral background, soft natural lighting, sharp focus, photorealistic"
        )

        return parts.joined(separator: ". ")
    }
}
