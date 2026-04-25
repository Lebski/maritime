import SwiftUI

private enum LauncherPhase { case loading, welcome }

struct LauncherView: View {
    @EnvironmentObject var appDelegate: AppDelegate

    @State private var phase: LauncherPhase = .loading

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch phase {
            case .loading:
                LoadingVideoView(onFinished: advance)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { advance() }
                    .transition(.opacity)
            case .welcome:
                WelcomeContent()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
    }

    private func advance() {
        guard phase == .loading else { return }
        phase = .welcome
    }
}
