import SwiftUI

struct NewCharacterSheet: View {
    @ObservedObject var vm: CharacterLabViewModel
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    enum Step: Hashable { case describe, details, count }

    @State private var step: Step = .describe
    @State private var source: CharacterSource = .new
    @State private var name = ""
    @State private var description = ""
    @State private var role = "Protagonist"
    @State private var answers = CharacterSetupAnswers()
    @State private var portraitCount: Int = 10
    @State private var didPrefill = false

    private let roles = ["Protagonist", "Antagonist", "Supporting", "Mentor", "Love Interest", "Comic Relief"]

    private var editingCharacter: LabCharacter? {
        guard let id = vm.editingCharacterID else { return nil }
        return vm.characters.first(where: { $0.id == id })
    }

    private var isEditing: Bool { editingCharacter != nil }

    private var storyDrafts: [StoryCharacterDraft] {
        project.bible.characterDrafts
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canProceedFromDescribe: Bool {
        if isEditing { return !trimmedName.isEmpty }
        return source == .new && !trimmedName.isEmpty
    }

    private var composedPromptPreview: String {
        let request = PortraitGenerationRequest(
            name: trimmedName,
            role: role,
            description: description,
            answers: answers,
            count: portraitCount
        )
        return FalaiPortraitService().composedPrompt(for: request)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle(isEditing ? "Set up character" : "New Character")
            .toolbar { toolbar }
        }
        .frame(minWidth: 560, minHeight: 560)
        .onAppear(perform: prefillIfNeeded)
    }

    private func prefillIfNeeded() {
        guard !didPrefill, let char = editingCharacter else { return }
        didPrefill = true
        source = .new
        name = char.name
        description = char.description
        role = char.role
        answers = char.setupAnswers
        portraitCount = char.portraitCount
    }

    // MARK: Content router

    @ViewBuilder
    private var content: some View {
        switch step {
        case .describe: describeStep
        case .details:  detailsStep
        case .count:    countStep
        }
    }

    // MARK: Step 1 — Describe

