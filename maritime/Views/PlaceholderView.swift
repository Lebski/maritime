import SwiftUI

struct PlaceholderView: View {
    let module: AppModule

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 24) {
                    emptyState
                    upcoming
                }
                .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.bg)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(module.tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: module.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(module.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(module.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(module.tagline)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button(action: {}) {
                Label("New", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(module.tint)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
        }
        .padding(24)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(module.tint.opacity(0.10))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(module.tint.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: 160, height: 160)
                Image(systemName: module.icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(module.tint)
            }
            .padding(.top, 40)

            Text("Coming Soon")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(emptyMessage)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
                .lineSpacing(3)

            HStack(spacing: 10) {
                Button(action: {}) {
                    Text("Explore examples")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                Button(action: {}) {
                    Text("Start tutorial")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(module.tint)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
            }
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What you'll be able to do")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    featureCard(feature)
                }
            }
        }
    }

    private func featureCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(module.tint)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var emptyMessage: String {
        switch module {
        case .storyForge: return "Craft characters, beats, and themes. Story Forge will guide you through proven structures like Save the Cat and the Hero's Journey."
        case .storyboard: return "Compose shot sequences with a smart shot library, 180° rule checks, and AI-assisted pacing suggestions."
        case .characterLab: return "Iteratively design consistent characters across multiple rounds — then auto-generate turnarounds, expressions, and action poses."
        case .frameBuilder: return "Assemble cinematic keyframes for each shot with composition guides, lighting presets, and round-trip editing."
        case .videoRenderer: return "Turn frames into motion. Murch's Rule of Six powers intelligent cut suggestions for your timeline."
        case .assetLibrary: return "All your characters, props, and backgrounds — tagged, searchable, and reusable across every project."
        case .exports: return "Deliver production-ready packages to Premiere Pro, Photoshop, and raw formats with a single click."
        default: return ""
        }
    }

    private var features: [String] {
        switch module {
        case .storyForge:
            return ["Want vs. Need character builder", "Five structure templates", "Scene breakdown cards", "Theme & motif tracker"]
        case .storyboard:
            return ["10+ shot type library", "Sequence builder", "Rhythm & timing planner", "AI thumbnail sketches"]
        case .characterLab:
            return ["Round 1 — 12 broad variations", "Round 2 — 6 focused refinements", "Round 3 — final polish", "Auto reference sheets"]
        case .frameBuilder:
            return ["Rule of thirds overlay", "Lighting presets", "Depth layers: FG · MG · BG", "Inpaint & Photoshop round-trip"]
        case .videoRenderer:
            return ["Motion intensity controls", "Murch-powered cut engine", "Timeline assembly", "Premiere XML export"]
        case .assetLibrary:
            return ["Tag-based search", "Version history", "Favorites & collections", "Project linking"]
        case .exports:
            return ["Premiere Pro XML", "Photoshop PSD exchange", "Raw footage bundles", "Cut-suggestion CSV"]
        default:
            return []
        }
    }
}
