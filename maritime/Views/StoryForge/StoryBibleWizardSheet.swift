import SwiftUI

enum StoryBibleWizardMode: Identifiable, Equatable {
    case initialEmpty
    case regenerateFromPitch

    var id: String {
        switch self {
        case .initialEmpty:        return "initial"
        case .regenerateFromPitch: return "regenerate"
        }
    }
}

/// 3-step modal that takes a free-form pitch and produces a complete Story Bible
/// (project meta, characters, structure, scenes, theme) via a single Claude call.
struct StoryBibleWizardSheet: View {
    let mode: StoryBibleWizardMode
    @ObservedObject var vm: StoryForgeViewModel
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private static let pitchMinLength = 40

    enum Step: Hashable { case pitch, generating, review }

    @State private var step: Step = .pitch

    @State private var pitch: String = ""
    @State private var titleHint: String = ""
    @State private var genre: String = ""
    @State private var tone: String = ""
    @State private var preferredTemplate: StoryStructureTemplate?
    @State private var useOpus: Bool = false

    @State private var errorText: String?
    @State private var generationTask: Task<Void, Never>?

    // Review-step editable copies
    @State private var editedTitle: String = ""
    @State private var editedLogline: String = ""
    @State private var editedCharacters: [StoryCharacterDraft] = []
    @State private var editedStructure: StoryStructureDraft = StoryStructureDraft(template: .threeAct)
    @State private var editedScenes: [SceneBreakdown] = []
    @State private var editedTheme: ThemeTracker = ThemeTracker()

