import SwiftUI
import AppKit

@main
struct MovieBlazeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appSettings = AppSettings()

    init() {
        print("MovieBlaze \(BuildInfo.versionString)")
    }

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
        .commands {
            CommandGroup(after: .saveItem) {
                Button("Save As…") {
                    NSApp.sendAction(#selector(NSDocument.saveAs(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        Settings {
            PreferencesView()
                .environmentObject(appSettings)
                .preferredColorScheme(.dark)
        }
    }
}
