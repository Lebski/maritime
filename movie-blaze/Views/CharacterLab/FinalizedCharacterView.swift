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
    }

    // MARK: Hero Card

    private var heroCard: some View {
        HStack(spacing: 24) {
            ZStack {
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
            VStack(alignment: .leading, spacing: 10) {
                Text(character.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Label(character.role, systemImage: "person.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                if let v = character.finalVariation {
                    Text(v.style)
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
                }
                .padding(.top, 4)
            }
            Spacer()
            VStack(spacing: 10) {
                Button(action: {
                    if let id = vm.characters.first(where: { $0.id == character.id })?.id {
                        vm.requestMoreRounds(characterID: id)
                    }
                }) {
                    Label("Re-refine", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.07))
                        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Button(action: { vm.showReferenceSheet = true }) {
                    Label("View Sheets", systemImage: "square.grid.2x2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.teal)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .cardStyle()
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
                        isGenerated: character.generatedSheets.contains(sheet),
                        isGenerating: vm.isGenerating
                    ) {
                        if let id = vm.characters.first(where: { $0.id == character.id })?.id {
                            vm.generateSheet(characterID: id, sheet: sheet)
                        }
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
            .buttonStyle(.plain)
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
                .buttonStyle(.plain)
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
    let isGenerated: Bool
    let isGenerating: Bool
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isGenerated ? Theme.teal.opacity(0.15) : Theme.bg)
                    .frame(height: 80)
                if isGenerated {
                    Image(systemName: sheet.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.teal)
                } else {
                    Image(systemName: sheet.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
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
                Text(isGenerated ? "Regenerate" : "Generate")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isGenerated ? Theme.textTertiary : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(isGenerated ? Color.white.opacity(0.06) : Theme.teal)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isGenerating)
        }
        .padding(12)
        .cardStyle()
    }
}
