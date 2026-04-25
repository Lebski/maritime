import SwiftUI

/// Grid of recraft-v4 portrait variations. The user taps to highlight one,
/// then clicks "Use This Portrait" to lock it in as the seed for downstream
/// reference sheets.
struct PortraitGalleryView: View {
    let character: LabCharacter
    @ObservedObject var vm: CharacterLabViewModel

    @State private var pendingSelection: UUID? = nil

    private var portraits: [PortraitVariation] {
        character.portraitVariations.sorted(by: { $0.index < $1.index })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                if let err = vm.generationError {
                    errorBanner(err)
                }
                gallery
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

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pick your portrait")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Tap a portrait, then lock it in. The chosen photo becomes the reference for the head turnaround, full body, and expression sheets.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Variations")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                Text("\(portraits.count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.teal)
            }
        }
        .padding(18)
        .cardStyle()
    }

    // MARK: Gallery

    private var gallery: some View {
        let cols = [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 14)]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(portraits) { p in
                PortraitTile(
                    portrait: p,
                    isSelected: pendingSelection == p.id,
                    accent: character.finalVariation?.accentColor ?? Theme.teal
                ) {
                    pendingSelection = p.id
                }
            }
        }
    }

    // MARK: Action bar

    private var actionBar: some View {
        let canConfirm = pendingSelection != nil
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: regenerate) {
                    Text("Regenerate All")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                .disabled(vm.isGenerating)

                Button(action: confirmSelection) {
                    Label("Use This Portrait", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(canConfirm ? .black : Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canConfirm ? Theme.teal : Theme.card)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                .disabled(!canConfirm)
            }
            Button(action: tweakDescription) {
                Text("↻  Tweak Description")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plainSolid)
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

    // MARK: Actions

    private func confirmSelection() {
        guard let pid = pendingSelection else { return }
        vm.selectPortrait(characterID: character.id, portraitID: pid)
    }

    private func regenerate() {
        pendingSelection = nil
        vm.regeneratePortraits(characterID: character.id)
    }

    private func tweakDescription() {
        vm.returnToSetup(characterID: character.id)
    }
}

// MARK: - Portrait tile

struct PortraitTile: View {
    let portrait: PortraitVariation
    let isSelected: Bool
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let nsImage = NSImage(data: portrait.imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Theme.card)
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.textTertiary)
                        )
                }
                if isSelected {
                    ZStack {
                        Circle().fill(accent).frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    .padding(10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? accent : Theme.stroke, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plainSolid)
    }
}

// MARK: - Generating overlay (shared with workspace)

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
                Text("Generating portraits…")
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
