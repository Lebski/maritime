import SwiftUI

struct HomeView: View {
    let onNavigate: (AppModule) -> Void
    @State private var query: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                topBar
                heroSection
                quickStats
                modulesSection
                HStack(alignment: .top, spacing: 20) {
                    projectsSection
                    sideColumn
                }
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back, Alex")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                Text("Your Studio")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
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
            TextField("Search projects, characters, scenes…", text: $query)
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
        HeroCard(onStart: { onNavigate(.storyForge) }, onContinue: { onNavigate(.sceneBuilder) })
    }

    // MARK: - Stats

    private var quickStats: some View {
        HStack(spacing: 16) {
            StatCard(title: "Active Projects", value: "4", delta: "+1 this week", icon: "film.fill", tint: Theme.accent)
            StatCard(title: "Characters", value: "16", delta: "3 finalized", icon: "person.crop.artframe", tint: Theme.teal)
            StatCard(title: "Rendered Shots", value: "82", delta: "+12 today", icon: "sparkles", tint: Theme.magenta)
            StatCard(title: "Runtime", value: "71m", delta: "across all films", icon: "clock.fill", tint: Theme.violet)
        }
    }

    // MARK: - Modules

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Production Pipeline", subtitle: "Six modules. One cinematic workflow.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                ForEach([AppModule.storyForge, .characterLab, .setDesign, .storyboard, .sceneBuilder, .videoRenderer], id: \.self) { m in
                    ModuleTile(module: m, isFeatured: m == .setDesign || m == .sceneBuilder) {
                        onNavigate(m)
                    }
                }
            }
        }
    }

    // MARK: - Projects

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Recent Projects", subtitle: "Pick up where you left off")
                Spacer()
                Button("View all") {}
                    .buttonStyle(.plainSolid)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            VStack(spacing: 12) {
                ForEach(SampleData.projects) { project in
                    ProjectRow(project: project)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Side column

    private var sideColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            ActivityCard(items: SampleData.activity)
            TipsCard(tips: SampleData.tips)
        }
        .frame(width: 340)
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