    @State private var showOverview = true
    @State private var showCharacters = true
    @State private var showStructure = false
    @State private var showScenes = false
    @State private var showTheme = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle(title)
            .toolbar { toolbar }
        }
        .frame(minWidth: 720, minHeight: 620)
        .onAppear { preload() }
        .onDisappear { generationTask?.cancel() }
    }

    private var title: String {
        switch mode {
        case .initialEmpty:        return "Start your Story Bible"
        case .regenerateFromPitch: return "Regenerate from Description"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .pitch:      pitchStep
        case .generating: generatingStep
        case .review:     reviewStep
        }
    }

    // MARK: - Pitch step

    private var pitchStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if mode == .regenerateFromPitch {
                    regenWarningBanner
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your story.")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Two or three sentences is plenty. Specifics help — names, places, the central want, what's at stake.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(3)
                }

                StyledTextField(
                    placeholder: "e.g. A memory-detective in a rain-drenched city investigates her partner's erasure and stumbles into a personal file she doesn't remember writing…",
                    text: $pitch,
                    isMultiLine: true
                )
                .frame(minHeight: 140)

                pitchCounter

                optionalDetails

                templatePicker

                modelToggle

                if let err = errorText {
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.coral)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var pitchCounter: some View {
        let count = pitch.trimmingCharacters(in: .whitespacesAndNewlines).count
        let ok = count >= Self.pitchMinLength
        return HStack {
            Text("\(count) / \(Self.pitchMinLength) characters minimum")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(ok ? Theme.lime : Theme.textTertiary)
            Spacer()
        }
    }

    private var regenWarningBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Applying will replace your current bible.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("To revise scenes only after a structure change, use the diff sheet that appears when you switch templates.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.accent.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var optionalDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OPTIONAL HINTS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            HStack(spacing: 10) {
                StyledTextField(placeholder: "Working title", text: $titleHint)
                StyledTextField(placeholder: "Genre (noir, folk-horror…)", text: $genre)
                StyledTextField(placeholder: "Tone (wry, lyrical…)", text: $tone)
            }
        }
    }

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PREFERRED STRUCTURE")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                templateTile(nil, label: "Let Claude decide")
                ForEach(StoryStructureTemplate.allCases) { t in
                    templateTile(t, label: t.rawValue)
                }
            }
        }
    }

    private func templateTile(_ t: StoryStructureTemplate?, label: String) -> some View {
        let isActive = preferredTemplate == t
        return Button(action: { preferredTemplate = t }) {
            HStack(spacing: 8) {
                Image(systemName: isActive ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isActive ? Theme.magenta : Theme.textTertiary)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(10)
            .background(isActive ? Theme.magenta.opacity(0.10) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isActive ? Theme.magenta.opacity(0.55) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var modelToggle: some View {
        HStack(spacing: 10) {
            Toggle(isOn: $useOpus) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use Opus 4.7 for higher quality")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Slower and more expensive. Defaults to your Preferences setting (\(settings.currentModel.displayName)) when off.")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .toggleStyle(.switch)
            .tint(Theme.magenta)
            Spacer()
        }
        .padding(12)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Generating step

    private var generatingStep: some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView().scaleEffect(1.4)
            Text("Claude is drafting your bible…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Text("Characters, structure, scenes, and theme — one pass.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
            if let err = errorText {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.coral)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Review step

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                    Text("Draft ready. Edit what you want before applying.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }

                accordion(title: "Overview", isOpen: $showOverview, count: nil) { overviewSection }
                accordion(title: "Characters", isOpen: $showCharacters, count: editedCharacters.count) { charactersSection }
                accordion(title: "Structure — \(editedStructure.template.rawValue)", isOpen: $showStructure, count: editedStructure.beats.count) { structureSection }
                accordion(title: "Scenes", isOpen: $showScenes, count: editedScenes.count) { scenesSection }
                accordion(title: "Theme & Motifs", isOpen: $showTheme, count: editedTheme.motifs.count) { themeSection }

                if let err = errorText {
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.coral)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func accordion<Body: View>(title: String,
                                       isOpen: Binding<Bool>,
                                       count: Int?,
                                       @ViewBuilder body: () -> Body) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { isOpen.wrappedValue.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isOpen.wrappedValue ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if let n = count {
                        Text("\(n)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plainSolid)

            if isOpen.wrappedValue {
                Divider().background(Theme.stroke)
                VStack(alignment: .leading, spacing: 12) {
                    body()
                }
                .padding(14)
            }
        }
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            labeled("Project title") {
                StyledTextField(placeholder: "Title", text: $editedTitle)
            }
            labeled("Logline") {
                StyledTextField(placeholder: "One sentence — protagonist, want, conflict.", text: $editedLogline, isMultiLine: true)
            }
        }
    }

    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(editedCharacters.indices, id: \.self) { i in
                characterCard(i)
            }
        }
    }

    private func characterCard(_ i: Int) -> some View {
        let binding = Binding<StoryCharacterDraft>(
            get: { editedCharacters[i] },
            set: { editedCharacters[i] = $0 }
        )
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                StyledTextField(placeholder: "Name", text: binding.name)
                StyledTextField(placeholder: "Role", text: binding.role)
            }
            labeled("Backstory") {
                StyledTextField(placeholder: "One or two concrete sentences.", text: binding.backstory, isMultiLine: true)
            }
            labeled("Want") {
                StyledTextField(placeholder: "Want", text: binding.want, isMultiLine: true)
            }
            labeled("Need") {
                StyledTextField(placeholder: "Need", text: binding.need, isMultiLine: true)
            }
            labeled("Ghost") {
                StyledTextField(placeholder: "Ghost", text: binding.ghost, isMultiLine: true)
            }
            labeled("Flaw") {
                StyledTextField(placeholder: "Flaw", text: binding.flaw, isMultiLine: true)
            }
            labeled("Stakes") {
                StyledTextField(placeholder: "Stakes", text: binding.stakes, isMultiLine: true)
            }
            labeled("Voice") {
                StyledTextField(placeholder: "Voice — a behavioral tic, not an adjective.", text: binding.voice, isMultiLine: true)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var structureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beats are pre-filled with Claude's annotations. You can edit them in the Structure tab after applying.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .lineSpacing(2)
            ForEach(editedStructure.beats) { beat in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(beat.actLabel.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(beat.actTint)
                        Text(beat.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    if !beat.userNotes.isEmpty {
                        Text(beat.userNotes)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.stroke.opacity(0.6), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var scenesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(editedScenes.indices, id: \.self) { i in
                sceneCard(i)
            }
        }
    }

    private func sceneCard(_ i: Int) -> some View {
        let binding = Binding<SceneBreakdown>(
            get: { editedScenes[i] },
            set: { editedScenes[i] = $0 }
        )
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("#\(editedScenes[i].number)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textTertiary)
                StyledTextField(placeholder: "Title", text: binding.title)
            }
            HStack(spacing: 8) {
                StyledTextField(placeholder: "Location", text: binding.location)
                Toggle("Interior", isOn: binding.isInterior)
                    .toggleStyle(.switch)
                    .tint(Theme.magenta)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            labeled("Goal") {
                StyledTextField(placeholder: "What the protagonist is trying to do.", text: binding.sceneGoal, isMultiLine: true)
            }
            labeled("Conflict") {
                StyledTextField(placeholder: "What stands in the way.", text: binding.conflict, isMultiLine: true)
            }
            labeled("Emotional beat") {
                StyledTextField(placeholder: "The feeling at the apex.", text: binding.emotionalBeat, isMultiLine: true)
            }
            labeled("Visual metaphor") {
                StyledTextField(placeholder: "Reference a motif or echo the theme statement.", text: binding.visualMetaphor, isMultiLine: true)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            labeled("Theme statement") {
                StyledTextField(placeholder: "One sentence, no hedging.", text: $editedTheme.themeStatement, isMultiLine: true)
            }
            if !editedTheme.motifs.isEmpty {
                Text("MOTIFS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(editedTheme.motifs) { motif in
                        HStack(spacing: 8) {
                            Image(systemName: motif.symbol)
                                .foregroundStyle(motif.tint)
                            Text(motif.label)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(motif.tint.opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            if !editedTheme.palette.isEmpty {
                Text("PALETTE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
                HStack(spacing: 8) {
                    ForEach(editedTheme.palette) { swatch in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(swatch.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Theme.stroke, lineWidth: 1)
                                )
                            Text(swatch.role)
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.textTertiary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    private func labeled<Body: View>(_ label: String, @ViewBuilder content: () -> Body) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            content()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                generationTask?.cancel()
                dismiss()
            }
            .foregroundStyle(Theme.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            primaryButton
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch step {
        case .pitch:
            Button(action: startGeneration) {
                Label(settings.isConfigured ? "Generate" : "Add API key first", systemImage: "sparkles")
            }
            .foregroundStyle(canGenerate ? Theme.magenta : Theme.textTertiary)
            .disabled(!canGenerate)
        case .generating:
            Button("Cancel") {
                generationTask?.cancel()
                step = .pitch
            }
            .foregroundStyle(Theme.textSecondary)
        case .review:
            Button("Apply Bible") { apply() }
                .foregroundStyle(Theme.magenta)
        }
    }

    private var canGenerate: Bool {
        guard settings.isConfigured else { return false }
        return pitch.trimmingCharacters(in: .whitespacesAndNewlines).count >= Self.pitchMinLength
    }

    // MARK: - Preload

    private func preload() {
        let bible = vm.bible
        if !bible.pitch.isEmpty {
            pitch = bible.pitch
        }
        if !bible.projectTitle.isEmpty, mode == .regenerateFromPitch {
            titleHint = bible.projectTitle
        }
    }

    // MARK: - Generation

    private func startGeneration() {
        guard canGenerate else { return }
        errorText = nil
        step = .generating

        let modelID = useOpus ? "claude-opus-4-7" : settings.modelID
        let client = AnthropicClient(apiKey: settings.apiKey, model: modelID)
        let service = StoryBibleGenerationService(client: client)
        let req = StoryBibleGenerationService.Request(
            pitch: pitch,
            projectTitle: titleHint.isEmpty ? nil : titleHint,
            genre: genre.isEmpty ? nil : genre,
            tone: tone.isEmpty ? nil : tone,
            preferredTemplate: preferredTemplate
        )

        generationTask = Task {
            do {
                let out = try await service.generate(req)
                try Task.checkCancellation()
                await MainActor.run {
                    editedTitle      = out.projectTitle
                    editedLogline    = out.logline
                    editedCharacters = out.characters
                    editedStructure  = out.structure
                    editedScenes     = out.scenes
                    editedTheme      = out.theme
                    step = .review
                }
            } catch is CancellationError {
                // Sheet dismissed or user cancelled — don't write back to state.
            } catch {
                await MainActor.run {
                    errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    step = .pitch
                }
            }
        }
    }

    // MARK: - Apply

    private func apply() {
        // Re-resolve scene character IDs against the (possibly edited) character list,
        // matching by name in case the user renamed someone in the review step.
        let nameToID: [String: UUID] = Dictionary(uniqueKeysWithValues: editedCharacters.map { ($0.name, $0.id) })
        var scenes = editedScenes
        for i in scenes.indices {
            let resolved = scenes[i].characterDraftIDs.compactMap { id -> UUID? in
                if editedCharacters.contains(where: { $0.id == id }) { return id }
                return nil
            }
            scenes[i].characterDraftIDs = resolved.isEmpty ? Array(nameToID.values.prefix(1)) : resolved
        }

        vm.applyGeneratedBible(
            title: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            logline: editedLogline.trimmingCharacters(in: .whitespacesAndNewlines),
            pitch: pitch.trimmingCharacters(in: .whitespacesAndNewlines),
            characters: editedCharacters,
            structure: editedStructure,
            scenes: scenes,
            theme: editedTheme
        )
        dismiss()
    }
}
