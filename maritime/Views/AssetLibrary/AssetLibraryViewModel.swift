import SwiftUI
import Combine

// MARK: - Asset Library view model
//
// Holds local UI state (filters, selection, panel collapse). The asset list
// and collections are derived projections of the open MovieBlazeProject —
// favorites and search filter on top of that derivation.

@MainActor
final class AssetLibraryViewModel: ObservableObject {
    @Published var selectedKind: AssetKind? = nil
    @Published var selectedCollectionID: UUID?
    @Published var selectedAssetID: UUID?
    @Published var searchText: String = ""
    @Published var favoritesOnly: Bool = false

    @Published var filtersCollapsed: Bool = false
    @Published var inspectorCollapsed: Bool = false

    private let project: MovieBlazeProject
    private var cancellables: Set<AnyCancellable> = []

    init(project: MovieBlazeProject) {
        self.project = project
        selectedAssetID = project.assets.first?.id
        selectedCollectionID = project.assetCollections.first?.id
        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: Derived state

    var assets: [Asset] { project.assets }
    var collections: [AssetCollection] { project.assetCollections }

    var selectedCollection: AssetCollection? {
        guard let id = selectedCollectionID else { return collections.first }
        return collections.first(where: { $0.id == id }) ?? collections.first
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
            if let col = selectedCollection {
                switch col.name {
                case "All Assets":
                    break
                case "Favorites":
                    if !asset.favorited { return false }
                default:
                    if !asset.linkedProjects.contains(col.name) { return false }
                }
            }
            return true
        }
    }

    // MARK: Mutations

    func setActive(_ asset: Asset) { selectedAssetID = asset.id }

    func setActiveCollection(_ collection: AssetCollection) {
        selectedCollectionID = collection.id
    }

    func toggleFavorite(_ asset: Asset) {
        project.toggleAssetFavorite(id: asset.id)
    }

    func allTags() -> [String] {
        Array(Set(assets.flatMap(\.tags))).sorted()
    }

    func tagCount(_ tag: String) -> Int {
        assets.filter { $0.tags.contains(tag) }.count
    }
}
