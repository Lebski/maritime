import SwiftUI

struct FrameCanvasView: View {
    let frame: Frame
    @ObservedObject var vm: FrameBuilderViewModel
    @EnvironmentObject var project: MovieBlazeProject
    @State private var isDropTargeted = false
    @State private var showPencilUnderlay = true

    private var parentPanel: StoryboardPanel? {
        project.storyboardPanels.first(where: { $0.id == frame.panelID })
    }

    private var pencilUnderlay: NSImage? {
        guard let assetID = parentPanel?.pencilSketchAssetID,
              let data = project.assetImageData(for: assetID) else { return nil }
        return NSImage(data: data)
    }

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
            Text("Frame Composition")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if pencilUnderlay != nil {
                Button(action: { showPencilUnderlay.toggle() }) {
                    HStack(spacing: 5) {
                        Image(systemName: showPencilUnderlay ? "scribble.variable" : "scribble")
                            .font(.system(size: 10, weight: .semibold))
                        Text(showPencilUnderlay ? "Sketch on" : "Sketch off")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(showPencilUnderlay ? Theme.violet : Theme.textTertiary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(showPencilUnderlay ? Theme.violet.opacity(0.14) : Color.white.opacity(0.05))
                    .overlay(
                        Capsule().stroke(showPencilUnderlay ? Theme.violet.opacity(0.4) : Theme.stroke, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                .help("Toggle the storyboard sketch underlay")
            }
            if frame.frameApproved {
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
                pencilUnderlayLayer
                charactersLayer(size: geo.size)
                guideOverlays(size: geo.size)
                topBadges
                dropHintOverlay
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isDropTargeted ? Theme.teal : Theme.stroke,
                            lineWidth: isDropTargeted ? 2 : 1)
            )
            .overlay {
                if vm.isGenerating {
                    GeneratingOverlay(progress: vm.generationProgress)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .dropDestination(for: DraggableCharacter.self) { items, location in
                guard let dropped = items.first else { return false }
                guard let lab = project.character(id: dropped.id) else { return false }
                let x = location.x / geo.size.width
                let y = location.y / geo.size.height
                return vm.addCharacter(from: lab, at: CGPoint(x: x, y: y))
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.15)) { isDropTargeted = targeted }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var dropHintOverlay: some View {
        if isDropTargeted {
            ZStack {
                Theme.teal.opacity(0.10)
                VStack(spacing: 8) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Theme.teal)
                    Text("Drop to place character")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.teal)
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .transition(.opacity)
        } else if frame.characters.isEmpty && !vm.isGenerating {
            VStack(spacing: 6) {
                Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.teal)
                Text("Drag a character from the panel →")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.black.opacity(0.45))
            .clipShape(Capsule())
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var pencilUnderlayLayer: some View {
        if showPencilUnderlay, let sketch = pencilUnderlay {
            Image(nsImage: sketch)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.28)
                .blendMode(.screen)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let bg = frame.background {
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
        ForEach(frame.characters) { ch in
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
            if frame.activeGuides.contains(.ruleOfThirds) {
                RuleOfThirdsOverlay()
            }
            if frame.activeGuides.contains(.goldenRatio) {
                GoldenRatioOverlay()
            }
            if frame.activeGuides.contains(.leadingLines) {
                LeadingLinesOverlay()
            }
            if frame.activeGuides.contains(.headroom) {
                HeadroomOverlay()
            }
            if frame.activeGuides.contains(.axis180) && frame.characters.count >= 2 {
                AxisLineOverlay(characters: frame.characters, size: size)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Top Badges

    private var topBadges: some View {
        VStack {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: frame.timeOfDay.icon)
                        .font(.system(size: 10))
                    Text(frame.locationLabel)
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
                    Text(frame.shotType.shortLabel)
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
            .buttonStyle(.plainSolid)
            Button(action: {}) {
                actionPill(icon: "pencil.and.scribble", label: "Edit Region", filled: false)
            }
            .buttonStyle(.plainSolid)
            Button(action: {}) {
                actionPill(icon: "link", label: "Open in Photoshop", filled: false)
            }
            .buttonStyle(.plainSolid)
            Spacer()
            if !frame.frameApproved {
                Button(action: { vm.approveFrame() }) {
                    actionPill(icon: "checkmark.seal.fill", label: "Approve Frame", filled: true)
                }
                .buttonStyle(.plainSolid)
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
