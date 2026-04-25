import SwiftUI

// MARK: - Hero

struct HeroCard: View {
    let projectTitle: String
    let nextStepLabel: String
    let nextStepIcon: String
    let onContinue: () -> Void
    let onOpenBible: () -> Void

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
                    Text("Current Project")
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

                Text(projectTitle)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .lineLimit(2)

                Text("Story Forge • Storyboard • Character Lab • Scene Builder • Renderer")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 10) {
                    Button(action: onContinue) {
                        Label(nextStepLabel, systemImage: nextStepIcon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plainSolid)

                    Button(action: onOpenBible) {
                        Label("Open Story Bible", systemImage: "text.book.closed.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.18))
                            .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plainSolid)
                }
            }
            Spacer()
        }
        .padding(28)
    }
}

// MARK: - Status pill

struct StatusPill: View {
    let status: ProjectStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(status.tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(status.tint.opacity(0.15))
            .overlay(Capsule().stroke(status.tint.opacity(0.35), lineWidth: 1))
            .clipShape(Capsule())
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
        .buttonStyle(.plainSolid)
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

// MARK: - Strips (Characters / Sets / Scenes)

struct StripHeader: View {
    let title: String
    let count: Int
    let viewAll: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            Spacer()
            Button("View all", action: viewAll)
                .buttonStyle(.plainSolid)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
        }
    }
}

private struct StripEmptyState: View {
    let icon: String
    let message: String
    let cta: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(message)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(cta)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accent)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plainSolid)
    }
}

struct CharacterStrip: View {
    let characters: [LabCharacter]
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StripHeader(title: "Characters", count: characters.count, viewAll: onViewAll)
            if characters.isEmpty {
                StripEmptyState(
                    icon: "person.crop.artframe",
                    message: "No characters yet",
                    cta: "Open Character Lab →",
                    action: onViewAll
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(characters) { character in
                            CharacterChip(character: character, onOpen: onViewAll)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct CharacterChip: View {
    let character: LabCharacter
    let onOpen: () -> Void

    private static let palette: [Color] = [Theme.teal, Theme.magenta, Theme.violet, Theme.coral, Theme.lime, Theme.accent]

    private var tint: Color {
        let idx = abs(character.id.hashValue) % Self.palette.count
        return Self.palette[idx]
    }

    private var initial: String {
        String(character.name.first ?? "?").uppercased()
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    LinearGradient(
                        colors: [tint.opacity(0.85), tint.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Text(initial)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    if character.isFinalized {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(width: 124, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(character.name.isEmpty ? "Untitled" : character.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(character.isFinalized ? "Finalized" : "Round \(character.currentRound.rawValue)")
                        .font(.system(size: 10))
                        .foregroundStyle(character.isFinalized ? Theme.lime : Theme.textTertiary)
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(8)
            .cardStyle()
        }
        .buttonStyle(.plainSolid)
    }
}

struct SetPieceStrip: View {
    let setPieces: [SetPiece]
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StripHeader(title: "Sets", count: setPieces.count, viewAll: onViewAll)
            if setPieces.isEmpty {
                StripEmptyState(
                    icon: "cube.transparent.fill",
                    message: "No set pieces yet",
                    cta: "Open Set Design →",
                    action: onViewAll
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(setPieces) { piece in
                            SetPieceChip(piece: piece, onOpen: onViewAll)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct SetPieceChip: View {
    let piece: SetPiece
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 10) {
                thumbnail
                    .frame(width: 164, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(piece.name.isEmpty ? "Untitled" : piece.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: piece.category.icon)
                            .font(.system(size: 9, weight: .bold))
                        Text(piece.category.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(piece.category.tint)
                }
            }
            .frame(width: 180, alignment: .leading)
            .padding(8)
            .cardStyle()
        }
        .buttonStyle(.plainSolid)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = piece.generatedImageData ?? piece.referenceImageData,
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: piece.primaryColors.isEmpty ? [piece.category.tint.opacity(0.55), piece.category.tint.opacity(0.25)] : piece.primaryColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: piece.category.icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}

struct SceneStrip: View {
    let scenes: [FilmScene]
    let onViewAll: () -> Void
    let onOpenScene: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StripHeader(title: "Scenes", count: scenes.count, viewAll: onViewAll)
            if scenes.isEmpty {
                StripEmptyState(
                    icon: "photo.stack.fill",
                    message: "No scenes yet",
                    cta: "Open Scene Builder →",
                    action: onViewAll
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(scenes) { scene in
                            SceneChip(scene: scene, onOpen: { onOpenScene(scene.id) })
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct SceneChip: View {
    let scene: FilmScene
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    LinearGradient(
                        colors: [scene.timeOfDay.tint.opacity(0.65), Theme.card],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 184, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    HStack(spacing: 6) {
                        Image(systemName: scene.timeOfDay.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(scene.timeOfDay.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                    .padding(8)

                    VStack {
                        Spacer()
                        HStack {
                            Text("Scene \(scene.number)")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            if scene.frameApproved {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.lime)
                            }
                        }
                        .padding(10)
                    }
                }
                .frame(width: 184, height: 90)

                VStack(alignment: .leading, spacing: 3) {
                    Text(scene.title.isEmpty ? "Untitled scene" : scene.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text("\(scene.isInterior ? "INT." : "EXT.") \(scene.location)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 200, alignment: .leading)
            .padding(8)
            .cardStyle()
        }
        .buttonStyle(.plainSolid)
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
                .buttonStyle(.plainSolid)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
