import SwiftUI

// MARK: - Hero

struct HeroCard: View {
    let onStart: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            Theme.heroGradient
            decoration
            content
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var decoration: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 340, height: 340)
                .blur(radius: 40)
                .offset(x: 380, y: -80)
            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 520, y: 120)
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Label {
                    Text("AI Filmmaking · Studio v1.0")
                        .font(.system(size: 11, weight: .semibold))
                } icon: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())

                Text("From a single idea\nto a finished film.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(2)

                Text("Story Forge • Storyboard • Character Lab • Scene Builder • Renderer")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 10) {
                    Button(action: onStart) {
                        Label("New Project", systemImage: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onContinue) {
                        Label("Continue Editing", systemImage: "play.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.18))
                            .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding(28)
    }
}

// MARK: - Stat card

struct StatCard: View {
    let title: String
    let value: String
    let delta: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Spacer()
                Image(systemName: "chevron.up.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Text(delta)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Module tile

struct ModuleTile: View {
    let module: AppModule
    let isFeatured: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                header
                Text(module.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(module.tagline)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                footer
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFeatured ? module.tint.opacity(0.5) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(module.tint.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: module.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(module.tint)
            }
            Spacer()
            if isFeatured {
                Text("ESSENTIAL")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(module.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(module.tint.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Open module")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(module.tint)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(module.tint)
        }
    }

    @ViewBuilder
    private var background: some View {
        if isFeatured {
            LinearGradient(
                colors: [module.tint.opacity(0.14), Theme.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Theme.card
        }
    }
}

// MARK: - Project row

struct ProjectRow: View {
    let project: MovieProject

    var body: some View {
        HStack(spacing: 16) {
            poster
            info
            Spacer()
            progress
            openButton
        }
        .padding(14)
        .cardStyle()
    }

    private var poster: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: project.posterColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "film.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(10)
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(project.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                statusPill
            }
            Text(project.logline)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: 380, alignment: .leading)
            HStack(spacing: 12) {
                metaItem(icon: "theatermasks.fill", text: project.genre)
                metaItem(icon: "square.stack.3d.up.fill", text: "\(project.scenes) scenes")
                metaItem(icon: "person.2.fill", text: "\(project.characters) chars")
                metaItem(icon: "clock", text: "\(project.durationMinutes)m")
            }
        }
    }

    private var statusPill: some View {
        Text(project.status.rawValue)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(project.status.tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(project.status.tint.opacity(0.15))
            .clipShape(Capsule())
    }

    private func metaItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Theme.textTertiary)
    }

    private var progress: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("\(Int(project.progress * 100))%")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            ProgressView(value: project.progress)
                .progressViewStyle(.linear)
                .tint(project.status.tint)
                .frame(width: 120)
            Text("Updated \(project.updatedLabel)")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var openButton: some View {
        Button(action: {}) {
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity

struct ActivityCard: View {
    let items: [ActivityItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("Today")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            VStack(spacing: 12) {
                ForEach(items) { item in
                    row(item)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func row(_ item: ActivityItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(item.tint.opacity(0.18)).frame(width: 30, height: 30)
                Image(systemName: item.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(item.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(item.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Text(item.time)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}

// MARK: - Tips

struct TipsCard: View {
    let tips: [FilmTip]
    @State private var index: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Director's Notes", systemImage: "book.pages.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            let tip = tips[index % tips.count]
            VStack(alignment: .leading, spacing: 8) {
                Text(tip.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text(tip.body)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 6) {
                ForEach(0..<tips.count, id: \.self) { i in
                    Capsule()
                        .fill(i == index % tips.count ? Theme.accent : Color.white.opacity(0.15))
                        .frame(width: i == index % tips.count ? 18 : 6, height: 6)
                }
                Spacer()
                Button(action: { index += 1 }) {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
