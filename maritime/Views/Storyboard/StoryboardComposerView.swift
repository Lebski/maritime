import SwiftUI

// MARK: - Storyboard Composer View
//
// 3-column root: sidebar (sequences + progress + promote), workspace
// (header + tabs + current section), helper panel.

struct StoryboardComposerView: View {
    @StateObject private var vm = StoryboardComposerViewModel()
    @ObservedObject private var store = StoryboardStore.shared
    @State private var showHelper = false
    @State private var showInnerSidebar = true

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
            sidebarSequenceList
            Divider().background(Theme.stroke)
            sidebarProgress
            Divider().background(Theme.stroke)
            sidebarActions
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

    private var sidebarSequenceList: some View {
        ScrollView {
            VStack(spacing: 6) {
                HStack {
                    Text("SEQUENCES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                    Text("\(store.sequences.count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, 4)
                .padding(.top, 10)

                ForEach(store.sequences) { seq in
                    sequenceRow(seq)
                }
            }
            .padding(10)
        }
        .frame(maxHeight: .infinity)
    }

    private func sequenceRow(_ seq: StoryboardSequence) -> some View {
        let isActive = store.activeSequenceID == seq.id
        return Button(action: { vm.setActiveSequence(seq.id) }) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: seq.posterColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 22)
                    .overlay(
                        Text("\(seq.panels.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(seq.projectTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(seq.title)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                CompletionRing(value: seq.completion, size: 18, color: Theme.violet)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? Theme.violet.opacity(0.10) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? Theme.violet.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var sidebarProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SECTION PROGRESS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            if let seq = vm.activeSequence {
                progressStat(icon: "square.grid.3x2.fill", label: "Panels", value: "\(seq.panels.count)", tint: Theme.violet)
                progressStat(icon: "clock.fill", label: "Runtime", value: seq.runtimeLabel, tint: Theme.teal)
                progressStat(icon: "waveform.path", label: "Avg Shot", value: String(format: "%.1fs", seq.averageShotLength), tint: Theme.accent)
                progressStat(icon: "checkmark.seal.fill", label: "Promoted", value: "\(seq.promotedCount)/\(seq.panels.count)", tint: Theme.magenta)
            } else {
                Text("No sequence selected")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
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
                    let count = vm.activeSequence?.unpromotedCount ?? 0
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

    @ViewBuilder
    private var workspace: some View {
        if let seq = vm.activeSequence {
            VStack(spacing: 0) {
                workspaceHeader(seq: seq)
                Divider().background(Theme.stroke)
                tabRow
                Divider().background(Theme.stroke)
                tabContent
            }
        } else {
            emptyWorkspace
        }
    }

    private func workspaceHeader(seq: StoryboardSequence) -> some View {
        HStack(spacing: 14) {
            sidebarToggle
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: seq.posterColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(seq.projectTitle.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
                Text(seq.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(seq.panels.count) panels · \(seq.runtimeLabel) runtime · ASL \(String(format: "%.1fs", seq.averageShotLength))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            helperToggle
            overallCompletionBadge(value: seq.completion)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
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
        HStack(spacing: 8) {
            ForEach(StoryboardTab.allCases) { tab in
                storyboardTabButton(tab)
            }
            Spacer()
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

    private var emptyWorkspace: some View {
        VStack(spacing: 18) {
            Image(systemName: "square.grid.3x2")
                .font(.system(size: 42))
                .foregroundStyle(Theme.violet.opacity(0.6))
            Text("No sequence selected")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Pick a sequence from the sidebar, or plan one from a Story Forge scene.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - New Panel Sheet

struct NewStoryboardPanelSheet: View {
    @ObservedObject var vm: StoryboardComposerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedShotType: CameraShotType = .wide

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("SHOT TYPE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(Theme.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                            ForEach(CameraShotType.allCases) { type in
                                shotTypeOption(type)
                            }
                        }
                        Text("Details like action, dialogue, duration, and priority are set after the panel is added.")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(22)
                }
            }
            .navigationTitle("New Panel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Panel") {
                        vm.addPanel(shotType: selectedShotType)
                        dismiss()
                    }
                    .foregroundStyle(Theme.violet)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 420)
    }

    private func shotTypeOption(_ type: CameraShotType) -> some View {
        let selected = selectedShotType == type
        return Button(action: { selectedShotType = type }) {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(selected ? Theme.violet : Theme.textSecondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.shortLabel)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(selected ? Theme.violet : Theme.textTertiary)
                    Text(type.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.violet)
                }
            }
            .padding(12)
            .background(selected ? Theme.violet.opacity(0.10) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? Theme.violet.opacity(0.5) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StoryboardComposerView()
        .frame(width: 1280, height: 800)
}
