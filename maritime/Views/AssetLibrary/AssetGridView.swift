import SwiftUI

struct AssetGridView: View {
    @ObservedObject var vm: AssetLibraryViewModel

    private let columns = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 14)]

    var body: some View {
        if vm.filtered.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(vm.filtered) { asset in
                        AssetTile(asset: asset,
                                  isActive: vm.selectedAssetID == asset.id,
                                  onTap: { vm.setActive(asset) },
                                  onToggleFav: { vm.toggleFavorite(asset) })
                    }
                }
                .padding(20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(Theme.textTertiary)
            Text("No assets match those filters")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Try clearing search or a different collection.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AssetTile: View {
    let asset: Asset
    let isActive: Bool
    let onTap: () -> Void
    let onToggleFav: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                thumbnail
                meta
            }
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isActive ? asset.kind.tint : Theme.stroke,
                            lineWidth: isActive ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var thumbnail: some View {
        ZStack {
            LinearGradient(colors: asset.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: asset.kind.icon)
                .font(.system(size: 34))
                .foregroundStyle(.white.opacity(0.35))

            VStack {
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: asset.kind.icon)
                            .font(.system(size: 8, weight: .semibold))
                        Text(asset.kind.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(.black.opacity(0.55))
                    .clipShape(Capsule())
                    Spacer()
                    Button(action: onToggleFav) {
                        Image(systemName: asset.favorited ? "heart.fill" : "heart")
                            .font(.system(size: 10))
                            .foregroundStyle(asset.favorited ? Theme.magenta : .white)
                            .padding(6)
                            .background(.black.opacity(0.45))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                if asset.versions > 1 {
                    HStack {
                        Spacer()
                        Text("v\(asset.versions)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(.black.opacity(0.55))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(8)
        }
        .frame(height: 120)
    }

    private var meta: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(asset.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            HStack(spacing: 4) {
                ForEach(asset.tags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 9))
                        .foregroundStyle(asset.kind.tint)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(asset.kind.tint.opacity(0.15))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            Text(asset.updatedLabel)
                .font(.system(size: 9))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
    }
}