    private var describeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                progressDots(current: 0, total: 3)
                if isEditing {
                    describeForm
                } else {
                    sourceSelector
                    if source == .storyForge { storyForgePicker }
                    if source == .new { describeForm }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sourceSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Character Source")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            VStack(spacing: 8) {
                sourceOption(.new, title: "Create New Character", subtitle: "Describe your character — we'll generate portrait variations", icon: "plus.circle.fill")
                sourceOption(.storyForge, title: "From Story Forge", subtitle: "Jump to a character already in this story", icon: "text.book.closed.fill")
                sourceOption(.library, title: "From Character Library", subtitle: "Re-use a finalized character", icon: "tray.full.fill")
            }
        }
    }

    private func sourceOption(_ s: CharacterSource, title: String, subtitle: String, icon: String) -> some View {
        Button(action: { source = s }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(source == s ? Theme.teal : Theme.textTertiary)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                if source == s {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.teal)
                }
            }
            .padding(14)
            .background(source == s ? Theme.teal.opacity(0.10) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(source == s ? Theme.teal.opacity(0.4) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var describeForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            formSection(label: "Name") {
                StyledTextField(placeholder: "e.g. Elena", text: $name)
            }
            formSection(label: "Role") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(roles, id: \.self) { r in
                            Button(action: { role = r }) {
                                Text(r)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(role == r ? .black : Theme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(role == r ? Theme.teal : Color.white.opacity(0.07))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plainSolid)
                        }
                    }
                }
            }
            formSection(label: "Visual Description") {
                StyledTextField(
                    placeholder: "e.g. 30-year-old woman, sharp features, dark curly hair, trench coat…",
                    text: $description,
                    isMultiLine: true
                )
            }
            hintBox
        }
    }

    private var hintBox: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.accent)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tip: Be specific")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text("Include age, build, ethnicity, key costume details, and any distinctive features. The next step lets you fill in optional details if you want extra control.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(Theme.accent.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Story Forge picker (short-circuit)

    private var storyForgePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(project.bible.projectTitle.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            if storyDrafts.isEmpty {
                storyForgeEmptyState
            } else {
                Text("Tap a draft to jump to its Lab character.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                VStack(spacing: 8) {
                    ForEach(storyDrafts) { draft in
                        draftPickerRow(draft)
                    }
                }
            }
        }
    }

    private func draftPickerRow(_ draft: StoryCharacterDraft) -> some View {
        Button(action: { jumpToLab(draft) }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.magenta)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(draft.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(draft.role.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                CompletionRing(value: draft.completion, size: 16, color: Theme.magenta)
                Image(systemName: "arrow.up.right.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.teal)
            }
            .padding(14)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var storyForgeEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 22))
                .foregroundStyle(Theme.magenta.opacity(0.6))
            Text("No character drafts yet")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Create drafts in Story Forge → Character Builder first.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func jumpToLab(_ draft: StoryCharacterDraft) {
        guard let labID = draft.promotedLabCharacterID,
              let lab = project.character(id: labID) else { return }
        vm.setActive(lab)
        dismiss()
    }

    // MARK: Step 2 — Optional details

    private var detailsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                progressDots(current: 1, total: 3)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Optional details")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Skip any field. The more you fill in, the more controlled the result.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button(action: clearDetails) {
                        Text("Skip all")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plainSolid)
                }
                detailField(label: "Age range", placeholder: "e.g. early 30s", text: $answers.ageRange)
                detailField(label: "Height & build", placeholder: "e.g. tall, athletic", text: $answers.heightBuild)
                detailField(label: "Hair color & style", placeholder: "e.g. dark curly, shoulder-length", text: $answers.hairColorStyle)
                detailField(label: "Eye color", placeholder: "e.g. green, deep brown", text: $answers.eyeColor)
                detailField(label: "Skin tone", placeholder: "e.g. olive, deep brown, fair", text: $answers.skinTone)
                detailField(label: "Facial features", placeholder: "e.g. sharp jaw, high cheekbones", text: $answers.facialFeatures)
                detailField(label: "Facial hair", placeholder: "e.g. clean-shaven, stubble, full beard", text: $answers.facialHair)
                detailField(label: "Distinguishing features", placeholder: "e.g. scar above brow, glasses, tattoos", text: $answers.distinguishing)
                detailField(label: "Clothing & style", placeholder: "e.g. trench coat, scuffed boots", text: $answers.clothingStyle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func detailField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            StyledTextField(placeholder: placeholder, text: text)
        }
    }

    private func clearDetails() {
        answers = CharacterSetupAnswers()
    }

    // MARK: Step 3 — Count + preview

    private var countStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                progressDots(current: 2, total: 3)
                Text("How many portraits?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("We'll generate this many variations and you'll pick your favourite. More options take a little longer.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                portraitCountControl
                if !settings.falIsConfigured {
                    missingKeyHint
                }
                composedPromptCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var portraitCountControl: some View {
        HStack(spacing: 16) {
            Button {
                portraitCount = max(1, portraitCount - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(portraitCount <= 1 ? Theme.textTertiary : Theme.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Theme.card)
                    .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plainSolid)
            .disabled(portraitCount <= 1)

            VStack(spacing: 2) {
                Text("\(portraitCount)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Theme.teal)
                Text(portraitCount == 1 ? "portrait" : "portraits")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(minWidth: 80)

            Button {
                portraitCount = min(20, portraitCount + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(portraitCount >= 20 ? Theme.textTertiary : Theme.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Theme.card)
                    .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plainSolid)
            .disabled(portraitCount >= 20)

            Spacer()
        }
        .padding(16)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var composedPromptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                Text("PROMPT PREVIEW")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(composedPromptPreview)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var missingKeyHint: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.coral)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text("Missing fal.ai API key")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.coral)
                Text("Add one in Preferences (⌘,) before generating portraits.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
        .background(Theme.coral.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.coral.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                vm.editingCharacterID = nil
                dismiss()
            }
            .foregroundStyle(Theme.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            primaryButton
        }
        if step != .describe {
            ToolbarItem(placement: .navigation) {
                Button("Back") { back() }
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch step {
        case .describe:
            Button("Next") { step = .details }
                .foregroundStyle(canProceedFromDescribe ? Theme.teal : Theme.textTertiary)
                .disabled(!canProceedFromDescribe)
        case .details:
            Button("Next") { step = .count }
                .foregroundStyle(Theme.teal)
        case .count:
            Button(action: generate) {
                Label("Generate Portraits", systemImage: "sparkles")
            }
            .foregroundStyle(settings.falIsConfigured ? Theme.teal : Theme.textTertiary)
            .disabled(!settings.falIsConfigured)
        }
    }

    private func back() {
        switch step {
        case .details:  step = .describe
        case .count:    step = .details
        case .describe: break
        }
    }

    private func generate() {
        vm.createAndGenerate(
            name: trimmedName.isEmpty ? "Unnamed" : trimmedName,
            description: description,
            role: role,
            answers: answers,
            portraitCount: portraitCount
        )
        dismiss()
    }

    // MARK: Helpers

    private func formSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            content()
        }
    }

    private func progressDots(current: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i <= current ? Theme.teal : Color.white.opacity(0.12))
                    .frame(width: 6, height: 6)
            }
            Spacer()
        }
    }
}

// MARK: - Styled Text Field

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    var isMultiLine = false

    var body: some View {
        Group {
            if isMultiLine {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(14)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(minHeight: 90)
                }
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(14)
            }
        }
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
