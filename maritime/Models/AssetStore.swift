import SwiftUI

// MARK: - Asset Library projection
//
// The Asset Library is a derived view over the open project. Each asset
// borrows the underlying entity's UUID (LabCharacter / SceneBackground /
// SceneProp / FilmScene) so favorites, selection, and SwiftUI diffing stay
// stable across re-derivations. The library always reflects the current
// document — there is no parallel sample catalogue.

@MainActor
extension MovieBlazeProject {

    var assets: [Asset] {
        var result: [Asset] = []
        let linked: [String] = [bible.projectTitle]

        // Characters
        for ch in characters {
            let gradient = ch.finalVariation?.gradientColors
                ?? ch.selectedVariations.first?.gradientColors
                ?? [Theme.teal.opacity(0.8), Theme.violet.opacity(0.8)]
            let tags = [ch.role, ch.isFinalized ? "finalized" : "in-lab"]
                .map { $0.lowercased() }
                .filter { !$0.isEmpty }
            let baseVersions = max(1, ch.selectedVariations.count)
            result.append(Asset(
                id: ch.id,
                name: ch.name,
                kind: .character,
                tags: tags,
                versions: baseVersions + (assetEditCounts[ch.id] ?? 0),
                favorited: favoritedAssetIDs.contains(ch.id),
                linkedProjects: linked,
                updatedLabel: ch.isFinalized ? "Finalized" : "In Character Lab",
                gradientColors: gradient
            ))
        }

        // Backgrounds — unique by id across all scenes
        var seenBg = Set<UUID>()
        for scene in scenes {
            guard let bg = scene.background, seenBg.insert(bg.id).inserted else { continue }
            let usage = scenes.filter { $0.background?.id == bg.id }.count
            result.append(Asset(
                id: bg.id,
                name: bg.name,
                kind: .background,
                tags: [bg.tag.lowercased()].filter { !$0.isEmpty },
                versions: usage + (assetEditCounts[bg.id] ?? 0),
                favorited: favoritedAssetIDs.contains(bg.id),
                linkedProjects: linked,
                updatedLabel: usage == 1 ? "1 scene" : "\(usage) scenes",
                gradientColors: bg.gradientColors
            ))
        }

        // Props — unique by id across all scenes
        var seenProp = Set<UUID>()
        for scene in scenes {
            for prop in scene.props {
                guard seenProp.insert(prop.id).inserted else { continue }
                let usage = scenes.filter { $0.props.contains(where: { $0.id == prop.id }) }.count
                result.append(Asset(
                    id: prop.id,
                    name: prop.name,
                    kind: .prop,
                    tags: [prop.category.lowercased()].filter { !$0.isEmpty },
                    versions: usage + (assetEditCounts[prop.id] ?? 0),
                    favorited: favoritedAssetIDs.contains(prop.id),
                    linkedProjects: linked,
                    updatedLabel: usage == 1 ? "1 scene" : "\(usage) scenes",
                    gradientColors: [prop.tint.opacity(0.85), prop.tint.opacity(0.35)]
                ))
            }
        }

        return result
    }

    var assetCollections: [AssetCollection] {
        let all = assets
        return [
            AssetCollection(name: "All Assets", count: all.count, tint: Theme.accent),
            AssetCollection(name: "Favorites", count: all.filter(\.favorited).count, tint: Theme.magenta),
            AssetCollection(name: bible.projectTitle, count: all.count, tint: Theme.teal)
        ]
    }

    func toggleAssetFavorite(id: UUID) {
        if favoritedAssetIDs.contains(id) {
            favoritedAssetIDs.remove(id)
        } else {
            favoritedAssetIDs.insert(id)
        }
    }
}
