import Foundation
import Combine

/// User-level preferences shared across all open documents.
/// API keys live in Keychain; model selection lives in UserDefaults.
@MainActor
final class AppSettings: ObservableObject {

    // MARK: Available Anthropic models

    struct ModelOption: Identifiable, Hashable {
        let id: String
        let displayName: String
        let tagline: String
    }

    static let availableModels: [ModelOption] = [
        ModelOption(id: "claude-sonnet-4-6",
                    displayName: "Claude Sonnet 4.6",
                    tagline: "Fast, high quality — good default"),
        ModelOption(id: "claude-opus-4-7",
                    displayName: "Claude Opus 4.7",
                    tagline: "Highest quality, slower"),
        ModelOption(id: "claude-haiku-4-5-20251001",
                    displayName: "Claude Haiku 4.5",
                    tagline: "Fastest, cheapest")
    ]

    private static let modelDefaultsKey = "com.maritime.movieblaze.model"
    private static let defaultModelID = "claude-sonnet-4-6"

    // MARK: Published state

    @Published var apiKey: String {
        didSet { KeychainStore.set(apiKey, account: .anthropic) }
    }

    @Published var modelID: String {
        didSet { UserDefaults.standard.set(modelID, forKey: Self.modelDefaultsKey) }
    }

    @Published var falAPIKey: String {
        didSet { KeychainStore.set(falAPIKey, account: .fal) }
    }

    var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var falIsConfigured: Bool {
        !falAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var currentModel: ModelOption {
        Self.availableModels.first(where: { $0.id == modelID }) ?? Self.availableModels[0]
    }

    // MARK: Init

    init() {
        self.apiKey = KeychainStore.get(account: .anthropic) ?? ""
        let stored = UserDefaults.standard.string(forKey: Self.modelDefaultsKey)
        self.modelID = stored ?? Self.defaultModelID
        self.falAPIKey = KeychainStore.get(account: .fal) ?? ""
    }
}
