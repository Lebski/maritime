import SwiftUI
import Combine

@MainActor
final class AssetLibraryViewModel: ObservableObject {
    @Published var assets: [Asset] = AssetLibrarySamples.assets
    @Published var collections: [AssetCollection] = AssetLibrarySamples.collections
    @Published var selectedKind: AssetKind? = nil
    @Published var selectedCollection: AssetCollection? = AssetLibrarySamples.collections.first
    @Published var selectedAssetID: UUID?
    @Published var searchText: String = ""
    @Published var favoritesOnly: Bool = false

    @Published var filtersCollapsed: Bool = false
    @Published var inspectorCollapsed: Bool = false

    init() {
        selectedAssetID = assets.first?.id
    }

    var selectedAsset: Asset? {
        assets.first(where: { $0.id == selectedAssetID })
    }

    var filtered: [Asset] {
        assets.filter { asset in
            if favoritesOnly && !asset.favorited { return false }
            if let kind = selectedKind, asset.kind != kind { return false }
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                if !asset.name.lowercased().contains(q),
                   !asset.tags.joined(separator: " ").lowercased().contains(q) {
                    return false
                }
            }
            if let col = selectedCollection, col.name != "All Assets" {
                if col.name == "Favorites" { return asset.favorited }
                if !asset.linkedProjects.contains(col.name) { return false }
            }
            return true
        }
    }

    func setActive(_ asset: Asset) { selectedAssetID = asset.id }

    func toggleFavorite(_ asset: Asset) {
        guard let idx = assets.firstIndex(where: { $0.id == asset.id }) else { return }
        assets[idx].favorited.toggle()
    }

    func allTags() -> [String] {
        Array(Set(assets.flatMap(\.tags))).sorted()
    }

    func tagCount(_ tag: String) -> Int {
        assets.filter { $0.tags.contains(tag) }.count
    }
}
