import SwiftUI

// MARK: - Storyboard Details View
//
// The "Details" step of the Storyboard module. Single flat panel list for
// the project. Workspace shows tabs and tab content.

struct StoryboardDetailsView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var navigator: AppNavigator
    @StateObject private var vm: StoryboardComposerViewModel

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: StoryboardComposerViewModel(project: project))
    }

    var body: some View {
        workspace
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg)
            .sheet(isPresented: $vm.showNewPanelSheet) {
                NewStoryboardPanelSheet(vm: vm)
            }
            .onAppear { consumePendingSceneBreakdownID() }
            .onChange(of: navigator.pendingSceneBreakdownID) { _, _ in
                consumePendingSceneBreakdownID()
            }
    }

    private func consumePendingSceneBreakdownID() {
        guard let id = navigator.pendingSceneBreakdownID else { return }
        if let panel = vm.panels.first(where: { $0.sceneBreakdownID == id }) {
            vm.selectPanel(panel.id)
        }
        navigator.pendingSceneBreakdownID = nil
    }

    private var workspace: some View {
        VStack(spacing: 0) {
            tabRow
            Divider().background(Theme.stroke)
            tabContent
        }
    }

    private var tabRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ForEach(StoryboardTab.allCases) { tab in
                    storyboardTabButton(tab)
                }
                Spacer()
            }
            Text(vm.activeTab.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
    }

    private func storyboardTabButton(_ tab: StoryboardTab) -> some View {
        let isActive = vm.activeTab == tab
        return Button(action: { vm.selectTab(tab) }) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isActive ? .black : Theme.textSecondary)
                Text(tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isActive ? .black : Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Theme.violet : Color.white.opacity(0.05))
            .overlay(
                Capsule().stroke(isActive ? Color.clear : Theme.stroke, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch vm.activeTab {
        case .panels:  StoryboardPanelsGridView(vm: vm)
        case .rhythm:  RhythmPlannerView(vm: vm)
        case .library: ShotLibraryView(vm: vm)
        }
    }
}
