import SwiftUI

struct StoryForgeView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var navigator: AppNavigator
    @EnvironmentObject var settings: AppSettings
    @StateObject private var vm: StoryForgeViewModel
    @State private var showHelper = false
    @State private var showInnerSidebar = true

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: StoryForgeViewModel(project: project))
    }

    private func consumePendingSceneBreakdownID() {
        guard let id = navigator.pendingSceneBreakdownID,
              project.bible.sceneBreakdowns.contains(where: { $0.id == id }) else { return }
        vm.activeSection = .scenes
        vm.expandedSceneID = id
        navigator.pendingSceneBreakdownID = nil
    }

    var body: some View {
        HStack(spacing: 0) {
            if showInnerSidebar {
                sidebar
                    .frame(width: 260)
                    .background(Theme.bgElevated)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                Divider().background(Theme.stroke)
            }
            workspace
                .frame(maxWidth: .infinity)
            if showHelper {
                Divider().background(Theme.stroke)
                StoryForgeHelperPanel(vm: vm)
                    .frame(width: 320)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showHelper)
        .animation(.easeInOut(duration: 0.22), value: showInnerSidebar)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .onAppear { consumePendingSceneBreakdownID() }
        .onChange(of: navigator.pendingSceneBreakdownID) { _, _ in consumePendingSceneBreakdownID() }
        .sheet(item: $vm.bibleWizardMode) { mode in
            StoryBibleWizardSheet(mode: mode, vm: vm)
        }
        .sheet(isPresented: $vm.showSceneDiff) {
            if let proposal = vm.pendingSceneDiff {
                SceneRegenDiffSheet(vm: vm, proposal: proposal)
            }
        }
    }

    private var sidebarToggle: some View {
        Button(action: { showInnerSidebar.toggle() }) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(showInnerSidebar ? Theme.magenta : Theme.textTertiary)
                .frame(width: 30, height: 30)
                .background(showInnerSidebar ? Theme.magenta.opacity(0.14) : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
        .help(showInnerSidebar ? "Hide sidebar" : "Show sidebar")
    }

    private var helperToggle: some View {
        Button(action: { showHelper.toggle() }) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(showHelper ? Theme.magenta : Theme.textTertiary)
                .frame(width: 30, height: 30)
                .background(showHelper ? Theme.magenta.opacity(0.14) : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
        .help(showHelper ? "Hide helper panel" : "Show helper panel")
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            sidebarProgress
            Divider().background(Theme.stroke)
            sidebarActions
            Spacer(minLength: 0)
        }
    }

    private var sidebarHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.magenta.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.magenta)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Story Forge")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Your story bible")
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

    private var sidebarProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SECTION PROGRESS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            ForEach(StoryForgeSection.allCases) { section in
                progressRow(section: section)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func progressRow(section: StoryForgeSection) -> some View {
        let value = vm.bible.completion(for: section)
        let isActive = vm.activeSection == section
        return Button(action: { vm.selectSection(section) }) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isActive ? Theme.magenta : Theme.textSecondary)
                    .frame(width: 16)
                Text(section.shortTitle)
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
                CompletionRing(value: value, size: 16, color: Theme.magenta)
                Text("\(Int(value * 100))%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isActive ? Theme.magenta.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var sidebarActions: some View {
        VStack(spacing: 8) {
            Text("PROMOTE")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            promoteButton(
                icon: "person.crop.artframe",
                label: "Send to Character Lab",
                tint: Theme.teal,
                count: unpromotedDrafts
            ) {
                vm.activeSection = .characters
            }
            promoteButton(
                icon: "photo.stack.fill",
                label: "Send to Scene Builder",
                tint: Theme.accent,
                count: unpromotedScenes
            ) {
                vm.activeSection = .scenes
            }
        }
        .padding(14)
    }

    private var unpromotedDrafts: Int {
        vm.bible.characterDrafts.filter { !$0.isPromoted }.count
    }

    private var unpromotedScenes: Int {
        vm.bible.sceneBreakdowns.filter { !$0.isPromoted }.count
    }

    private func promoteButton(icon: String, label: String, tint: Color, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tint)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(tint.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    // MARK: Workspace

    private var workspace: some View {
        VStack(spacing: 0) {
            workspaceHeader(bible: vm.bible)
            Divider().background(Theme.stroke)
            tabRow(bible: vm.bible)
            Divider().background(Theme.stroke)
            sectionContent
        }
    }

    private func workspaceHeader(bible: StoryBible) -> some View {
        HStack(spacing: 14) {
            sidebarToggle
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: bible.posterColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(bible.projectTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                if bible.logline.isEmpty {
                    Text("No logline yet — every story needs one sentence.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .italic()
                } else {
                    Text(bible.logline)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            editDescriptionButton
            helperToggle
            overallCompletionBadge(value: bible.overallCompletion)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var editDescriptionButton: some View {
        Button(action: { vm.openBibleWizard(mode: .regenerateFromPitch) }) {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
        .help("Edit Description & Regenerate")
    }

    private func overallCompletionBadge(value: Double) -> some View {
        HStack(spacing: 8) {
            CompletionRing(value: value, size: 28, color: Theme.magenta, showLabel: true)
            VStack(alignment: .leading, spacing: 1) {
                Text("OVERALL")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
                Text("\(Int(value * 100))% complete")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.card)
        .overlay(
            Capsule().stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private func tabRow(bible: StoryBible) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StoryForgeSection.allCases) { section in
                    SectionTabButton(
                        section: section,
                        isActive: vm.activeSection == section,
                        completion: bible.completion(for: section)
                    ) {
                        vm.selectSection(section)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch vm.activeSection {
        case .characters:
            CharacterBuilderView(vm: vm)
        case .structure:
            StoryStructureView(vm: vm)
        case .scenes:
            SceneBreakdownView(vm: vm)
        case .theme:
            ThemeTrackerView(vm: vm)
        }
    }

}
