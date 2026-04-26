import SwiftUI

// MARK: - App Navigator
//
// Per-window navigation coordinator. Owns the selected module and the
// cross-module "intents" that let one module open another on a specific
// entity (e.g. Storyboard → Frame Builder with a chosen Frame or panel).
// Modules observe the relevant `pending…ID` and clear it once consumed.

struct ToastContent: Identifiable {
    let id: UUID = UUID()
    var message: String
    var actionLabel: String?
    var action: (() -> Void)?
}

@MainActor
final class AppNavigator: ObservableObject {
    @Published var selection: AppModule = .home

    @Published var pendingFrameID: UUID?
    @Published var pendingPanelID: UUID?
    @Published var pendingSceneBreakdownID: UUID?

    @Published var toast: ToastContent?

    func go(to module: AppModule) {
        selection = module
    }

    func openFrameBuilder(frameID: UUID) {
        pendingFrameID = frameID
        selection = .frameBuilder
    }

    func openFrameBuilder(panelID: UUID) {
        pendingPanelID = panelID
        selection = .frameBuilder
    }

    func openStoryForge(sceneBreakdownID: UUID? = nil) {
        pendingSceneBreakdownID = sceneBreakdownID
        selection = .storyForge
    }

    func openStoryboard(sceneBreakdownID: UUID? = nil) {
        pendingSceneBreakdownID = sceneBreakdownID
        selection = .storyboard
    }

    func consumePendingFrameID() -> UUID? {
        defer { pendingFrameID = nil }
        return pendingFrameID
    }

    func consumePendingPanelID() -> UUID? {
        defer { pendingPanelID = nil }
        return pendingPanelID
    }

    func consumePendingSceneBreakdownID() -> UUID? {
        defer { pendingSceneBreakdownID = nil }
        return pendingSceneBreakdownID
    }

    func showToast(_ content: ToastContent) {
        let id = content.id
        toast = content
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if self.toast?.id == id { self.toast = nil }
        }
    }

    func dismissToast() { toast = nil }
}

// MARK: - RootView

struct RootView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @StateObject private var navigator = AppNavigator()

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: Binding(
                get: { navigator.selection },
                set: { navigator.selection = $0 }
            ))
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            ZStack(alignment: .bottom) {
                detailView
                    .background(Theme.bg.ignoresSafeArea())
                if let toast = navigator.toast {
                    ToastView(toast: toast, onDismiss: { navigator.dismissToast() })
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: navigator.toast?.id)
        }
        .navigationSplitViewStyle(.balanced)
        .background(Theme.bg)
        .tint(Theme.accent)
        .environmentObject(navigator)
    }

    @ViewBuilder
    private var detailView: some View {
        switch navigator.selection {
        case .home:
            HomeView(
                onNavigate: { navigator.go(to: $0) },
                onJumpToFrame: { navigator.openFrameBuilder(frameID: $0) }
            )
        case .storyForge:
            StoryForgeView(project: project)
        case .storyboard:
            StoryboardComposerView(project: project)
        case .characterLab:
            CharacterLabView(project: project)
        case .setDesign:
            SetDesignView(project: project)
        case .frameBuilder:
            FrameBuilderView(project: project)
        case .videoRenderer:
            VideoRendererView(project: project)
        case .assetLibrary:
            AssetLibraryView(project: project)
        case .exports:
            ExportsView(project: project)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(MovieBlazeProject())
        .frame(width: 1200, height: 780)
}
