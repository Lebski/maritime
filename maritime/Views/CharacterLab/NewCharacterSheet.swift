import SwiftUI

struct NewCharacterSheet: View {
    @ObservedObject var vm: CharacterLabViewModel
    @EnvironmentObject var project: MovieBlazeProject
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var role = "Protagonist"
    @State private var source: CharacterSource = .new

    private let roles = ["Protagonist", "Antagonist", "Supporting", "Mentor", "Love Interest", "Comic Relief"]

    private var storyDrafts: [StoryCharacterDraft] {
        project.bible.characterDrafts
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        sourceSelector
                        if source == .storyForge { storyForgePicker }
                        if source == .new { form }
                    }
                    .padding(28)
                }
            }
            .navigationTitle("New Character")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Lab") {
                        vm.createCharacter(name: name.isEmpty ? "Unnamed" : name,
                                           description: description.isEmpty ? "No description" : description,
                                           role: role)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(name.isEmpty ? Theme.textTertiary : Theme.teal)
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }

    // MARK: Source Selector

    private var sourceSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Character Source")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            VStack(spacing: 8) {
                sourceOption(.new, title: "Create New Character", subtitle: "Start fresh — describe your character", icon: "plus.circle.fill")
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
            .padding(16)
            .background(source == s ? Theme.teal.opacity(0.10) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(source == s ? Theme.teal.opacity(0.4) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    // MARK: Story Forge Picker

    private var storyForgePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(project.bible.projectTitle.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
            }
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

    // MARK: Form

    private var form: some View {
        VStack(spacing: 20) {
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

    private func formSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            content()
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
                Text("Include age, build, ethnicity, key costume details, and any distinctive features. The more precise you are, the better Round 1 variations will be.")
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
