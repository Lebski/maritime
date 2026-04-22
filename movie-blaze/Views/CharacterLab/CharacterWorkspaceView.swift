import SwiftUI

struct CharacterWorkspaceView: View {
    let character: LabCharacter
    @ObservedObject var vm: CharacterLabViewModel

    var body: some View {
        VStack(spacing: 0) {
            workspaceHeader
            if character.isFinalized {
                FinalizedCharacterView(character: character, vm: vm)
            } else {
                RefinementView(character: character, vm: vm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Header

    private var workspaceHeader: some View {
        HStack(spacing: 14) {
            avatarBadge
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(character.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if character.isFinalized {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                            Text("Finalized")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Theme.teal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.teal.opacity(0.15))
                        .clipShape(Capsule())
                    } else {
                        Text(character.currentRound.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.accent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text("\(character.role) · \(character.description)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            if character.isFinalized {
                Button(action: { vm.showReferenceSheet = true }) {
                    Label("Reference Sheets", systemImage: "square.grid.2x2.fill")
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
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    private var avatarBadge: some View {
        ZStack {
            let color = character.finalVariation?.accentColor ?? character.selectedVariations.first?.accentColor ?? Theme.teal
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.2))
                .frame(width: 52, height: 52)
            Text(String(character.name.prefix(1)))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Refinement Flow

struct RefinementView: View {
    let character: LabCharacter
    @ObservedObject var vm: CharacterLabViewModel

    private var variations: [CharacterVariation] {
        switch character.currentRound {
        case .broad:   return CharacterLabSamples.broadVariations
        case .focused: return CharacterLabSamples.focusedVariations
        case .polish:  return CharacterLabSamples.polishVariations
        }
    }

    private var selectedIDs: Set<UUID> {
        Set(character.selectedVariations.map { $0.id })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                roundProgressBar
                roundHeader
                variationsGrid
                actionBar
            }
            .padding(28)
        }
        .overlay {
            if vm.isGenerating {
                GeneratingOverlay(progress: vm.generationProgress)
            }
        }
    }

    // MARK: Round Progress Bar

    private var roundProgressBar: some View {
        HStack(spacing: 0) {
            ForEach(RefinementRound.allCases, id: \.rawValue) { round in
                let isActive = round.rawValue <= character.currentRound.rawValue
                let isCurrent = round == character.currentRound
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(isActive ? Theme.teal : Theme.card)
                            .frame(width: 28, height: 28)
                        if isActive && !isCurrent {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.black)
                        } else {
                            Text("\(round.rawValue)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(isCurrent ? .black : Theme.textTertiary)
                        }
                    }
                    if round != .polish {
                        Rectangle()
                            .fill(isActive ? Theme.teal.opacity(0.5) : Theme.stroke)
                            .frame(maxWidth: .infinity)
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: Round Header

    private var roundHeader: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(character.currentRound.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(character.currentRound.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Selected")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                Text("\(character.selectedVariations.count) / \(character.currentRound.maxSelections)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.teal)
            }
        }
        .padding(18)
        .cardStyle()
    }

    // MARK: Variations Grid

    private var variationsGrid: some View {
        let cols = [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 14)]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(variations) { variation in
                VariationCard(
                    variation: variation,
                    isSelected: selectedIDs.contains(variation.id),
                    round: character.currentRound
                ) {
                    if let id = vm.characters.first(where: { $0.id == character.id })?.id {
                        vm.toggleVariation(characterID: id, variation: variation)
                    }
                }
            }
        }
    }

    // MARK: Action Bar

    private var actionBar: some View {
        let hasSelections = !character.selectedVariations.isEmpty
        let isPolish = character.currentRound == .polish

        return VStack(spacing: 12) {
            if isPolish && hasSelections {
                polishActions
            } else {
                standardActions(hasSelections: hasSelections)
            }
            Button(action: {
                if let id = vm.characters.first(where: { $0.id == character.id })?.id {
                    vm.requestMoreRounds(characterID: id)
                }
            }) {
                Text("↻  Request More Rounds")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var polishActions: some View {
        HStack(spacing: 12) {
            Button(action: { vm.showNewCharacter = false }) {
                Text("Provide Edit Notes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button(action: {
                guard let sel = character.selectedVariations.first else { return }
                if let id = vm.characters.first(where: { $0.id == character.id })?.id {
                    vm.finalizeCharacter(characterID: id, variation: sel)
                }
            }) {
                Label("Finalize Character", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.teal)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func standardActions(hasSelections: Bool) -> some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Text("Regenerate All")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button(action: {
                if let id = vm.characters.first(where: { $0.id == character.id })?.id {
                    vm.advanceRound(characterID: id)
                }
            }) {
                let nextTitle = character.currentRound == .broad ? "Continue to Round 2 →" : "Continue to Round 3 →"
                Text(hasSelections ? nextTitle : "Select \(character.currentRound.maxSelections) to continue")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(hasSelections ? .black : Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(hasSelections ? Theme.teal : Theme.card)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!hasSelections)
        }
    }
}

// MARK: - Variation Card

struct VariationCard: View {
    let variation: CharacterVariation
    let isSelected: Bool
    let round: RefinementRound
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                artworkArea
                infoArea
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? variation.accentColor : Theme.stroke, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var artworkArea: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: variation.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 160)
            // Faux character silhouette
            VStack {
                Spacer()
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(variation.accentColor.opacity(0.6))
                Spacer()
            }
            if isSelected {
                ZStack {
                    Circle().fill(variation.accentColor).frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                }
                .padding(10)
            }
        }
    }

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(variation.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Text(variation.age)
                .font(.system(size: 10))
                .foregroundStyle(variation.accentColor)
            Text(variation.style)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card)
    }
}

// MARK: - Generating Overlay

struct GeneratingOverlay: View {
    let progress: Double

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Theme.teal.opacity(0.2), lineWidth: 4)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.teal, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 72, height: 72)
                        .animation(.easeInOut(duration: 0.15), value: progress)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.teal)
                }
                Text("Generating variations…")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(40)
            .background(Theme.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}
