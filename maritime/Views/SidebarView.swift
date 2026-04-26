import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppModule
    @Environment(\.openSettings) private var openSettings

    private let productionModules: [AppModule] = [
        .storyForge, .characterLab, .setDesign, .storyboard, .frameBuilder, .videoRenderer
    ]
    private let libraryModules: [AppModule] = [.assetLibrary, .exports]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
            Divider().background(Theme.stroke).padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section(title: nil, modules: [.home])
                    section(title: "PRODUCTION", modules: productionModules)
                    section(title: "LIBRARY", modules: libraryModules)
                }
                .padding(.vertical, 16)
            }

            Spacer(minLength: 0)
            userFooter
            versionLabel
        }
        .background(Theme.bgElevated.ignoresSafeArea())
    }

    private var versionLabel: some View {
        Text(BuildInfo.versionString)
            .font(.system(size: 10, weight: .regular))
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 10)
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 34, height: 34)
                Image(systemName: "film.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Movie Maker")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("AI Filmmaking Studio")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
        .padding(16)
    }

    @ViewBuilder
    private func section(title: String?, modules: [AppModule]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
            }
            ForEach(modules) { module in
                SidebarRow(module: module, isSelected: selection == module) {
                    selection = module
                }
            }
        }
    }

    private var userFooter: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.heroGradient)
                .frame(width: 30, height: 30)
                .overlay(Text("AR").font(.system(size: 11, weight: .bold)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 1) {
                Text("Alex Reyes")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Director · Pro")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plainSolid)
            .help("Settings (⌘,)")
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(12)
    }
}

private struct SidebarRow: View {
    let module: AppModule
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: module.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? module.tint : Theme.textSecondary)
                    .frame(width: 20)
                Text(module.shortTitle)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
            )
            .padding(.horizontal, 10)
        }
        .buttonStyle(.plainSolid)
    }
}
