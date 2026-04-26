import SwiftUI

struct CharacterLabView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @StateObject private var vm: CharacterLabViewModel

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: CharacterLabViewModel(project: project))
    }

    var body: some View {
        HStack(spacing: 0) {
            CollapsiblePane(
                isCollapsed: $vm.sidebarCollapsed,
                edge: .leading,
                expandedWidth: 280,
                tint: AppModule.characterLab.tint,
                icon: AppModule.characterLab.icon,
                label: "Characters",
                shortcut: "["
            ) {
                sidebar.background(Theme.bgElevated)
            }
            Divider().background(Theme.stroke)
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .sheet(isPresented: $vm.showNewCharacter) {
            NewCharacterSheet(vm: vm)
        }
        .sheet(isPresented: $vm.showReferenceSheet) {
            if let char = vm.activeCharacter {
                ReferenceSheetView(character: char, vm: vm)
            }
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            sidebarList
            sidebarFooter
        }
    }

    private var sidebarHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.teal.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "person.crop.artframe")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.teal)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Character Lab")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Design consistent heroes")
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

    private var sidebarList: some View {
        ScrollView {
            VStack(spacing: 4) {
                SidebarSection(label: "My Characters") {
                    ForEach(vm.characters) { char in
                        CharacterRowView(character: char, isActive: vm.activeCharacter?.id == char.id) {
                            vm.setActive(char)
                        }
                    }
                }
                SidebarSection(label: "Library", collapsible: true, initiallyCollapsed: true) {
                    ForEach(CharacterLabSamples.libraryCharacters) { char in
                        CharacterRowView(character: char, isActive: vm.activeCharacter?.id == char.id) {
                            vm.setActive(char)
                        }
                    }
                }
            }
            .padding(10)
        }
    }

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.stroke)
            Button(action: { vm.showNewCharacter = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.teal)
                    Text("New Character")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.teal)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plainSolid)
        }
    }

    // MARK: Main Content

    @ViewBuilder
    private var content: some View {
        if let char = vm.activeCharacter {
            CharacterWorkspaceView(character: char, vm: vm)
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.teal.opacity(0.10))
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(Theme.teal.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: 150, height: 150)
                Image(systemName: "person.crop.artframe")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Theme.teal)
            }
            Text("Select or Create a Character")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Use the sidebar to pick an existing character\nor start a new one from scratch.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: { vm.showNewCharacter = true }) {
                Label("New Character", systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.teal)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sidebar Helpers

struct SidebarSection<Content: View>: View {
    let label: String
    var collapsible: Bool
    var initiallyCollapsed: Bool
    @ViewBuilder let content: Content
    @State private var isCollapsed: Bool

    init(label: String,
         collapsible: Bool = false,
         initiallyCollapsed: Bool = false,
         @ViewBuilder content: () -> Content) {
        self.label = label
        self.collapsible = collapsible
        self.initiallyCollapsed = initiallyCollapsed
        self.content = content()
        _isCollapsed = State(initialValue: collapsible && initiallyCollapsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            header
            if !collapsible || !isCollapsed {
                content
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            if collapsible {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            guard collapsible else { return }
            withAnimation(.easeInOut(duration: 0.18)) { isCollapsed.toggle() }
        }
    }
}

struct CharacterRowView: View {
    let character: LabCharacter
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(avatarColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(character.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(character.statusLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(character.isFinalized ? Theme.teal : Theme.textTertiary)
                }
                Spacer()
                if character.isFinalized {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.teal)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? Theme.teal.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? Theme.teal.opacity(0.35) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var avatarColor: Color {
        character.finalVariation?.accentColor ?? Theme.teal
    }
}
