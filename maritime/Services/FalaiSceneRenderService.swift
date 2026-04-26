import Foundation

/// Concrete `ImageGenerationService` backed by fal.ai Nano Banana 2.
///
/// Composes up to 14 reference images (scene composition + character refs +
/// style refs) into the `image_urls` array as base64 data URIs and posts to
/// the `/edit` endpoint. Falls back to plain text-to-image when no refs exist.
struct FalaiSceneRenderService: ImageGenerationService {

    private static let maxImages = 14

    func generate(package: RenderPackage) async throws -> Data {
        let key = KeychainStore.get(account: .fal) ?? ""
        let client = FalaiClient(apiKey: key)

        var imageURLs: [String] = []
        if let composition = package.sceneCompositionImage {
            imageURLs.append(dataURIForImage(composition))
        }
        for ref in package.characterReferences {
            if let data = ref.imageData {
                imageURLs.append(dataURIForImage(data))
            }
        }
        for ref in package.styleReferences {
            imageURLs.append(dataURIForImage(ref.imageData))
        }

        if imageURLs.count > Self.maxImages {
            imageURLs = Array(imageURLs.prefix(Self.maxImages))
        }

        let payload = FalaiClient.GenerateRequest(
            prompt: package.prompt,
            image_urls: imageURLs.isEmpty ? nil : imageURLs,
            num_images: 1,
            aspect_ratio: package.aspectRatio.rawValue,
            output_format: "png",
            resolution: "1K"
        )

        return try await client.generateAndFetch(payload, edit: !imageURLs.isEmpty, label: "Scene render")
    }
}
