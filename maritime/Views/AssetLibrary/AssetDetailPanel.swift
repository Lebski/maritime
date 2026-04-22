import SwiftUI

struct AssetDetailPanel: View {
    @ObservedObject var vm: AssetLibraryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let asset = vm.selectedAsset {
                    hero(asset: asset)
                    tagsCard(asset: asset)
                    versionsCard(asset: asset)
                    linkedCard(asset: asset)
                } else {
                    emptyState
                }
            }
            .padding(14)
        }
        .background(Theme.bgElevated)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 24))
                .foregroundStyle(Theme.textTertiary)
            Text("Select an asset")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func hero(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                LinearGradient(colors: asset.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: asset.kind.icon)
                    .font(.system(size: 38))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                Text(asset.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Button(action: { vm.toggleFavorite(asset) }) {
                    Image(systemName: asset.favorited ? "heart.fill" : "heart")
                        .font(.system(size: 11))
                        .foregroundStyle(asset.favorited ? Theme.magenta : Theme.textTertiary)
                        .padding(6)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                Image(systemName: asset.kind.icon)
                    .font(.system(size: 10))
                Text(asset.kind.rawValue)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(asset.kind.tint)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(asset.kind.tint.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(12)
        .cardStyle()
    }

    private func tagsCard(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Tags", icon: "tag.fill")
            FlowLayout(spacing: 6) {
                ForEach(asset.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(asset.kind.tint)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(asset.kind.tint.opacity(0.15))
                        .overlay(Capsule().stroke(asset.kind.tint.opacity(0.4), lineWidth: 1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .cardStyle()
    }

    private func versionsCard(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Versions", icon: "clock.arrow.circlepath")
            ForEach(0..<asset.versions, id: \.self) { i in
                let v = asset.versions - i
                HStack(spacing: 10) {
                    Circle()
                        .fill(i == 0 ? AppModule.assetLibrary.tint : Color.white.opacity(0.15))
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("v\(v)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(i == 0 ? asset.updatedLabel : "\(i * 2 + 1)d ago")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    if i == 0 {
                        Text("CURRENT")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(AppModule.assetLibrary.tint)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(AppModule.assetLibrary.tint.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .padding(12)
        .cardStyle()
    }

    private func linkedCard(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Linked Projects", icon: "link")
            if asset.linkedProjects.isEmpty {
                Text("Not linked to any project yet.")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                ForEach(asset.linkedProjects, id: \.self) { p in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.heroGradient)
                            .frame(width: 8, height: 8)
                        Text(p)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .padding(12)
        .cardStyle()
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppModule.assetLibrary.tint)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
    }
}
