import Foundation

/// Concrete `SetPieceGenerationService` backed by fal.ai Nano Banana 2.
///
/// Reads the API key from Keychain at call time so it always sees the
/// latest value the user has saved in Preferences. If a reference image
/// is attached, posts to the `/edit` endpoint; otherwise plain text-to-image.
struct FalaiSetPieceService: SetPieceGenerationService {

    var category: SetPieceCategory?

    func generate(request: SetPieceRenderRequest) async throws -> Data {
        let key = KeychainStore.get(account: .fal) ?? ""
        let client = FalaiClient(apiKey: key)

        let prompt = composedPrompt(for: request)
        let imageURLs = request.referenceImage.map { [dataURIForImage($0)] }

        let payload = FalaiClient.GenerateRequest(
            prompt: prompt,
            image_urls: imageURLs,
            num_images: 1,
            aspect_ratio: "1:1",
            output_format: "png",
            resolution: "1K"
        )

        return try await client.generateAndFetch(payload, edit: imageURLs != nil, label: "Set piece image")
    }

    /// Append a category hint to the prompt seed so generated pieces stay on-style
    /// for the slot they're filling. The user's prompt always leads.
    private func composedPrompt(for request: SetPieceRenderRequest) -> String {
        let trimmed = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix: String
        switch request.category {
        case .furniture, .architecture, .vehicle:
            suffix = " Studio product photography, neutral backdrop, soft even lighting."
        case .prop:
            suffix = " Hero prop shot, neutral backdrop, sharp focus."
        case .vegetation:
            suffix = " Botanical reference, neutral backdrop, natural lighting."
        case .other:
            suffix = ""
        }
        return trimmed + suffix
    }
}
