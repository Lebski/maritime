import SwiftUI

@main
struct MovieBlazeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        DocumentGroup(newDocument: { MovieBlazeProject() }) { file in
            RootView()
                .environmentObject(file.document)
                .environmentObject(appSettings)
                .frame(minWidth: 1100, minHeight: 720)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        Settings {
            PreferencesView()
                .environmentObject(appSettings)
                .preferredColorScheme(.dark)
        }
    }
}
