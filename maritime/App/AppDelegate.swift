import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    @Published var hasOpenDocument: Bool = false
    @Published var recentDocumentURLs: [URL] = []

    private var documentsObservation: NSKeyValueObservation?
    private var welcomeWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = NSDocumentController.shared
        hasOpenDocument = !controller.documents.isEmpty
        recentDocumentURLs = controller.recentDocumentURLs

        documentsObservation = controller.observe(\.documents, options: [.new]) { [weak self] controller, _ in
            let isEmpty = controller.documents.isEmpty
            let recents = controller.recentDocumentURLs
            DispatchQueue.main.async {
                guard let self else { return }
                self.hasOpenDocument = !isEmpty
                self.recentDocumentURLs = recents
                if !isEmpty { self.closeWelcomeWindow() }
            }
        }

        if !hasOpenDocument {
            showWelcomeWindow()
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func showWelcomeWindow() {
        if welcomeWindowController != nil { return }

        let root = LauncherView().environmentObject(self)
        let host = NSHostingController(rootView: root)
        host.view.frame = NSRect(x: 0, y: 0, width: 880, height: 560)

        let window = NSWindow(contentViewController: host)
        window.title = "Welcome to maritime"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.setContentSize(NSSize(width: 880, height: 560))
        window.center()
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        welcomeWindowController = controller
    }

    func closeWelcomeWindow() {
        welcomeWindowController?.close()
        welcomeWindowController = nil
    }
}
