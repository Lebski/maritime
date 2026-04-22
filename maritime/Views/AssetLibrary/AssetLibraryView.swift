import SwiftUI

struct AssetLibraryView: View {
    @StateObject private var vm: AssetLibraryViewModel

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: AssetLibraryViewModel(project: project))
    }

    var body: some View {
        HStack(spacing: 0) {
            CollapsiblePane(
                isCollapsed: $vm.filtersCollapsed,
                edge: .leading,
                expandedWidth: 240,
                tint: AppModule.assetLibrary.tint,
                icon: AppModule.assetLibrary.icon,
                label: "Filters",
                shortcut: "["
            ) {
                filterRail
            }
            Divider().background(Theme.stroke)
            workspace
            Divider().background(Theme.stroke)
            CollapsiblePane(
                isCollapsed: $vm.inspectorCollapsed,
                edge: .trailing,
                expandedWidth: 300,
                tint: AppModule.assetLibrary.tint,
                icon: "info.circle.fill",
                label: "Details",
                shortcut: "]"
            ) {
                AssetDetailPanel(vm: vm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }

    private var filterRail: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    collectionsSection
                    kindsSection
                    tagsSection
                }
                .padding(12)
            }
        }
        .background(Theme.bgElevated)
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppModule.assetLibrary.tint.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: AppModule.assetLibrary.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppModule.assetLibrary.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Asset Library")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(vm.assets.count) assets")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            Divider().background(Theme.stroke)
        }
    }

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("Collections", icon: "rectangle.stack.fill")
            ForEach(vm.collections) { col in
                Button(action: { vm.setActiveCollection(col) }) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(col.tint)
                            .frame(width: 8, height: 8)
                        Text(col.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(col.count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(vm.selectedCollection?.id == col.id ? col.tint.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plainSolid)
            }
        }
    }

    private var kindsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("Type", icon: "square.grid.2x2.fill")
            Button(action: { vm.selectedKind = nil }) {
                HStack(spacing: 10) {
                    Image(systemName: "asterisk")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(vm.selectedKind == nil ? AppModule.assetLibrary.tint : Theme.textTertiary)
                        .frame(width: 18)
                    Text("All")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(vm.selectedKind == nil ? AppModule.assetLibrary.tint.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plainSolid)

            ForEach(AssetKind.allCases) { kind in
                Button(action: { vm.selectedKind = kind }) {
                    HStack(spacing: 10) {
                        Image(systemName: kind.icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(vm.selectedKind == kind ? kind.tint : Theme.textTertiary)
                            .frame(width: 18)
                        Text(kind.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(vm.assets.filter { $0.kind == kind }.count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(vm.selectedKind == kind ? kind.tint.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plainSolid)
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("Tags", icon: "tag.fill")
            FlowLayout(spacing: 4) {
                ForEach(vm.allTags(), id: \.self) { tag in
                    Button(action: { vm.searchText = tag }) {
                        Text("#\(tag)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.white.opacity(0.05))
                            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plainSolid)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
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

    private var workspace: some View {
        VStack(spacing: 0) {
            workspaceHeader
            AssetGridView(vm: vm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var workspaceHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                TextField("Search assets or tags…", text: $vm.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textPrimary)
                if !vm.searchText.isEmpty {
                    Button(action: { vm.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plainSolid)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(maxWidth: 320)

            Spacer()

            Toggle(isOn: $vm.favoritesOnly) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                    Text("Favorites")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(vm.favoritesOnly ? Theme.magenta : Theme.textSecondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            Text("\(vm.filtered.count) of \(vm.assets.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)

            Button(action: {}) {
                Label("Import", systemImage: "square.and.arrow.down.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(AppModule.assetLibrary.tint)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }
}
