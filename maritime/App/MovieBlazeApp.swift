import SwiftUI

@main
struct MovieBlazeApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { MovieBlazeProject() }) { file in
            RootView()
                .environmentObject(file.document)
                .frame(minWidth: 1100, minHeight: 720)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
