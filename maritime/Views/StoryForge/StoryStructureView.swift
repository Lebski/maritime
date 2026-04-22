import SwiftUI

struct StoryStructureView: View {
    @ObservedObject var vm: StoryForgeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                templatePicker
                if let bible = vm.activeBible {
                    arcCard(bible: bible)
                    timelineCard(bible: bible)
                    selectedBeatCard(bible: bible)
                }
            }
            .padding(24)
        }
    }

    // MARK: Template Picker

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoryForgeSectionHeader(
                title: "Structure Template",
                subtitle: "Choose a frame. Switching templates resets your beat notes.",
                tint: Theme.magenta
            )
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 12)],
                spacing: 12
            ) {
                ForEach(StoryStructureTemplate.allCases) { template in
                    TemplateChoiceCard(
                        template: template,
                        isSelected: vm.activeBible?.structure.template == template,
                        action: { chooseTemplate(template) }
                    )
                }
            }
        }
    }

    private func chooseTemplate(_ template: StoryStructureTemplate) {
        // Confirm swap if current has annotations.
        let hasNotes = (vm.activeBible?.structure.beats.contains { !$0.userNotes.isEmpty }) ?? false
        if hasNotes && vm.activeBible?.structure.template != template {
            // For now, switch directly. A confirmation sheet could be added later.
        }
        vm.chooseTemplate(template)
    }

    // MARK: Emotional Arc

    private func arcCard(bible: StoryBible) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Emotional Arc")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("Murch's Rule #1 · Emotion first")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
            EmotionalArcCurve(
                beats: bible.structure.beats,
                highlight: vm.selectedBeatID,
                tint: Theme.magenta
            )
            .frame(height: 110)
            .padding(.top, 6)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: Timeline

    private func timelineCard(bible: StoryBible) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Beat Timeline")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(bible.structure.beats.count) beats · \(Int(bible.structure.completion * 100))% annotated")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }

            GeometryReader { geo in
                let w = geo.size.width
                let beats = bible.structure.beats
                ZStack(alignment: .topLeading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 4)
                        .offset(y: 32)

                    // Pills
                    ForEach(beats) { beat in
                        let x = w * CGFloat(beat.timingPercent)
                        BeatPill(
                            beat: beat,
                            isSelected: vm.selectedBeatID == beat.id,
                            action: { vm.selectBeat(beat.id) }
                        )
                        .fixedSize()
                        .position(x: clamped(x, w: w), y: 18)
                    }

                    // Timing marks 0 / 50 / 100
                    ForEach([0.0, 0.5, 1.0], id: \.self) { pct in
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.textTertiary)
                            .position(x: max(14, min(w - 14, w * CGFloat(pct))), y: 54)
                    }
                }
            }
            .frame(height: 68)
        }
        .padding(16)
        .cardStyle()
    }

    private func clamped(_ x: CGFloat, w: CGFloat) -> CGFloat {
        max(70, min(w - 70, x))
    }

    // MARK: Selected Beat Editor

    @ViewBuilder
    private func selectedBeatCard(bible: StoryBible) -> some View {
        if let beat = vm.selectedBeat {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(beat.actTint)
                        .frame(width: 10, height: 10)
                    Text(beat.actLabel.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(beat.actTint)
                    Text(beat.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("Lands @ \(Int(beat.timingPercent * 100))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                }
                promptBlock(beat: beat)
                filmExampleBlock(beat: beat)
                notesBlock(beatID: beat.id)
            }
            .padding(18)
            .cardStyle()
        } else {
            EmptyView()
        }
    }

    private func promptBlock(beat: StoryBeat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WHAT HAPPENS HERE")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            Text(beat.defaultPrompt)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
    }

    private func filmExampleBlock(beat: StoryBeat) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "film.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.accent)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text("EXAMPLE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.accent)
                Text(beat.filmExample)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func notesBlock(beatID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YOUR NOTES")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.magenta)
            StyledTextField(
                placeholder: "How does this beat land in your story?",
                text: Binding(
                    get: { vm.selectedBeat?.userNotes ?? "" },
                    set: { vm.updateBeatNotes($0) }
                ),
                isMultiLine: true
            )
        }
    }
}
