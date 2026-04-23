import SwiftUI

// MARK: - Storyboard Panel Card
//
// A 16:9 programmatic "thumbnail sketch" of a panel. Mirrors the visual
// language of SceneCanvasView but scaled down: gradient base + vignette +
// faint SF symbol + character silhouettes positioned per shot type.
// Deterministic, no AI generation required.

struct StoryboardPanelCard: View {
    let panel: StoryboardPanel
    let isSelected: Bool
    let onTap: () -> Void
    var onReturnToScene: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnail
            metaRow
        }
        .padding(10)
        .background(isSelected ? Theme.violet.opacity(0.10) : Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Theme.violet : Theme.stroke, lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture { onTap() }
    }

    // MARK: Thumbnail

    private var thumbnail: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Gradient base
                LinearGradient(colors: panel.thumbnailColors,
                               startPoint: .topLeading, endPoint: .bottomTrailing)

                // Radial vignette
                RadialGradient(colors: [Color.clear, Color.black.opacity(0.5)],
                               center: .center,
                               startRadius: min(w, h) * 0.25,
                               endRadius: max(w, h) * 0.7)

                // Faint symbol backdrop
                Image(systemName: panel.thumbnailSymbol)
                    .font(.system(size: h * 0.72, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.06))
                    .offset(x: w * 0.08, y: h * 0.04)

                // Character silhouettes positioned by shot type
                silhouetteGroup(width: w, height: h)
                    .rotationEffect(panel.shotType == .dutchAngle ? .degrees(-7) : .zero)

                // POV scope overlay
                if panel.shotType == .pov {
                    Image(systemName: "scope")
                        .font(.system(size: h * 0.7, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                // Top row — number + duration
                VStack {
                    HStack {
                        panelNumberBubble
                        Spacer()
                        durationBadge
                    }
                    Spacer()
                    HStack {
                        shotTypeChip
                        Spacer()
                        priorityDot
                    }
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .aspectRatio(16.0/9.0, contentMode: .fit)
    }

    @ViewBuilder
    private func silhouetteGroup(width w: CGFloat, height h: CGFloat) -> some View {
        switch panel.shotType {
        case .wide:
            // Two small circles on the thirds
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 12, height: 12)
                .position(x: w * 0.33, y: h * 0.62)
            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 10, height: 10)
                .position(x: w * 0.66, y: h * 0.64)
        case .full:
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 16, height: 32)
                .position(x: w * 0.5, y: h * 0.58)
        case .medium:
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 22, height: 22)
                .position(x: w * 0.55, y: h * 0.55)
        case .closeUp:
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 40, height: 40)
                .position(x: w * 0.5, y: h * 0.5)
        case .extremeCloseUp:
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: min(w, h) * 0.7, height: min(w, h) * 0.7)
                .position(x: w * 0.5, y: h * 0.5)
        case .overTheShoulder:
            Circle()
                .fill(Color.black.opacity(0.45))
                .frame(width: 60, height: 60)
                .position(x: w * 0.22, y: h * 0.85)
            Circle()
                .fill(Color.white.opacity(0.42))
                .frame(width: 22, height: 22)
                .position(x: w * 0.66, y: h * 0.42)
        case .pov:
            EmptyView()   // handled by scope overlay
        case .dutchAngle:
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 24, height: 24)
                .position(x: w * 0.5, y: h * 0.55)
        case .lowAngle:
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 20, height: 20)
                .position(x: w * 0.5, y: h * 0.38)
        case .highAngle:
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 18, height: 18)
                .position(x: w * 0.5, y: h * 0.72)
        }
    }

    // MARK: Badges

    private var panelNumberBubble: some View {
        Text("\(panel.number)")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(width: 20, height: 20)
            .background(Color.black.opacity(0.55))
            .clipShape(Circle())
    }

    private var durationBadge: some View {
        Text(panel.durationLabel)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.55))
            .clipShape(Capsule())
    }

    private var shotTypeChip: some View {
        Text(panel.shotType.shortLabel)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.violet.opacity(0.85))
            .clipShape(Capsule())
    }

    private var priorityDot: some View {
        Circle()
            .fill(panel.editingPriority.tint)
            .frame(width: 8, height: 8)
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
    }

    // MARK: Meta row

    private var metaRow: some View {
        HStack(spacing: 8) {
            Image(systemName: panel.cameraMovement.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(panel.cameraMovement.shortLabel)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            if panel.isPromoted {
                inBuilderChip
            } else {
                Image(systemName: panel.timeOfDay.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(panel.timeOfDay.tint)
                Text(panel.timeOfDay.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var inBuilderChip: some View {
        if let onReturnToScene {
            Button(action: onReturnToScene) {
                chipLabel
            }
            .buttonStyle(.plainSolid)
            .help("Open the matching scene in Scene Builder")
        } else {
            chipLabel
        }
    }

    private var chipLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.right.square.fill")
                .font(.system(size: 10))
            Text("VIEW IN BUILDER")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
        }
        .foregroundStyle(Theme.teal)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Theme.teal.opacity(0.14))
        .overlay(Capsule().stroke(Theme.teal.opacity(0.35), lineWidth: 1))
        .clipShape(Capsule())
    }
}
