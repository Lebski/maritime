import SwiftUI

struct ReferenceSheetView: View {
    let character: LabCharacter
    @ObservedObject var vm: CharacterLabViewModel
    @Environment(\.dismiss) private var dismiss

    private let sheetTypes = ReferenceSheetType.allCases

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        portraitHero
                        if let err = vm.generationError {
                            errorBanner(err)
                        }
                        generatedSheets
                    }
                    .padding(28)
                }
                if vm.isGenerating {
                    GeneratingOverlay(progress: vm.generationProgress)
                }
            }
            .navigationTitle("\(character.name) — Reference Sheets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.teal)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {}) {
                        Label("Export All", systemImage: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Theme.teal)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plainSolid)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 680)
    }

    // MARK: Portrait Hero

    private var portraitHero: some View {
        HStack(spacing: 24) {
            heroThumb
            VStack(alignment: .leading, spacing: 8) {
                Text(character.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(character.role)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                if !character.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(character.description)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(3)
                }
                statsRow
            }
            Spacer()
        }
        .padding(20)
        .cardStyle()
    }

    private var heroThumb: some View {
        ZStack {
            if let portrait = character.selectedPortrait,
               let nsImage = NSImage(data: portrait.imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                let colors = character.finalVariation?.gradientColors ?? [Theme.card, Theme.teal]
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 100, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle((character.finalVariation?.accentColor ?? Theme.teal).opacity(0.7))
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statBadge(value: "\(character.generatedSheets.count)", label: "Generated")
            statBadge(value: "\(ReferenceSheetType.allCases.count - character.generatedSheets.count)", label: "Pending")
            statBadge(value: "\(character.costumes.count)", label: "Costumes")
        }
        .padding(.top, 4)
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.teal)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    // MARK: Generated Sheets

    private var generatedSheets: some View {
        VStack(spacing: 16) {
            ForEach(sheetTypes) { sheet in
                SheetDetailRow(
                    sheet: sheet,
                    imageData: character.sheetImages[sheet],
                    accentColor: character.finalVariation?.accentColor ?? Theme.teal,
                    isBusy: vm.isGenerating,
                    onGenerate: {
                        vm.generateSheet(characterID: character.id, sheet: sheet)
                    }
                )
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.coral)
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Theme.coral.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.coral.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Sheet Detail Row

struct SheetDetailRow: View {
    let sheet: ReferenceSheetType
    let imageData: Data?
    let accentColor: Color
    let isBusy: Bool
    let onGenerate: () -> Void

    private var hasImage: Bool { imageData != nil }

    var body: some View {
        HStack(spacing: 16) {
            thumbnail
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(sheet.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if hasImage {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.teal)
                    }
                }
                Text(sheet.description)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                if hasImage {
                    Text("Ready for export")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.teal.opacity(0.8))
                } else {
                    Text("Not yet generated")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary.opacity(0.7))
                }
            }
            Spacer()
            actions
        }
        .padding(16)
        .cardStyle()
    }

    private var thumbnail: some View {
        ZStack {
            if let data = imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.card)
                    .frame(width: 80, height: 80)
                Image(systemName: sheet.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.textTertiary)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 80, height: 80)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if hasImage {
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(8)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
                .buttonStyle(.plainSolid)
                Button(action: { if !isBusy { onGenerate() } }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(8)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
                .buttonStyle(.plainSolid)
                .disabled(isBusy)
            }
        } else {
            Button(action: { if !isBusy { onGenerate() } }) {
                Text("Generate")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.teal)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            .disabled(isBusy)
        }
    }
}
