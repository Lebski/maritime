import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Set Piece Prompt Panel
//
// Right-side editor. Drives everything that isn't the big preview: the
// name, category, prompt seed, tags, and the reference image drop target
// used for image-to-image generation.

struct SetPiecePromptPanel: View {
    @ObservedObject var vm: SetDesignViewModel
    let piece: SetPiece

    @State private var nameDraft = ""
    @State private var descriptionDraft = ""
    @State private var promptDraft = ""
    @State private var tagsDraft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                categoryPicker
                nameField
                descriptionField
                promptField
                tagsField
                referenceImageSection
                regenerateButton
                Spacer(minLength: 40)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgElevated)
        .onAppear { hydrate(from: piece) }
        .onChange(of: piece.id) { _, _ in hydrate(from: piece) }
    }

    private func hydrate(from piece: SetPiece) {
        nameDraft = piece.name
        descriptionDraft = piece.description
        promptDraft = piece.promptSeed
        tagsDraft = piece.tags.joined(separator: ", ")
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.coral.opacity(0.18))
                    .frame(width: 30, height: 30)
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.coral)
            }
            Text("Piece Settings")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Category")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(SetPieceCategory.allCases) { cat in
                    categoryChip(cat)
                }
            }
        }
    }

    private func categoryChip(_ cat: SetPieceCategory) -> some View {
        let selected = piece.category == cat
        return Button(action: { vm.updateCategory(cat) }) {
            VStack(spacing: 4) {
                Image(systemName: cat.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selected ? .black : cat.tint)
                Text(cat.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selected ? .black : Theme.textSecondary)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(selected ? cat.tint : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(selected ? Color.clear : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Name")
            TextField("", text: $nameDraft)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary)
                .padding(10)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onChange(of: nameDraft) { _, newValue in
                    vm.updateName(newValue)
                }
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Description")
            TextEditor(text: $descriptionDraft)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 60)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onChange(of: descriptionDraft) { _, newValue in
                    vm.updateDescription(newValue)
                }
        }
    }

    private var promptField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                label("Prompt Seed")
                Spacer()
                Text("\(promptDraft.count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textTertiary)
            }
            TextEditor(text: $promptDraft)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 110)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onChange(of: promptDraft) { _, newValue in
                    vm.updatePrompt(newValue)
                }
        }
    }

    private var tagsField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Tags")
            TextField("", text: $tagsDraft, prompt: Text("comma separated"))
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textPrimary)
                .padding(10)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onChange(of: tagsDraft) { _, newValue in
                    vm.updateTags(newValue)
                }
        }
    }

    // MARK: Reference image

    private var referenceImageSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                label("Reference Image")
                Spacer()
                if piece.hasReferenceImage {
                    Button(action: vm.clearReferenceImage) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove reference image")
                }
            }
            referenceDropTarget
            Text("Used as an image-to-image seed when generating.")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var referenceDropTarget: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            Theme.stroke,
                            style: StrokeStyle(lineWidth: 1, dash: piece.hasReferenceImage ? [] : [5, 4])
                        )
                )
            if let data = piece.referenceImageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.coral)
                    Text("Drop image or click to choose")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 20)
            }
        }
        .frame(height: 120)
        .contentShape(Rectangle())
        .onTapGesture { chooseReferenceImage() }
        .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    // MARK: Regenerate

    @ViewBuilder
    private var regenerateButton: some View {
        let busy = vm.isGenerating(piece.id)
        let canGenerate = !piece.promptSeed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        Button(action: { vm.regenerate(piece) }) {
            HStack(spacing: 8) {
                if busy {
                    ProgressView().controlSize(.small).tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                }
                Text(busy ? "Generating…" : piece.hasGeneratedImage ? "Regenerate" : "Generate")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                if piece.hasReferenceImage && !busy {
                    Text("with reference")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .foregroundStyle(canGenerate ? .white : Theme.textTertiary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(canGenerate ? Theme.accent : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canGenerate || busy)
        .help(canGenerate ? "Generate image from the prompt seed" : "Add a prompt seed to enable generation")
    }

    // MARK: Helpers

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(Theme.textTertiary)
    }

    private func chooseReferenceImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url,
           let data = try? Data(contentsOf: url) {
            vm.attachReferenceImage(data)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data else { return }
                Task { @MainActor in vm.attachReferenceImage(data) }
            }
            return true
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, let data = try? Data(contentsOf: url) else { return }
                Task { @MainActor in vm.attachReferenceImage(data) }
            }
            return true
        }
        return false
    }
}
