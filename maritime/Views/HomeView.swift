import SwiftUI

struct HomeView: View {
    let onNavigate: (AppModule) -> Void
    let onJumpToScene: (UUID) -> Void
    @EnvironmentObject var project: MovieBlazeProject
    @State private var query: String = ""

    private var status: ProjectStatus {
        if !project.cutSuggestions.isEmpty || project.scenes.contains(where: { $0.clipDuration > 0 && $0.frameApproved }) {
            return .finishing
        }
        if project.scenes.contains(where: { $0.frameApproved }) {
            return .shooting
        }
        if !project.storyboardPanels.isEmpty {
            return .storyboard
        }
        return .story
    }

    private var nextStepModule: AppModule {
        switch status {
        case .story:      return .storyForge
        case .storyboard: return .storyboard
        case .shooting:   return .sceneBuilder
        case .finishing:  return .videoRenderer
        }
    }

    private var nextStepLabel: String {
        switch status {
        case .story:      return "Continue in Story Forge"
        case .storyboard: return "Continue in Storyboard"
        case .shooting:   return "Continue in Scene Builder"
        case .finishing:  return "Continue in Renderer"
        }
    }

    private var nextStepIcon: String {
        switch status {
        case .story:      return "text.book.closed.fill"
        case .storyboard: return "square.grid.3x2.fill"
        case .shooting:   return "photo.stack.fill"
        case .finishing:  return "film.stack.fill"
        }
    }

    private var displayTitle: String {
        let raw = project.bible.projectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Untitled Project" : raw
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                topBar
                heroSection
                quickStats
                modulesSection
                CharacterStrip(characters: project.characters,
                               onViewAll: { onNavigate(.characterLab) })
                SetPieceStrip(setPieces: project.setPieces,
                              onViewAll: { onNavigate(.setDesign) })
                SceneStrip(scenes: project.scenes,
                           onViewAll: { onNavigate(.sceneBuilder) },
                           onOpenScene: onJumpToScene)
                TipsCard(tips: SampleData.tips)
                Color.clear.frame(height: 16)
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.bg)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Project")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
                HStack(spacing: 12) {
                    Text(displayTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    StatusPill(status: status)
                }
            }
            Spacer()
            searchField
            iconButton("bell")
            iconButton("gearshape")
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            TextField("Search characters, sets, scenes…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(width: 320)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func iconButton(_ name: String) -> some View {
        Button(action: {}) {
            Image(systemName: name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 36, height: 36)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    // MARK: - Hero

    private var heroSection: some View {
        HeroCard(
            projectTitle: displayTitle,
            nextStepLabel: nextStepLabel,
            nextStepIcon: nextStepIcon,
            onContinue: { onNavigate(nextStepModule) },
            onOpenBible: { onNavigate(.storyForge) }
        )
    }

    // MARK: - Stats

    private var quickStats: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Characters",
                value: "\(project.characters.count)",
                delta: "\(project.characters.filter(\.isFinalized).count) finalized",
                icon: "person.crop.artframe",
                tint: Theme.teal
            )
            StatCard(
                title: "Sets",
                value: "\(project.setPieces.count)",
                delta: "\(project.setPieces.filter(\.hasGeneratedImage).count) generated",
                icon: "cube.transparent.fill",
                tint: Theme.coral
            )
            StatCard(
                title: "Scenes",
                value: "\(project.scenes.count)",
                delta: "\(project.scenes.filter(\.frameApproved).count) approved",
                icon: "photo.stack.fill",
                tint: Theme.accent
            )
            StatCard(
                title: "Shots",
                value: "\(project.storyboardPanels.count)",
                delta: project.storyboardPanels.isEmpty ? "no panels yet" : "\(project.storyboardPanels.count) panels",
                icon: "square.grid.3x2.fill",
                tint: Theme.violet
            )
        }
    }

    // MARK: - Modules

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Production Pipeline", subtitle: "Six modules. One cinematic workflow.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                ForEach([AppModule.storyForge, .characterLab, .setDesign, .storyboard, .sceneBuilder, .videoRenderer], id: \.self) { m in
                    ModuleTile(module: m, isFeatured: m == nextStepModule) {
                        onNavigate(m)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}
