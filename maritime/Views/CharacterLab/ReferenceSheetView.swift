import SwiftUI

struct ReferenceSheetView: View {
    let character: LabCharacter
    @Environment(\.dismiss) private var dismiss

    private let sheetTypes = ReferenceSheetType.allCases

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        portraitHero
                        generatedSheets
                    }
                    .padding(28)
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
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 680)
    }

    // MARK: Portrait Hero

    private var portraitHero: some View {
        HStack(spacing: 24) {
            ZStack {
                let colors = character.finalVariation?.gradientColors ?? [Theme.card, Theme.teal]
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 100, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle((character.finalVariation?.accentColor ?? Theme.teal).opacity(0.7))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(character.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(character.role)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                if let v = character.finalVariation {
                    Text(v.style)
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
                    isGenerated: character.generatedSheets.contains(sheet),
                    accentColor: character.finalVariation?.accentColor ?? Theme.teal
                )
            }
        }
    }
}

// MARK: - Sheet Detail Row

struct SheetDetailRow: View {
    let sheet: ReferenceSheetType
    let isGenerated: Bool
    let accentColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isGenerated ? accentColor.opacity(0.15) : Theme.card)
                    .frame(width: 80, height: 80)
                if isGenerated {
                    Image(systemName: sheet.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(accentColor)
                } else {
                    Image(systemName: sheet.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textTertiary)
                }
                if !isGenerated {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: 80, height: 80)
                }
            }
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(sheet.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if isGenerated {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.teal)
                    }
                }
                Text(sheet.description)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                if isGenerated {
                    Text("Ready for export")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.teal.opacity(0.8))
                } else {
                    Text("Not yet generated — go to Character Lab to generate")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary.opacity(0.7))
                }
            }
            Spacer()
            // Actions
            if isGenerated {
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(8)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Button(action: {}) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(8)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Pending")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .cardStyle()
    }
}
