import SwiftUI

struct SetDesignWizardSheet: View {
    @ObservedObject var vm: SetDesignViewModel
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    enum Step: Hashable { case basics, description, generating, review }

    @State private var step: Step = .basics
    @State private var setType: String?
    @State private var interiorExterior: String?
    @State private var era: String?
    @State private var descriptionText: String = ""
    @State private var errorText: String?
    @State private var suggestions: [EditableSuggestion] = []
    @State private var generationTask: Task<Void, Never>?

    private let setTypes = ["Movie", "Advertising", "Editorial", "Music Video", "Other"]
    private let inOutOptions = ["Interior", "Exterior", "Both"]
    private let eras = ["Contemporary", "Period", "Future", "Timeless"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Set Design with AI")
            .toolbar { toolbar }
        }
        .frame(minWidth: 620, minHeight: 560)
        .onDisappear { generationTask?.cancel() }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .basics:     basicsStep
        case .description: descriptionStep
        case .generating: generatingStep
        case .review:     reviewStep
        }
    }

    // MARK: Basics step

    private var basicsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                progressDots(current: 0, total: 3)
                Text("What kind of set is this?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("All optional. These nudge Claude in a direction without locking anything in.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                chipRow(title: "Set type", options: setTypes, selection: $setType)
                chipRow(title: "Interior / exterior", options: inOutOptions, selection: $interiorExterior)
                chipRow(title: "Era", options: eras, selection: $era)
                Spacer(minLength: 8)
            }
        }
    }

    private func chipRow(title: String, options: [String], selection: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    chip(option, selection: selection)
                }
            }
        }
    }

    private func chip(_ value: String, selection: Binding<String?>) -> some View {
        let active = selection.wrappedValue == value
        return Button {
            selection.wrappedValue = active ? nil : value
        } label: {
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(active ? .black : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(active ? Theme.coral : Color.white.opacity(0.05))
                .overlay(
                    Capsule().stroke(active ? Color.clear : Theme.stroke, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plainSolid)
    }

    // MARK: Description step

    private var descriptionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            progressDots(current: 1, total: 3)
            Text("Describe the set.")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("A few sentences are plenty. Specifics — materials, weather, era cues — give Claude something concrete to build from.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
            StyledTextField(
                placeholder: "e.g. A small smoky highland café at dusk, oak panelling, copper kettles, postcards on the walls.",
                text: $descriptionText,
                isMultiLine: true
            )
            HStack(spacing: 10) {
                pullFromStoryForgeMenu
                Spacer()
                Text("\(descriptionText.count) characters · optional")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var pullFromStoryForgeMenu: some View {
        let breakdowns = project.bible.sceneBreakdowns
        if breakdowns.isEmpty {
            Label("Pull from Story Forge", systemImage: "text.book.closed")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
                .help("No scene breakdowns yet. Add some in Story Forge first.")
        } else {
            Menu {
                ForEach(breakdowns) { scene in
                    Button {
                        descriptionText = composeFromBreakdown(scene)
                    } label: {
                        Text("\(scene.number). \(scene.title) — \(scene.location)")
                    }
                }
            } label: {
                Label("Pull from Story Forge", systemImage: "text.book.closed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(Capsule())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private func composeFromBreakdown(_ scene: SceneBreakdown) -> String {
        var parts: [String] = []
        let location = scene.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal = scene.sceneGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        let metaphor = scene.visualMetaphor.trimmingCharacters(in: .whitespacesAndNewlines)
        if !location.isEmpty { parts.append(location) }
        if !goal.isEmpty { parts.append(goal) }
        if !metaphor.isEmpty { parts.append(metaphor) }
        return parts.joined(separator: ". ")
    }

    // MARK: Generating step

    private var generatingStep: some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView().scaleEffect(1.4)
            Text("Claude is sketching set pieces…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            if let err = errorText {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.coral)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Review step

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                    Text("\(suggestions.filter(\.keep).count) of \(suggestions.count) selected. Edit anything before applying.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                ForEach($suggestions) { $suggestion in
                    suggestionCard($suggestion)
                }
                Button {
                    suggestions.append(EditableSuggestion.blank)
                } label: {
                    Label("Add another", systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func suggestionCard(_ suggestion: Binding<EditableSuggestion>) -> some View {
        let s = suggestion.wrappedValue
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    suggestion.wrappedValue.keep.toggle()
                } label: {
                    Image(systemName: s.keep ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(s.keep ? Theme.coral : Theme.textTertiary)
                }
                .buttonStyle(.plainSolid)
                TextField("Name", text: suggestion.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .textFieldStyle(.plain)
                Picker("", selection: suggestion.category) {
                    ForEach(SetPieceCategory.allCases) { cat in
                        Label(cat.title, systemImage: cat.icon).tag(cat)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }
            TextEditor(text: suggestion.description)
                .font(.system(size: 12))
                .foregroundStyle(s.keep ? Theme.textSecondary : Theme.textTertiary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 50)
            if !s.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(s.tags.prefix(5), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.card.opacity(s.keep ? 1.0 : 0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(s.keep ? Theme.stroke : Theme.stroke.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Toolbar

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
        if step == .description {
            ToolbarItem(placement: .navigation) {
                Button("Back") { step = .basics }
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch step {
        case .basics:
            Button("Next") { step = .description }
                .foregroundStyle(Theme.coral)
        case .description:
            Button(action: startGeneration) {
                Label(settings.isConfigured ? "Generate" : "Add API key first", systemImage: "sparkles")
            }
            .foregroundStyle(settings.isConfigured ? Theme.coral : Theme.textTertiary)
            .disabled(!settings.isConfigured)
        case .generating:
            Button("Cancel") {
                generationTask?.cancel()
                step = .description
            }
            .foregroundStyle(Theme.textSecondary)
        case .review:
            Button("Apply") { apply() }
                .foregroundStyle(suggestions.contains(where: \.keep) ? Theme.coral : Theme.textTertiary)
                .disabled(!suggestions.contains(where: \.keep))
        }
    }

    // MARK: Generation

    private func startGeneration() {
        guard settings.isConfigured else { return }
        errorText = nil
        step = .generating
        let client = AnthropicClient(apiKey: settings.apiKey, model: settings.modelID)
        let service = SetPieceSuggestionService(client: client)
        let req = SetPieceSuggestionService.Request(
            description: descriptionText,
            setType: setType,
            interiorExterior: interiorExterior,
            era: era,
            projectTitle: project.bible.projectTitle,
            desiredCount: 6
        )

        generationTask = Task {
            do {
                let out = try await service.suggest(req)
                await MainActor.run {
                    suggestions = out.suggestions.map { EditableSuggestion(suggestion: $0) }
                    if suggestions.isEmpty {
                        errorText = "Claude didn't return any usable set pieces. Try adding more detail."
                        step = .description
                    } else {
                        step = .review
                    }
                }
            } catch {
                await MainActor.run {
                    errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    step = .description
                }
            }
        }
    }

    // MARK: Apply

    private func apply() {
        let kept = suggestions.filter(\.keep)
        guard !kept.isEmpty else { return }
        var firstID: UUID?
        for item in kept {
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { continue }
            let piece = SetPiece(
                name: trimmedName,
                category: item.category,
                description: item.description,
                promptSeed: item.promptSeed,
                tags: item.tags
            )
            project.addSetPiece(piece)
            if firstID == nil { firstID = piece.id }
        }
        if let id = firstID { vm.selectedPieceID = id }
        dismiss()
    }

    // MARK: Progress dots

    private func progressDots(current: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i <= current ? Theme.coral : Color.white.opacity(0.12))
                    .frame(width: 6, height: 6)
            }
            Spacer()
        }
    }
}

// MARK: - Editable suggestion model

struct EditableSuggestion: Identifiable {
    let id: UUID = UUID()
    var keep: Bool = true
    var name: String
    var category: SetPieceCategory
    var description: String
    var promptSeed: String
    var tags: [String]

    init(suggestion: SetPieceSuggestionService.Suggestion) {
        self.name = suggestion.name
        self.category = suggestion.category
        self.description = suggestion.description
        self.promptSeed = suggestion.promptSeed
        self.tags = suggestion.tags
    }

    private init(blank: Void) {
        self.name = ""
        self.category = .prop
        self.description = ""
        self.promptSeed = ""
        self.tags = []
    }

    static var blank: EditableSuggestion { EditableSuggestion(blank: ()) }
}

