import SwiftUI

// MARK: - Storyboard Helper Panel
//
// Right-side panel — context swaps based on active tab and focused field,
// matching the StoryForgeHelperPanel pattern.

struct StoryboardHelperPanel: View {
    @ObservedObject var vm: StoryboardComposerViewModel

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
            Image(systemName: "film.stack.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.violet)
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
        switch vm.activeTab {
        case .panels:  return "Storyboard Helper"
        case .rhythm:  return "Rhythm Helper"
        case .library: return "Shot Library Notes"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.activeTab {
        case .panels:  panelsHelper
        case .rhythm:  rhythmHelper
        case .library: libraryHelper
        }
    }

    // MARK: Panels tab

    @ViewBuilder
    private var panelsHelper: some View {
        if let field = vm.focusedField {
            WhyItMattersTip(
                title: fieldTipTitle(field),
                message: fieldTipBody(field),
                tint: Theme.violet
            )
            examplesCard(title: "Try", items: fieldExamples(field), tint: Theme.violet)
        } else if let panel = vm.selectedPanel {
            panelSummary(panels: vm.panels, panel: panel)
            ForEach(murchTips) { tip in
                tipCard(tip: tip)
            }
        } else if vm.panels.isEmpty {
            emptyHelper(icon: "square.grid.3x2",
                        text: "Add your first panel — a wide to set geography, then close in.")
            ForEach(murchTips) { tip in
                tipCard(tip: tip)
            }
        } else {
            emptyHelper(icon: "rectangle.3.group",
                        text: "Select a panel to see sequence stats and Murch tips.")
        }
    }

    private func panelSummary(panels: [StoryboardPanel], panel: StoryboardPanel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SEQUENCE STATS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            statRow(icon: "square.grid.3x2.fill", tint: Theme.violet, label: "Panels", value: "\(panels.count)")
            statRow(icon: "clock.fill", tint: Theme.teal, label: "Runtime", value: panels.runtimeLabel)
            statRow(icon: "waveform.path", tint: Theme.accent, label: "Avg Shot", value: String(format: "%.1fs", panels.averageShotLength))
            statRow(icon: "checkmark.seal.fill", tint: Theme.magenta, label: "Promoted", value: "\(panels.promotedCount)/\(panels.count)")
            Divider().background(Theme.stroke).padding(.vertical, 4)
            Text("SELECTED PANEL")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            HStack(spacing: 8) {
                Text("\(panel.number)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Theme.violet)
                    .clipShape(Circle())
                Text("\(panel.shotType.shortLabel) · \(panel.cameraMovement.shortLabel)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(panel.durationLabel)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textTertiary)
            }
            HStack(spacing: 6) {
                Image(systemName: panel.editingPriority.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(panel.editingPriority.tint)
                Text("Cut on \(panel.editingPriority.rawValue.lowercased())")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func fieldTipTitle(_ field: PanelField) -> String {
        switch field {
        case .action:     return "Why the Action Note matters"
        case .dialogue:   return "Dialogue in the frame"
        case .duration:   return "Why Duration matters"
        case .shotType:   return "Choosing a Shot Type"
        case .movement:   return "Choosing a Camera Movement"
        case .priority:   return "Murch's Rule of Six"
        case .characters: return "Characters in the frame"
        }
    }

    private func fieldTipBody(_ field: PanelField) -> String {
        switch field {
        case .action:
            return "Describe what changes in this frame as a verb. Storyboards aren't screenplays — one sentence, one action. If you can't name the action, the panel probably doesn't earn its cut."
        case .dialogue:
            return "Only include dialogue if the audience needs to hear it over this specific beat. If the line belongs to the next panel, move it."
        case .duration:
            return "Shot length is a dial. Under 1.5s: action or panic. 2-3s: modern drama. 4s+: the audience has time to notice. Cut sooner than feels comfortable, then sooner again."
        case .shotType:
            return "Each shot withholds or reveals. Start wide to orient, close in to feel, then pull out to release. Breaking this rhythm is how you earn surprise."
        case .movement:
            return "A locked frame is a choice. Movement should either follow a subject, reveal geography, or push emotion. If it does none of those, lock it."
        case .priority:
            return "Walter Murch: cut first on emotion — how the audience should feel. Story is second. Rhythm is third. Cut for emotion and the rest usually forgives itself."
        case .characters:
            return "Naming who's in the frame — even in a storyboard — forces you to think about eyelines, blocking, and what the panel is about."
        }
    }

    private func fieldExamples(_ field: PanelField) -> [String] {
        switch field {
        case .action:
            return ["Elena steps into frame; her hand finds the cold slab.",
                    "Wren's fingers close around the lantern. Flame steadies.",
                    "Marcus doesn't look up when she enters."]
        case .dialogue:
            return ["(off-screen) You shouldn't be here.",
                    "— no dialogue. Breath only.",
                    "V.O. \"I was told to ask for Wren.\""]
        case .duration:
            return ["1.2s — staccato reaction beat.",
                    "2.5s — modern conversation rhythm.",
                    "4.5s — sustained wide. Let it breathe."]
        case .shotType:
            return ["Wide → CU → OTS pattern for coverage.",
                    "ECU at the emotional apex only.",
                    "Dutch for a single beat of instability."]
        case .movement:
            return ["Dolly-in on rising tension.",
                    "Handheld to put breath in the frame.",
                    "Locked wide for a reveal."]
        case .priority:
            return ["Emotion — cut when the feeling peaks.",
                    "Story — cut when new information lands.",
                    "Rhythm — cut to match the scene's breath."]
        case .characters:
            return ["One character — isolation.",
                    "Two characters in OTS — relationship.",
                    "Three+ — ensemble blocking."]
        }
    }

    // MARK: Rhythm tab

    @ViewBuilder
    private var rhythmHelper: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PACING LEGEND")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            bulletLine("Valleys in the curve = short shots (urgency, panic).")
            bulletLine("Peaks = sustained shots (dread, awe, contemplation).")
            bulletLine("Long flat stretches = one pace throughout. Often a problem.")
            bulletLine("The selected panel is highlighted on the curve — scrub through the sequence to feel its shape.")
        }
        .padding(14)
        .cardStyle()

        VStack(alignment: .leading, spacing: 8) {
            Text("ASL BENCHMARKS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.accent)
            benchmarkLine(era: "Classical Hollywood (1930-60s)", asl: "8-11s", example: "Casablanca")
            benchmarkLine(era: "New Hollywood (1970s)", asl: "5-7s", example: "The Godfather")
            benchmarkLine(era: "Modern drama", asl: "3-5s", example: "The Social Network")
            benchmarkLine(era: "Modern action", asl: "1.5-2.5s", example: "The Bourne Ultimatum")
        }
        .padding(14)
        .cardStyle()

        WhyItMattersTip(
            title: "Distribution Tip",
            message: "If your distribution is 80% medium shots, the sequence is conversational. If it's 60% close-ups, it's emotional. If it's even across wide/medium/close, it's probably too safe — pick a lean.",
            tint: Theme.teal
        )
    }

    private func benchmarkLine(era: String, asl: String, example: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(asl)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent)
                .frame(width: 58, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(era)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(example)
                    .font(.system(size: 10, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    // MARK: Library tab

    @ViewBuilder
    private var libraryHelper: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SHOT HIERARCHY")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.violet)
            Text("From widest to tightest:")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            ForEach(["WS → Geography", "FS → Body language", "MS → Conversation", "CU → Emotion", "ECU → The only thing that matters"], id: \.self) { line in
                bulletLine(line)
            }
        }
        .padding(14)
        .cardStyle()

        VStack(alignment: .leading, spacing: 8) {
            Text("ANGLE MODIFIERS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.teal)
            bulletLine("Low angle confers power, height, grandeur.")
            bulletLine("High angle diminishes, isolates, observes.")
            bulletLine("Dutch angle destabilizes — use once, maybe twice.")
            bulletLine("POV makes the audience the character. Intimate or menacing depending on what's shown.")
        }
        .padding(14)
        .cardStyle()

        WhyItMattersTip(
            title: "Coverage Rule of Thumb",
            message: "Master → OTS → CU is the workhorse trinity. Four panels covering a conversation can carry it. Add a cutaway only when the camera has run out of things to reveal on faces.",
            tint: Theme.violet
        )
    }

    // MARK: Shared

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
                .foregroundStyle(Theme.violet)
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
                .foregroundStyle(Theme.violet.opacity(0.6))
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private var murchTips: [FilmTip] {
        [
            FilmTip(title: "Murch's Rule of Six", body: "Emotion · Story · Rhythm · Eye-trace · Two-dimensional plane · Three-dimensional space — in that order of importance."),
            FilmTip(title: "On Duration", body: "If you're holding a shot past its emotional peak, the audience notices the edit before you do.")
        ]
    }
}
