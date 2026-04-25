import SwiftUI

struct StoryForgeView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var navigator: AppNavigator
    @StateObject private var vm: StoryForgeViewModel

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
        workspace
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg)
            .onAppear { consumePendingSceneBreakdownID() }
            .onChange(of: navigator.pendingSceneBreakdownID) { _, _ in consumePendingSceneBreakdownID() }
    }

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
            overallCompletionBadge(value: bible.overallCompletion)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
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
