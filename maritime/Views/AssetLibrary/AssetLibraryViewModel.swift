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

    let project: MovieBlazeProject
    let photoshopBridge: PhotoshopBridge
    private var cancellables: Set<AnyCancellable> = []

    init(project: MovieBlazeProject) {
        self.project = project
        self.photoshopBridge = PhotoshopBridge(project: project)
        selectedAssetID = project.assets.first?.id
        selectedCollectionID = project.assetCollections.first?.id
        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        photoshopBridge.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: Photoshop round-trip

    func editInPhotoshop(_ asset: Asset) {
        photoshopBridge.beginEditing(asset)
    }

    func stopEditingInPhotoshop(_ asset: Asset) {
        photoshopBridge.endEditing(asset.id)
    }

    func isEditingInPhotoshop(_ asset: Asset) -> Bool {
        photoshopBridge.isEditing(asset.id)
    }

    func revealEditFile(for asset: Asset) {
        guard let url = photoshopBridge.tempFileURL(for: asset.id) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func assetImage(for asset: Asset) -> NSImage? {
        guard let data = project.assetImageData(for: asset.id) else { return nil }
        return NSImage(data: data)
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
