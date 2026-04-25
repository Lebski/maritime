import SwiftUI

enum CharacterWizardMode: Identifiable {
    case new
    case refine(draftID: UUID)

    var id: String {
        switch self {
        case .new: return "new"
        case .refine(let id): return "refine-\(id.uuidString)"
        }
    }
}

struct CharacterWizardSheet: View {
    let mode: CharacterWizardMode
    @ObservedObject var vm: StoryForgeViewModel
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    // MARK: Local state

    enum Step: Hashable { case name, role, backstory, generating, review }

    @State private var step: Step = .name
    @State private var name: String = ""
    @State private var role: String = "Protagonist"
    @State private var backstory: String = ""
    @State private var errorText: String?
    @State private var result: [StoryCharacterField: String] = [:]
    @State private var regeneratingField: StoryCharacterField?
    @State private var generationTask: Task<Void, Never>?

    private let roles = ["Protagonist", "Antagonist", "Supporting", "Mentor", "Love Interest", "Comic Relief"]

    // MARK: Derived

    private var refiningDraft: StoryCharacterDraft? {
        if case .refine(let id) = mode {
            return vm.bible.characterDrafts.first(where: { $0.id == id })
        }
        return nil
    }

    private var existingPsychology: [StoryCharacterField: String] {
        guard let draft = refiningDraft else { return [:] }
        var map: [StoryCharacterField: String] = [:]
        for field in StoryCharacterField.psychologyFields {
            let value = draft.value(for: field)
            if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                map[field] = value
            }
        }
        return map
    }

    private var fieldsToFill: Set<StoryCharacterField> {
        let all = Set(StoryCharacterField.psychologyFields)
        return all.subtracting(existingPsychology.keys)
    }

    // MARK: View

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
        .frame(minWidth: 560, minHeight: 520)
        .onAppear { preloadFromDraft() }
        .onDisappear { generationTask?.cancel() }
    }

    private var title: String {
        switch mode {
        case .new: return "New Character with AI"
        case .refine: return "Generate with AI"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .name:      nameStep
        case .role:      roleStep
        case .backstory: backstoryStep
        case .generating: generatingStep
        case .review:    reviewStep
        }
    }

    // MARK: Name

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            progressDots(current: 0, total: 3)
            Text("What's their name?")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Just a working name is fine — you can change it later.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            StyledTextField(placeholder: "e.g. Mara, Nan, Elena", text: $name)
            Spacer()
        }
    }

    // MARK: Role

    private var roleStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            progressDots(current: 1, total: 3)
            Text("What role do they play?")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Roles shape the kinds of beats Claude will lean toward.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(roles, id: \.self) { r in
                    roleTile(r)
                }
            }
            Spacer()
        }
    }

    private func roleTile(_ r: String) -> some View {
        Button(action: { role = r }) {
            HStack(spacing: 10) {
                Image(systemName: role == r ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(role == r ? Theme.magenta : Theme.textTertiary)
                Text(r)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(12)
            .background(role == r ? Theme.magenta.opacity(0.10) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(role == r ? Theme.magenta.opacity(0.55) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    // MARK: Backstory

    private var backstoryStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            progressDots(current: 2, total: 3)
            Text("Tell me something about \(displayName).")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("A sentence or two of backstory. Concrete details give Claude something real to echo — a job, a loss, a decision they regret.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
            StyledTextField(
                placeholder: "e.g. A field medic who lost her brother during a refugee crossing she helped organize.",
                text: $backstory,
                isMultiLine: true
            )
            Text("\(backstory.count) characters · optional, but richer backstory = more specific fields")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
        }
    }

    private var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "your character" : trimmed
    }

    // MARK: Generating

    private var generatingStep: some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView().scaleEffect(1.4)
            Text("Claude is drafting \(displayName)'s psychology…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            if let err = errorText {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.coral)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                    Text("Draft ready. Edit anything before applying.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                ForEach(StoryCharacterField.psychologyFields) { field in
                    if let value = result[field] {
                        reviewCard(field: field, value: value)
                    } else if let locked = existingPsychology[field] {
                        lockedCard(field: field, value: locked)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func reviewCard(field: StoryCharacterField, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: field.icon).foregroundStyle(field.tint)
                Text(field.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(field.tint)
                Spacer()
                Button {
                    regenerate(field: field)
                } label: {
                    HStack(spacing: 4) {
                        if regeneratingField == field {
                            ProgressView().scaleEffect(0.5).frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "arrow.clockwise").font(.system(size: 10))
                        }
                        Text("Regenerate").font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                .disabled(regeneratingField != nil)
            }
            TextEditor(text: Binding(
                get: { result[field] ?? "" },
                set: { result[field] = $0 }
            ))
            .font(.system(size: 13))
            .foregroundStyle(Theme.textPrimary)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 60)
        }
        .padding(14)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func lockedCard(field: StoryCharacterField, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(Theme.textTertiary)
                Text("\(field.label.uppercased()) · KEPT AS-IS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        if step != .name && step != .generating && step != .review {
            ToolbarItem(placement: .navigation) {
                Button("Back") { back() }.foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch step {
        case .name:
            Button("Next") { step = .role }
                .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textTertiary : Theme.magenta)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        case .role:
            Button("Next") { step = .backstory }.foregroundStyle(Theme.magenta)
        case .backstory:
            Button(action: startGeneration) {
                Label(settings.isConfigured ? "Generate" : "Add API key first", systemImage: "sparkles")
            }
            .foregroundStyle(settings.isConfigured ? Theme.magenta : Theme.textTertiary)
            .disabled(!settings.isConfigured)
        case .generating:
            Button("Cancel") {
                generationTask?.cancel()
                step = .backstory
            }
            .foregroundStyle(Theme.textSecondary)
        case .review:
            Button("Apply") { apply() }.foregroundStyle(Theme.magenta)
        }
    }

    // MARK: Navigation

    private func back() {
        switch step {
        case .role: step = .name
        case .backstory: step = .role
        default: break
        }
    }

    // MARK: Generation

    private func startGeneration() {
        guard settings.isConfigured else { return }
        errorText = nil
        step = .generating
        let client = AnthropicClient(apiKey: settings.apiKey, model: settings.modelID)
        let service = CharacterGenerationService(client: client)
        let req = CharacterGenerationService.Request(
            name: name,
            role: role,
            backstory: backstory,
            existing: existingPsychology,
            fieldsToFill: fieldsToFill.isEmpty ? Set(StoryCharacterField.psychologyFields) : fieldsToFill
        )

        generationTask = Task {
            do {
                let out = try await service.generate(req)
                await MainActor.run {
                    result = out.fields
                    step = .review
                }
            } catch {
                await MainActor.run {
                    errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    step = .backstory
                }
            }
        }
    }

    private func regenerate(field: StoryCharacterField) {
        guard settings.isConfigured else { return }
        regeneratingField = field
        let client = AnthropicClient(apiKey: settings.apiKey, model: settings.modelID)
        let service = CharacterGenerationService(client: client)

        // Pass the rest of `result` + `existingPsychology` as context so the regen stays consistent.
        var context = existingPsychology
        for (f, v) in result where f != field {
            context[f] = v
        }
        let req = CharacterGenerationService.Request(
            name: name,
            role: role,
            backstory: backstory,
            existing: context,
            fieldsToFill: [field]
        )
        Task {
            defer { Task { @MainActor in regeneratingField = nil } }
            do {
                let out = try await service.generate(req)
                if let value = out.fields[field] {
                    await MainActor.run { result[field] = value }
                }
            } catch {
                await MainActor.run {
                    errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    // MARK: Apply

    private func apply() {
        switch mode {
        case .new:
            var draft = StoryCharacterDraft(name: name.trimmingCharacters(in: .whitespaces), role: role)
            draft.backstory = backstory
            for (field, value) in result {
                draft.setValue(value, for: field)
            }
            vm.insertDraft(draft)
        case .refine(let id):
            vm.updateDraftFields(id: id, name: name, role: role, backstory: backstory, generated: result)
        }
        dismiss()
    }

    // MARK: Preload

    private func preloadFromDraft() {
        guard let draft = refiningDraft else { return }
        name = draft.name
        role = draft.role
        backstory = draft.backstory
    }

    // MARK: Progress dots

    private func progressDots(current: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i <= current ? Theme.magenta : Color.white.opacity(0.12))
                    .frame(width: 6, height: 6)
            }
            Spacer()
        }
    }
}
