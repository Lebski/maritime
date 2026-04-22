import SwiftUI

// MARK: - Shot Library View
//
// Reference grid of all 10 CameraShotType cases with description + classic
// film example. Each card has an "Apply to selected" CTA that updates the
// selected panel's shot type.

struct ShotLibraryView: View {
    @ObservedObject var vm: StoryboardComposerViewModel

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(CameraShotType.allCases) { type in
                        ShotTypeCard(
                            type: type,
                            canApply: vm.selectedPanel != nil,
                            isActive: vm.selectedPanel?.shotType == type,
                            onApply: { vm.applyShotType(type) }
                        )
                    }
                }
            }
            .padding(24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SHOT TYPE LIBRARY")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            Text("Ten shots that have carried a hundred years of cinema.")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Pick any card's \"Apply to selected\" button to stamp it onto the current panel.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Shot Type Card

struct ShotTypeCard: View {
    let type: CameraShotType
    let canApply: Bool
    let isActive: Bool
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text(type.description)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            exampleRow
            applyButton
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(isActive ? Theme.violet.opacity(0.10) : Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isActive ? Theme.violet.opacity(0.55) : Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.violet.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.violet)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(type.shortLabel)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.violet)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.violet.opacity(0.15))
                    .clipShape(Capsule())
                Text(type.rawValue)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.violet)
            }
        }
    }

    private var exampleRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "film.fill")
                .font(.system(size: 10))
                .foregroundStyle(Theme.accent)
                .padding(.top, 2)
            Text(type.filmExample)
                .font(.system(size: 11, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.accent.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var applyButton: some View {
        Button(action: onApply) {
            HStack(spacing: 6) {
                Image(systemName: isActive ? "checkmark" : "arrow.right.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(isActive ? "Applied" : "Apply to selected")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(canApply ? (isActive ? Theme.teal : Theme.textPrimary) : Theme.textTertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                canApply
                    ? (isActive ? Theme.teal.opacity(0.15) : Theme.violet.opacity(0.15))
                    : Color.white.opacity(0.04)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plainSolid)
        .disabled(!canApply)
    }
}
