import SwiftUI

struct SceneCanvasView: View {
    let scene: FilmScene
    @ObservedObject var vm: SceneBuilderViewModel

    var body: some View {
        VStack(spacing: 16) {
            canvasHeader
            canvas
            frameActions
        }
    }

    // MARK: Header

    private var canvasHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 13))
                .foregroundStyle(Theme.accent)
            Text("Start Frame Composition")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if scene.frameApproved {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                    Text("Approved")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Theme.lime)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Theme.lime.opacity(0.15))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: Canvas

    private var canvas: some View {
        GeometryReader { geo in
            ZStack {
                backgroundLayer
                charactersLayer(size: geo.size)
                guideOverlays(size: geo.size)
                topBadges
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .overlay {
                if vm.isGenerating {
                    GeneratingOverlay(progress: vm.generationProgress)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let bg = scene.background {
            LinearGradient(colors: bg.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            // atmospheric vignette
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.55)],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            // subtle ambient symbol
            Image(systemName: bg.symbol)
                .font(.system(size: 180, weight: .light))
                .foregroundStyle(Color.white.opacity(0.05))
        } else {
            Theme.bgElevated
            VStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.textTertiary)
                Text("No background selected")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private func charactersLayer(size: CGSize) -> some View {
        ForEach(scene.characters) { ch in
            CharacterPin(character: ch)
                .position(x: ch.xRatio * size.width, y: ch.yRatio * size.height)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            let x = v.location.x / size.width
                            let y = v.location.y / size.height
                            vm.moveCharacter(id: ch.id, x: x, y: y)
                        }
                )
                .onTapGesture(count: 2) {
                    vm.cycleDepth(id: ch.id)
                }
        }
    }

    private func guideOverlays(size: CGSize) -> some View {
        ZStack {
            if scene.activeGuides.contains(.ruleOfThirds) {
                RuleOfThirdsOverlay()
            }
            if scene.activeGuides.contains(.goldenRatio) {
                GoldenRatioOverlay()
            }
            if scene.activeGuides.contains(.leadingLines) {
                LeadingLinesOverlay()
            }
            if scene.activeGuides.contains(.headroom) {
                HeadroomOverlay()
            }
            if scene.activeGuides.contains(.axis180) && scene.characters.count >= 2 {
                AxisLineOverlay(characters: scene.characters, size: size)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Top Badges

    private var topBadges: some View {
        VStack {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: scene.timeOfDay.icon)
                        .font(.system(size: 10))
                    Text(scene.locationLabel)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.black.opacity(0.5))
                .clipShape(Capsule())
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10))
                    Text(scene.shotType.shortLabel)
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.black.opacity(0.5))
                .clipShape(Capsule())
            }
            .padding(10)
            Spacer()
        }
    }

    // MARK: Frame Actions

    private var frameActions: some View {
        HStack(spacing: 10) {
            Button(action: { vm.regenerateFrame() }) {
                actionPill(icon: "arrow.triangle.2.circlepath", label: "Regenerate", filled: false)
            }
            .buttonStyle(.plain)
            Button(action: {}) {
                actionPill(icon: "pencil.and.scribble", label: "Edit Region", filled: false)
            }
            .buttonStyle(.plain)
            Button(action: {}) {
                actionPill(icon: "link", label: "Open in Photoshop", filled: false)
            }
            .buttonStyle(.plain)
            Spacer()
            if !scene.frameApproved {
                Button(action: { vm.approveFrame() }) {
                    actionPill(icon: "checkmark.seal.fill", label: "Approve Frame", filled: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func actionPill(icon: String, label: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(filled ? .black : Theme.textPrimary)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(filled ? Theme.accent : Color.white.opacity(0.06))
        .overlay(
            Capsule().stroke(filled ? Color.clear : Theme.stroke, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Character Pin

struct CharacterPin: View {
    let character: SceneCharacterRef

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(character.tint.opacity(0.25))
                    .frame(width: 66 * character.depthLayer.scale, height: 66 * character.depthLayer.scale)
                Circle()
                    .stroke(character.tint, lineWidth: 2)
                    .frame(width: 66 * character.depthLayer.scale, height: 66 * character.depthLayer.scale)
                Text(String(character.name.prefix(1)))
                    .font(.system(size: 22 * character.depthLayer.scale, weight: .bold))
                    .foregroundStyle(character.tint)
                // gaze arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 10 * character.depthLayer.scale, weight: .bold))
                    .foregroundStyle(character.tint)
                    .offset(x: 38 * character.depthLayer.scale)
                    .rotationEffect(.degrees(character.gazeDegrees))
            }
            HStack(spacing: 4) {
                Text(character.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                Text(character.depthLayer.rawValue)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(character.tint)
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(character.tint.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(.black.opacity(0.5))
            .clipShape(Capsule())
        }
        .opacity(character.depthLayer.opacity)
    }
}

// MARK: - Guide Overlays

struct RuleOfThirdsOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                let w = geo.size.width, h = geo.size.height
                p.move(to: CGPoint(x: w/3, y: 0));   p.addLine(to: CGPoint(x: w/3, y: h))
                p.move(to: CGPoint(x: 2*w/3, y: 0)); p.addLine(to: CGPoint(x: 2*w/3, y: h))
                p.move(to: CGPoint(x: 0, y: h/3));   p.addLine(to: CGPoint(x: w, y: h/3))
                p.move(to: CGPoint(x: 0, y: 2*h/3)); p.addLine(to: CGPoint(x: w, y: 2*h/3))
            }
            .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }
}

struct GoldenRatioOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let phi: CGFloat = 0.618
            Path { p in
                p.move(to: CGPoint(x: w * phi, y: 0));       p.addLine(to: CGPoint(x: w * phi, y: h))
                p.move(to: CGPoint(x: w * (1 - phi), y: 0)); p.addLine(to: CGPoint(x: w * (1 - phi), y: h))
                p.move(to: CGPoint(x: 0, y: h * phi));       p.addLine(to: CGPoint(x: w, y: h * phi))
                p.move(to: CGPoint(x: 0, y: h * (1 - phi))); p.addLine(to: CGPoint(x: w, y: h * (1 - phi)))
            }
            .stroke(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }
}

struct LeadingLinesOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.move(to: .zero);                  p.addLine(to: CGPoint(x: w/2, y: h/2))
                p.move(to: CGPoint(x: w, y: 0));    p.addLine(to: CGPoint(x: w/2, y: h/2))
                p.move(to: CGPoint(x: 0, y: h));    p.addLine(to: CGPoint(x: w/2, y: h/2))
                p.move(to: CGPoint(x: w, y: h));    p.addLine(to: CGPoint(x: w/2, y: h/2))
            }
            .stroke(Theme.teal.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
    }
}

struct HeadroomOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: 0, y: h * 0.15))
                p.addLine(to: CGPoint(x: w, y: h * 0.15))
            }
            .stroke(Theme.magenta.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6, 3]))
        }
    }
}

struct AxisLineOverlay: View {
    let characters: [SceneCharacterRef]
    let size: CGSize

    var body: some View {
        guard characters.count >= 2 else { return AnyView(EmptyView()) }
        let a = characters[0], b = characters[1]
        let p1 = CGPoint(x: a.xRatio * size.width, y: a.yRatio * size.height)
        let p2 = CGPoint(x: b.xRatio * size.width, y: b.yRatio * size.height)
        // extend line across the frame
        let dx = p2.x - p1.x, dy = p2.y - p1.y
        let scale: CGFloat = 3
        let start = CGPoint(x: p1.x - dx * scale, y: p1.y - dy * scale)
        let end   = CGPoint(x: p2.x + dx * scale, y: p2.y + dy * scale)
        return AnyView(
            Path { p in
                p.move(to: start); p.addLine(to: end)
            }
            .stroke(Theme.violet.opacity(0.6), style: StrokeStyle(lineWidth: 1.2, dash: [8, 4]))
        )
    }
}
