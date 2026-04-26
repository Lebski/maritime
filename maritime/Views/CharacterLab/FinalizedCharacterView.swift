import SwiftUI

struct FinalizedCharacterView: View {
    let character: LabCharacter
    @ObservedObject var vm: CharacterLabViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroCard
                referenceSheets
                characterVariables
                costumeVariants
            }
            .padding(28)
        }
        .overlay {
            if vm.isGenerating {
                GeneratingOverlay(progress: vm.generationProgress)
            }
        }
    }

    // MARK: Hero Card

    private var heroCard: some View {
        HStack(spacing: 24) {
            portraitThumb
            VStack(alignment: .leading, spacing: 10) {
                Text(character.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Label(character.role, systemImage: "person.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                if !character.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(character.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(3)
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.teal)
                    Text("Production Ready")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.teal)
                    Text("·")
                        .foregroundStyle(Theme.textTertiary)
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.magenta)
                    Text("Drag to Scene Builder")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.magenta)
                }
                .padding(.top, 4)
            }
            Spacer()
            VStack(spacing: 10) {
                Button(action: { vm.clearSelection(characterID: character.id) }) {
                    Label("Pick Different", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.07))
                        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                Button(action: { vm.showReferenceSheet = true }) {
                    Label("View Sheets", systemImage: "square.grid.2x2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.teal)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
            }
        }
        .padding(20)
        .cardStyle()
        .draggable(DraggableCharacter(id: character.id, name: character.name)) {
            HStack(spacing: 8) {
                Circle()
                    .fill(character.finalVariation?.accentColor ?? Theme.teal)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(String(character.name.prefix(1)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
                Text(character.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.black.opacity(0.7))
            .clipShape(Capsule())
        }
    }

    private var portraitThumb: some View {
        ZStack {
            if let portrait = character.selectedPortrait,
               let nsImage = NSImage(data: portrait.imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                let color = character.finalVariation?.accentColor ?? Theme.teal
                LinearGradient(
                    colors: character.finalVariation?.gradientColors ?? [Theme.card, Theme.teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 120, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Image(systemName: "person.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(color.opacity(0.7))
            }
        }
    }

    // MARK: Reference Sheets

    private var referenceSheets: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Reference Sheets")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(character.generatedSheets.count)/\(ReferenceSheetType.allCases.count) generated")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                ForEach(ReferenceSheetType.allCases) { sheet in
                    ReferenceSheetCard(
                        sheet: sheet,
                        imageData: character.sheetImages[sheet],
                        isGenerating: vm.isGenerating
                    ) {
                        vm.generateSheet(characterID: character.id, sheet: sheet)
                    }
                }
            }
        }
    }

    // MARK: Character Variables

    private var characterVariables: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Character Variables")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            VStack(spacing: 0) {
                variableRow(key: "character_id", value: "char_\(String(character.id.uuidString.prefix(8)).lowercased())")
                Divider().background(Theme.stroke)
                variableRow(key: "name", value: character.name)
                Divider().background(Theme.stroke)
                variableRow(key: "role", value: character.role)
                Divider().background(Theme.stroke)
                variableRow(key: "visual_prompt", value: character.description)
                Divider().background(Theme.stroke)
                variableRow(key: "linked_project", value: "project_current")
            }
            .cardStyle()
        }
    }

    private func variableRow(key: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.teal)
                .frame(width: 130, alignment: .leading)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
            Spacer()
            Button(action: {}) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plainSolid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Costume Variants

    private var costumeVariants: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Costume Variants")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(action: {}) {
                    Label("Add Variant", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.teal)
                }
                .buttonStyle(.plainSolid)
            }
            HStack(spacing: 12) {
                ForEach(character.costumes, id: \.self) { costume in
                    HStack(spacing: 8) {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.teal)
                        Text(costume)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }
}

// MARK: - Reference Sheet Card

struct ReferenceSheetCard: View {
    let sheet: ReferenceSheetType
    let imageData: Data?
    let isGenerating: Bool
    let onGenerate: () -> Void

    private var hasImage: Bool { imageData != nil }

    var body: some View {
        VStack(spacing: 10) {
            thumb
            VStack(spacing: 3) {
                Text(sheet.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(sheet.description)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            Button(action: { if !isGenerating { onGenerate() } }) {
                Text(hasImage ? "Regenerate" : "Generate")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(hasImage ? Theme.textTertiary : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(hasImage ? Color.white.opacity(0.06) : Theme.teal)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            .disabled(isGenerating)
        }
        .padding(12)
        .cardStyle()
    }

    private var thumb: some View {
        ZStack {
            if let data = imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.bg)
                    .frame(height: 80)
                Image(systemName: sheet.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}
