import SwiftUI

// MARK: - Storyboard Details View
//
// The "Details" step of the Storyboard module. Single flat panel list for
// the project. Sidebar shows progress + promote action; workspace shows
// step indicator, breadcrumb, tabs, and tab content. This is the original
// Storyboard workspace moved under a segmented picker alongside Moodboard.

struct StoryboardDetailsView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var navigator: AppNavigator
    @StateObject private var vm: StoryboardComposerViewModel
    @State private var showHelper = false
    @State private var showInnerSidebar = true

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: StoryboardComposerViewModel(project: project))
    }

    private func firstOriginScene() -> SceneBreakdown? {
        for panel in vm.panels {
            if let scene = vm.originSceneBreakdown(for: panel) { return scene }
        }
        return nil
    }

    private func goToStep(_ step: StepIndicator.Step) {
        switch step {
        case .storyboard:
            break
        case .outline:
            if let origin = firstOriginScene() {
                navigator.openStoryForge(sceneBreakdownID: origin.id)
            } else {
                navigator.openStoryForge()
            }
        case .frame:
            navigator.go(to: .sceneBuilder)
        case .render:
            navigator.go(to: .videoRenderer)
        }
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
                StoryboardHelperPanel(vm: vm)
                    .frame(width: 320)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showHelper)
        .animation(.easeInOut(duration: 0.22), value: showInnerSidebar)
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

    private var sidebarToggle: some View {
        Button(action: { showInnerSidebar.toggle() }) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(showInnerSidebar ? Theme.violet : Theme.textTertiary)
                .frame(width: 30, height: 30)
                .background(showInnerSidebar ? Theme.violet.opacity(0.14) : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(showInnerSidebar ? "Hide sidebar" : "Show sidebar")
    }

    private var helperToggle: some View {
        Button(action: { showHelper.toggle() }) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(showHelper ? Theme.violet : Theme.textTertiary)
                .frame(width: 30, height: 30)
                .background(showHelper ? Theme.violet.opacity(0.14) : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(showHelper ? "Hide helper panel" : "Show helper panel")
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            sidebarProgress
            Divider().background(Theme.stroke)
            sidebarActions
            Spacer()
        }
    }

    private var sidebarHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.violet.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "square.grid.3x2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.violet)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Storyboard")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Visualize shot sequences")
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
            let panels = vm.panels
            progressStat(icon: "square.grid.3x2.fill", label: "Panels", value: "\(panels.count)", tint: Theme.violet)
            progressStat(icon: "clock.fill", label: "Runtime", value: panels.runtimeLabel, tint: Theme.teal)
            progressStat(icon: "waveform.path", label: "Avg Shot", value: String(format: "%.1fs", panels.averageShotLength), tint: Theme.accent)
            progressStat(icon: "checkmark.seal.fill", label: "Promoted", value: "\(panels.promotedCount)/\(panels.count)", tint: Theme.magenta)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func progressStat(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(tint)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var sidebarActions: some View {
        VStack(spacing: 8) {
            Text("PROMOTE")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: {
                vm.activeTab = .panels
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.teal)
                    Text("Send Panel to Scene Builder")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    let count = vm.panels.unpromotedCount
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.teal)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Theme.teal.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.teal.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
    }

    // MARK: Workspace

    private var workspace: some View {
        VStack(spacing: 0) {
            workspaceHeader
            Divider().background(Theme.stroke)
            tabRow
            Divider().background(Theme.stroke)
            tabContent
        }
    }

    private var workspaceHeader: some View {
        let panels = vm.panels
        let originScene = vm.selectedPanel.flatMap(vm.originSceneBreakdown)
        return VStack(spacing: 12) {
            HStack(spacing: 14) {
                sidebarToggle
                StepIndicator(current: .storyboard, onTap: goToStep)
                Spacer()
                helperToggle
                overallCompletionBadge(value: panels.completion)
            }
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: project.bible.posterColors.isEmpty
                                ? [Theme.violet, Theme.magenta]
                                : project.bible.posterColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 38)
                VStack(alignment: .leading, spacing: 4) {
                    breadcrumb
                    HStack(spacing: 8) {
                        if let origin = originScene {
                            originPill(origin)
                        }
                        Text("\(panels.count) panels · \(panels.runtimeLabel) runtime · ASL \(String(format: "%.1fs", panels.averageShotLength))")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var breadcrumb: some View {
        HStack(spacing: 6) {
            Button(action: { navigator.go(to: .home) }) {
                Text(project.bible.projectTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            Text("Storyboard")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
        }
    }

    private func originPill(_ scene: SceneBreakdown) -> some View {
        Button(action: { navigator.openStoryForge(sceneBreakdownID: scene.id) }) {
            HStack(spacing: 5) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text("From Story Forge · Scene \(scene.number) \(scene.title)")
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(Theme.magenta)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.magenta.opacity(0.12))
            .overlay(Capsule().stroke(Theme.magenta.opacity(0.35), lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Open this scene in Story Forge")
    }

    private func overallCompletionBadge(value: Double) -> some View {
        HStack(spacing: 8) {
            CompletionRing(value: value, size: 28, color: Theme.violet, showLabel: true)
            VStack(alignment: .leading, spacing: 1) {
                Text("COMPLETION")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
                Text("\(Int(value * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.card)
        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        .clipShape(Capsule())
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
