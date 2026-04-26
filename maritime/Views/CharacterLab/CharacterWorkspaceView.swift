import SwiftUI

struct CharacterWorkspaceView: View {
    let character: LabCharacter
    @ObservedObject var vm: CharacterLabViewModel

    var body: some View {
        VStack(spacing: 0) {
            workspaceHeader
            phaseContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch character.phase {
        case .setup:
            CharacterSetupPlaceholderView(character: character, vm: vm)
        case .generating:
            ZStack {
                Color.clear
                GeneratingOverlay(progress: vm.generationProgress)
            }
        case .selecting:
            PortraitGalleryView(character: character, vm: vm)
        case .finalized:
            FinalizedCharacterView(character: character, vm: vm)
        }
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
                    phaseBadge
                }
                Text("\(character.role) · \(character.description)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            if character.phase == .finalized {
                Button(action: { vm.showReferenceSheet = true }) {
                    Label("Reference Sheets", systemImage: "square.grid.2x2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.teal)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    @ViewBuilder
    private var phaseBadge: some View {
        switch character.phase {
        case .finalized:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 11))
                Text("Finalized").font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Theme.teal)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.teal.opacity(0.15))
            .clipShape(Capsule())
        case .generating:
            badgeChip("Generating Portraits", tint: Theme.accent)
        case .selecting:
            badgeChip("Pick a Portrait", tint: Theme.accent)
        case .setup:
            badgeChip("Setup", tint: Theme.textTertiary)
        }
    }

    private func badgeChip(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.15))
            .clipShape(Capsule())
    }

    private var avatarBadge: some View {
        ZStack {
            let color = character.finalVariation?.accentColor ?? Theme.teal
            if let portrait = character.selectedPortrait,
               let nsImage = NSImage(data: portrait.imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(0.2))
                    .frame(width: 52, height: 52)
                Text(String(character.name.prefix(1)))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Setup placeholder (shown if a character somehow lands back in .setup)

struct CharacterSetupPlaceholderView: View {
    let character: LabCharacter
    @ObservedObject var vm: CharacterLabViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 38))
                .foregroundStyle(Theme.teal.opacity(0.7))
            Text("Set up \(character.name)'s portraits")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Tell us how this character looks — facial features, hair, build, clothing — and how many portrait variations to generate.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            Button(action: { vm.openSetup(for: character.id) }) {
                Label("Set up character", systemImage: "wand.and.stars")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.teal)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            if let err = vm.generationError {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.coral)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
