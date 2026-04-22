import SwiftUI

struct RootView: View {
    @State private var selection: AppModule = .home

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            detailView
                .background(Theme.bg.ignoresSafeArea())
        }
        .navigationSplitViewStyle(.balanced)
        .background(Theme.bg)
        .tint(Theme.accent)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .home:
            HomeView(onNavigate: { selection = $0 })
        case .storyForge:
            PlaceholderView(module: .storyForge)
        case .storyboard:
            PlaceholderView(module: .storyboard)
        case .characterLab:
            PlaceholderView(module: .characterLab)
        case .sceneBuilder:
            PlaceholderView(module: .sceneBuilder)
        case .videoRenderer:
            PlaceholderView(module: .videoRenderer)
        case .assetLibrary:
            PlaceholderView(module: .assetLibrary)
        case .exports:
            PlaceholderView(module: .exports)
        }
    }
}

#Preview {
    RootView()
        .frame(width: 1200, height: 780)
}
