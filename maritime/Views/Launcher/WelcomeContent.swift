import AppKit
import SwiftUI

struct WelcomeContent: View {
    @EnvironmentObject var appDelegate: AppDelegate

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                actionsRow
                recentsSection
                Color.clear.frame(height: 8)
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.bg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("maritime")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Pick up where you left off, or start something new.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var actionsRow: some View {
        HStack(spacing: 12) {
            primaryAction(title: "New Project", icon: "plus") {
                NSDocumentController.shared.newDocument(nil)
            }
            secondaryAction(title: "Open…", icon: "folder") {
                NSDocumentController.shared.openDocument(nil)
            }
            Spacer(minLength: 0)
        }
    }

    private func primaryAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
        }
        .buttonStyle(.maritimePrimary)
    }

    private func secondaryAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(Theme.card)
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plainSolid)
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            if appDelegate.recentDocumentURLs.isEmpty {
                emptyState
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    ForEach(appDelegate.recentDocumentURLs, id: \.self) { url in
                        RecentProjectCard(url: url) {
                            open(url)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            Text("No recent projects yet — create one to get started.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func open(_ url: URL) {
        NSDocumentController.shared.openDocument(
            withContentsOf: url,
            display: true
        ) { _, _, _ in }
    }
}
