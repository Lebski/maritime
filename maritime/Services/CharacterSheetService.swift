import Foundation

/// Generates a single reference sheet (turnaround / full body / expressions /
/// action poses / portrait re-render) from a chosen portrait. Uses fal.ai's
/// nano-banana-2 `/edit` endpoint so the new image keeps the likeness of the
/// portrait the user picked.
struct CharacterSheetService {

    func generate(sheet: ReferenceSheetType,
                  portrait: PortraitVariation,
                  character: LabCharacter) async throws -> Data {
        let key = KeychainStore.get(account: .fal) ?? ""
        let client = FalaiClient(apiKey: key)

        let prompt = Self.composedPrompt(sheet: sheet, character: character)
        let payload = FalaiClient.GenerateRequest(
            prompt: prompt,
            image_urls: [dataURIForImage(portrait.imageData)],
            num_images: 1,
            aspect_ratio: aspectRatio(for: sheet),
            output_format: "png",
            resolution: "1K"
        )

        return try await client.generateAndFetch(payload, edit: true, label: "Character sheet · \(label(for: sheet))")
    }

    private func label(for sheet: ReferenceSheetType) -> String {
        switch sheet {
        case .portrait:    return "portrait"
        case .turnaround:  return "turnaround"
        case .fullBody:    return "full body"
        case .expressions: return "expressions"
        case .actionPoses: return "action poses"
        }
    }

    /// 16:9 for full-body / poses / turnaround (wide multi-view layouts);
    /// 1:1 for portrait & expression sheet.
    private func aspectRatio(for sheet: ReferenceSheetType) -> String {
        switch sheet {
        case .portrait, .expressions: return "1:1"
        case .turnaround, .fullBody, .actionPoses: return "16:9"
        }
    }

    static func composedPrompt(sheet: ReferenceSheetType, character: LabCharacter) -> String {
        let identity = "Same character as the reference photo: \(character.name), \(character.role)."
        let body: String
        switch sheet {
        case .portrait:
            body = "Re-render as a clean studio portrait: head and shoulders, neutral 3/4 angle, even soft lighting, neutral grey backdrop. Keep facial features and hair identical to the reference."
        case .turnaround:
            body = "Head turnaround sheet, single image, five views in a row at the same height: front, 3/4, profile, 3/4 back, back. Neutral expression, even studio lighting, plain grey background. Keep facial features identical to the reference."
        case .fullBody:
            body = "Full-body shot, A-pose facing camera, plain grey background, even studio lighting. Show the entire figure from head to feet. Keep face and proportions consistent with the reference."
        case .expressions:
            body = "Expression sheet, single image, 2x3 grid of head-and-shoulders views: happy, sad, angry, surprised, disgusted, neutral. Same lighting and angle in every cell. Keep facial features identical to the reference."
        case .actionPoses:
            body = "Action poses sheet, single image, four full-body poses in a row: walking, running, sitting, gesturing. Plain grey background, even lighting. Keep face and outfit consistent with the reference."
        }
        return identity + " " + body
    }
}
