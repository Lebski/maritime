import SwiftUI

struct StoryForgeHelperPanel: View {
    @ObservedObject var vm: StoryForgeViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Theme.stroke)
            ScrollView {
                VStack(spacing: 16) {
                    content
                }
                .padding(18)
            }
        }
        .background(Theme.bgElevated)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.magenta)
            Text(contextTitle.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var contextTitle: String {
        switch vm.activeSection {
        case .characters: return "Character Helper"
        case .structure:  return "Structure Helper"
        case .scenes:     return "Scene Helper"
        case .theme:      return "Theme Helper"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.activeSection {
        case .characters: characterHelper
        case .structure:  structureHelper
        case .scenes:     sceneHelper
        case .theme:      themeHelper
        }
    }

    // MARK: Character Helper

    @ViewBuilder
    private var characterHelper: some View {
        if let field = vm.focusedField {
            WhyItMattersTip(
                title: "Why \(field.label) matters",
                message: field.whyItMatters,
                tint: field.tint
            )
            examplesCard(title: "Examples", items: field.examples, tint: field.tint)
        } else if let draft = vm.activeDraft {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(draft.name) · \(draft.role)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Tap any field to see why it matters and how the classics solved it.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
                completionBreakdown(draft: draft)
            }
            .padding(14)
            .cardStyle()
            ForEach(generalTips) { tip in
                tipCard(tip: tip)
            }
        } else {
            emptyHelper(icon: "person.text.rectangle",
                        text: "Add a character to see guidance here.")
        }
    }

    private func completionBreakdown(draft: StoryCharacterDraft) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FIELD COMPLETION")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            ForEach(StoryCharacterField.allCases) { field in
                HStack(spacing: 8) {
                    Image(systemName: field.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(field.tint)
                        .frame(width: 14)
                    Text(field.label)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Image(systemName: draft.value(for: field).trimmingCharacters(in: .whitespaces).isEmpty ? "circle" : "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(draft.value(for: field).trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textTertiary : Theme.teal)
                }
            }
        }
    }

    // MARK: Structure Helper

    @ViewBuilder
    private var structureHelper: some View {
        if let beat = vm.selectedBeat {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle().fill(beat.actTint).frame(width: 8, height: 8)
                    Text(beat.actLabel.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(beat.actTint)
                    Spacer()
                    Text("\(Int(beat.timingPercent * 100))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                }
                Text(beat.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(beat.defaultPrompt)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
            }
            .padding(14)
            .cardStyle()
            WhyItMattersTip(
                title: "Act context",
                message: actContext(for: beat.actLabel),
                tint: beat.actTint
            )
        } else if let template = vm.activeBible?.structure.template {
            VStack(alignment: .leading, spacing: 10) {
                Text(template.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.magenta)
                Text(template.tagline)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Select a beat on the timeline to see its context and examples.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineSpacing(2)
            }
            .padding(14)
            .cardStyle()
            examplesCard(title: "Films using \(template.rawValue)", items: template.filmExamples, tint: Theme.magenta)
        } else {
            emptyHelper(icon: "chart.bar.xaxis", text: "Choose a template to begin.")
        }
    }

    private func actContext(for actLabel: String) -> String {
        switch actLabel {
        case "Act 1": return "Setup. Establish the ordinary world. Introduce the protagonist's flaw before challenging it."
        case "Act 2": return "Confrontation. The protagonist attempts solutions that don't yet address the real problem."
        case "Act 2A": return "Early confrontation. Promise of the premise — the trailer moments."
        case "Act 2B": return "Later confrontation. Opposition mounts. The flaw becomes a liability."
        case "Act 3": return "Resolution. Apply the lesson learned. Visual echoes of Act 1, now transformed."
        case "Act 4": return "Kishotenketsu coda — synthesis. No winner, only resonance."
        default: return "Each beat should either advance the plot, reveal character, or transform mood."
        }
    }

    // MARK: Scene Helper

    @ViewBuilder
    private var sceneHelper: some View {
        if let field = vm.focusedSceneField {
            WhyItMattersTip(
                title: sceneFieldTitle(field),
                message: sceneFieldTip(field),
                tint: Theme.magenta
            )
            examplesCard(title: "Try prompting with", items: sceneFieldExamples(field), tint: Theme.magenta)
        } else if let bible = vm.activeBible, !bible.sceneBreakdowns.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("SCENE STATS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
                statRow(icon: "rectangle.stack.fill", tint: Theme.magenta, label: "Scenes", value: "\(bible.sceneBreakdowns.count)")
                statRow(icon: "checkmark.seal.fill", tint: Theme.teal, label: "Promoted", value: "\(bible.sceneBreakdowns.filter { $0.isPromoted }.count)")
                statRow(icon: "person.2.fill", tint: Theme.accent, label: "With Characters", value: "\(bible.sceneBreakdowns.filter { !$0.characterDraftIDs.isEmpty }.count)")
            }
            .padding(14)
            .cardStyle()
            ForEach(sceneTips) { tip in
                tipCard(tip: tip)
            }
        } else {
            emptyHelper(icon: "rectangle.stack", text: "Add a scene to see guidance.")
        }
    }

    private func sceneFieldTitle(_ field: StoryForgeViewModel.SceneField) -> String {
        switch field {
        case .goal:            return "Why the Scene Goal matters"
        case .conflict:        return "Why the Conflict matters"
        case .emotionalBeat:   return "Why the Emotional Beat matters"
        case .visualMetaphor:  return "Why the Visual Metaphor matters"
        case .transition:      return "Why the Transition matters"
        }
    }

    private func sceneFieldTip(_ field: StoryForgeViewModel.SceneField) -> String {
        switch field {
        case .goal:            return "Every scene must contribute something irreversible to the story. If nothing changes, cut it or merge it."
        case .conflict:        return "The obstacle can be another character, the environment, or the protagonist themselves. Choose the one that reveals character best."
        case .emotionalBeat:   return "Audiences remember feelings before plot. Name the feeling you're trying to land — shame, relief, awe — and shoot toward it."
        case .visualMetaphor:  return "Optional, but powerful. A recurring image gives the cut its subtext. Don't state the theme — rhyme it."
        case .transition:      return "How the scene ends telegraphs what matters in the next. Match cuts, L-cuts, and hard cuts each carry meaning."
        }
    }

    private func sceneFieldExamples(_ field: StoryForgeViewModel.SceneField) -> [String] {
        switch field {
        case .goal:            return ["Protagonist has to find X.", "Protagonist has to convince Y.", "Protagonist has to survive Z."]
        case .conflict:        return ["Internal — they don't want to.", "Relational — Y won't let them.", "Environmental — the storm arrives."]
        case .emotionalBeat:   return ["Vertigo.", "A cold, perfect horror.", "Relief that tastes like iron."]
        case .visualMetaphor:  return ["Broken clock on the wall.", "Steam rising where rain fell.", "Their shadow reaches the door first."]
        case .transition:      return ["Match cut on a slamming drawer.", "L-cut — breath carries over.", "Dissolve — time compression."]
        }
    }

    // MARK: Theme Helper

    @ViewBuilder
    private var themeHelper: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THEME DOS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.magenta)
            bulletLine("One declarative sentence. No ‘about’ or ‘explores’.")
            bulletLine("The audience shouldn't hear the theme — they should leave with it.")
            bulletLine("Motifs should appear at least three times. Under three reads as coincidence.")
            bulletLine("Color choices should echo emotional arc, not mood of the day.")
        }
        .padding(14)
        .cardStyle()
        if let palette = vm.activeBible?.theme.palette, palette.count >= 2 {
            harmonyHintCard(palette: palette)
        }
    }

    private func harmonyHintCard(palette: [ColorPaletteSwatch]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PALETTE HARMONY")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.accent)
            Text("\(palette.count) swatches defined. Keep the contrast between your protagonist and antagonist swatches the biggest in the whole palette — audiences read contrast as conflict.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: Shared subviews

    private func examplesCard(title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(tint)
            ForEach(items, id: \.self) { line in
                HStack(alignment: .top, spacing: 8) {
                    Text("›")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(tint)
                    Text(line)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func bulletLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(Theme.magenta)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func statRow(icon: String, tint: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(tint)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func tipCard(tip: FilmTip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tip.title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.accent)
            Text(tip.body)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func emptyHelper(icon: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Theme.magenta.opacity(0.6))
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: Tips

    private var generalTips: [FilmTip] {
        [
            FilmTip(title: "Mamet on Want", body: "Every protagonist must want something. Make it clear, make it active, make it visual."),
            FilmTip(title: "Need ≠ Want", body: "The gap between what your character pursues and what they require is the arc.")
        ]
    }

    private var sceneTips: [FilmTip] {
        [
            FilmTip(title: "Murch's Rule #1", body: "Emotion first. Cut on feeling before story, rhythm, or eyeline."),
            FilmTip(title: "Scene Architecture", body: "Open on entry, close on exit. Trim the first sentence and the last sentence of every scene.")
        ]
    }
}
