import SwiftUI

struct CharacterBuilderView: View {
    @ObservedObject var vm: StoryForgeViewModel
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 0) {
            draftListColumn
                .frame(width: 220)
            Divider().background(Theme.stroke)
            editorColumn
                .frame(maxWidth: .infinity)
        }
        .sheet(item: $vm.wizardMode) { mode in
            CharacterWizardSheet(mode: mode, vm: vm)
                .environmentObject(settings)
        }
        .alert("Generation failed",
               isPresented: Binding(
                   get: { vm.generationError != nil },
                   set: { if !$0 { vm.generationError = nil } }
               ),
               presenting: vm.generationError) { _ in
            Button("OK") { vm.generationError = nil }
        } message: { detail in
            Text(detail)
        }
        .confirmationDialog(
            deleteDraftTitle,
            isPresented: $vm.confirmingDraftDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { vm.removeActiveDraft() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if vm.activeDraftHasLabLink {
                Text("The Character Lab character will be kept but unlinked.")
            } else {
                Text("This action cannot be undone.")
            }
        }
    }

    private var deleteDraftTitle: String {
        if let name = vm.activeDraft?.name, !name.isEmpty {
            return "Delete \(name)?"
        }
        return "Delete draft?"
    }

    // MARK: Draft List

    private var draftListColumn: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Characters")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Menu {
                    Button {
                        vm.wizardMode = .new
                    } label: {
                        Label("New with AI…", systemImage: "sparkles")
                    }
                    Button {
                        vm.showNewCharacterSheet = true
                    } label: {
                        Label("Blank draft", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.magenta)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().background(Theme.stroke)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(vm.bible.characterDrafts) { draft in
                        draftRow(draft)
                    }
                    if vm.bible.characterDrafts.isEmpty {
                        emptyDraftsHint
                    }
                }
                .padding(10)
            }
        }
        .background(Color.white.opacity(0.02))
        .sheet(isPresented: $vm.showNewCharacterSheet) {
            NewStoryCharacterSheet(vm: vm)
        }
    }

    private func draftRow(_ draft: StoryCharacterDraft) -> some View {
        Button(action: { vm.selectDraft(draft.id) }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(roleColor(for: draft.role))
                        .frame(width: 8, height: 8)
                    Text(draft.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                }
                HStack(spacing: 6) {
                    Text(draft.role.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                    CompletionRing(value: draft.completion, size: 14, color: Theme.magenta)
                }
            }
            .padding(10)
            .background(vm.activeDraftID == draft.id ? Theme.magenta.opacity(0.10) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(vm.activeDraftID == draft.id ? Theme.magenta.opacity(0.55) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var emptyDraftsHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.dashed")
                .font(.system(size: 28))
                .foregroundStyle(Theme.magenta.opacity(0.6))
            Text("Start with a protagonist")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
    }

    private func roleColor(for role: String) -> Color {
        let lower = role.lowercased()
        if lower.contains("prot") { return Theme.magenta }
        if lower.contains("ant") { return Theme.accent }
        if lower.contains("mentor") { return Theme.teal }
        if lower.contains("ally") || lower.contains("love") { return Theme.lime }
        return Theme.violet
    }

    // MARK: Editor

    private var editorColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerBar

                if let draft = vm.activeDraft {
                    ForEach(StoryCharacterField.allCases) { field in
                        fieldCardBinding(for: field, draft: draft)
                    }
                } else {
                    emptyEditor
                }
            }
            .padding(24)
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            if let draft = vm.activeDraft {
                TextField("Character name", text: Binding(
                    get: { draft.name },
                    set: { vm.updateDraftName($0) }
                ))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .textFieldStyle(.plain)
                .frame(maxWidth: 320)

                roleMenu(current: draft.role)

                Spacer()

                aiGenerateMenu(draft: draft)

                Menu {
                    Button(role: .destructive) { vm.confirmingDraftDelete = true } label: {
                        Label("Remove draft", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textSecondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            } else {
                Text("Character Builder")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
        }
    }

    private func roleMenu(current: String) -> some View {
        Menu {
            ForEach(["Protagonist", "Antagonist", "Supporting", "Mentor", "Love Interest", "Comic Relief"], id: \.self) { r in
                Button(r) { vm.updateDraftRole(r) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(current)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }


    private func fieldCardBinding(for field: StoryCharacterField, draft: StoryCharacterDraft) -> some View {
        FieldCard(
            field: field,
            text: Binding(
                get: { draft.value(for: field) },
                set: { vm.updateDraftField(field, value: $0) }
            ),
            isFocused: vm.focusedField == field,
            onFocus: { vm.focusedField = field },
            onRegenerate: StoryCharacterField.psychologyFields.contains(field)
                ? { Task { await vm.regenerate(field: field, settings: settings) } }
                : nil,
            isRegenerating: vm.regeneratingField == field
        )
    }

    // MARK: AI Generate Menu

    @ViewBuilder
    private func aiGenerateMenu(draft: StoryCharacterDraft) -> some View {
        Menu {
            Button {
                vm.wizardMode = .refine(draftID: draft.id)
            } label: {
                Label("Fill empty fields…", systemImage: "sparkles")
            }
            .disabled(!settings.isConfigured)

            if !settings.isConfigured {
                Divider()
                Text("Add your Anthropic API key in Preferences (⌘,) to enable.")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").font(.system(size: 11))
                Text("Generate with AI").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(settings.isConfigured ? Theme.textPrimary : Theme.textTertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(settings.isConfigured ? 0.08 : 0.03))
            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
            .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var emptyEditor: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 42))
                .foregroundStyle(Theme.magenta.opacity(0.6))
            Text("Add your first character")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Start with the protagonist. Tell Claude a name, role, and a sentence of backstory — it'll draft Want, Need, Ghost, Flaw, Stakes, and Voice for you to refine.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            VStack(spacing: 8) {
                Button(action: { vm.wizardMode = .new }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles").font(.system(size: 12))
                        Text("Start with AI").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.magenta)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)

                Button(action: { vm.showNewCharacterSheet = true }) {
                    Text("Blank character")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plainSolid)
            }

            if !settings.isConfigured {
                Text("Add your Anthropic API key in Preferences (⌘,) to enable AI.")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - New Character Sheet

struct NewStoryCharacterSheet: View {
    @ObservedObject var vm: StoryForgeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var role = "Protagonist"
    private let roles = ["Protagonist", "Antagonist", "Supporting", "Mentor", "Love Interest", "Comic Relief"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("Character Name").font(.system(size: 10, weight: .bold)).tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                    StyledTextField(placeholder: "e.g. Nan, Wren, Mara", text: $name)
                    Text("Role").font(.system(size: 10, weight: .bold)).tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(roles, id: \.self) { r in
                                Button(action: { role = r }) {
                                    Text(r)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(role == r ? .black : Theme.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(role == r ? Theme.magenta : Color.white.opacity(0.07))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plainSolid)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Character Draft")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        vm.addCharacterDraft(name: name, role: role)
                        dismiss()
                    }
                    .foregroundStyle(name.isEmpty ? Theme.textTertiary : Theme.magenta)
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 320)
    }
}
