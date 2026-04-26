import SwiftUI

// MARK: - Frame Inspector Panel (right column)

struct FrameInspectorPanel: View {
    let frame: Frame
    @ObservedObject var vm: FrameBuilderViewModel
    @EnvironmentObject var project: MovieBlazeProject

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                backgroundSection
                characterLabSection
                propsSection
                charactersSection
                lightingSection
                cameraSection
                guidesSection
            }
            .padding(16)
        }
        .background(Theme.bgElevated)
    }

    // MARK: Background

    private var backgroundSection: some View {
        PanelCard(title: "Background", icon: "photo.fill", tint: Theme.teal) {
            if let bg = frame.background {
                HStack(spacing: 10) {
                    ZStack {
                        LinearGradient(colors: bg.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: bg.symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(width: 56, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bg.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(bg.tag)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                }
            }
            Button(action: { vm.showBackgroundPicker = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.stack.fill")
                    Text(frame.background == nil ? "Choose Background" : "Change Background")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.teal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.teal.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
        }
    }

    // MARK: Character Lab (draggable roster)

    private var characterLabSection: some View {
        PanelCard(title: "Character Lab", icon: "person.crop.square.filled.and.at.rectangle.fill", tint: Theme.teal) {
            let finalized = project.finalizedCharacters
            if finalized.isEmpty {
                Text("No finalized characters yet. Approve a character in Character Lab to use it here.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 6) {
                    ForEach(finalized) { lab in
                        LabCharacterDragChip(
                            lab: lab,
                            isInScene: frame.characters.contains(where: { $0.name == lab.name })
                        ) {
                            // Fallback "add" button drops at default center-right
                            let pos = CGPoint(x: 0.5, y: 0.6)
                            _ = vm.addCharacter(from: lab, at: pos)
                        }
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 9))
                    Text("Drag a character onto the canvas")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(Theme.teal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            }
        }
    }

    // MARK: Props

    private var propsSection: some View {
        PanelCard(title: "Props", icon: "shippingbox.fill", tint: Theme.accent) {
            if frame.props.isEmpty {
                Text("No props added yet")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 6) {
                    ForEach(frame.props) { prop in
                        propRow(prop)
                    }
                }
            }
            Button(action: { vm.showPropPicker = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Prop")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.accent.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
        }
    }

    private func propRow(_ prop: SceneProp) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(prop.tint.opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: prop.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(prop.tint)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(prop.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(prop.category)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button(action: { vm.removeProp(prop) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plainSolid)
        }
    }

    // MARK: Characters

    private var charactersSection: some View {
        PanelCard(title: "In Scene", icon: "person.2.fill", tint: Theme.magenta) {
            if frame.characters.isEmpty {
                Text("Drag from Character Lab above onto the canvas")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 6) {
                    ForEach(frame.characters) { ch in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(ch.tint.opacity(0.25))
                                .frame(width: 22, height: 22)
                                .overlay(Text(String(ch.name.prefix(1))).font(.system(size: 10, weight: .bold)).foregroundStyle(ch.tint))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(ch.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(ch.role)
                                    .font(.system(size: 9))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            Spacer()
                            Text(ch.depthLayer.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(ch.tint)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(ch.tint.opacity(0.15))
                                .clipShape(Capsule())
                            Button(action: { vm.removeCharacter(id: ch.id) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Theme.textTertiary)
                                    .padding(4)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plainSolid)
                        }
                    }
                }
                Text("Drag on canvas · Double-tap to cycle depth")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Lighting

    private var lightingSection: some View {
        PanelCard(title: "Lighting", icon: "sun.max.fill", tint: Theme.accent) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Time of Day")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                ChipRow(items: TimeOfDay.allCases, selected: frame.timeOfDay) { t in
                    ChipContent(label: t.rawValue, icon: t.icon, tint: t.tint)
                } onSelect: { vm.setTimeOfDay($0) }

                Text("Mood")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                ChipRow(items: LightingMood.allCases, selected: frame.lightingMood) { m in
                    ChipContent(label: m.rawValue, icon: nil, tint: m.tint)
                } onSelect: { vm.setMood($0) }

                Text("Key Light Direction")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                ChipRow(items: KeyLightDirection.allCases, selected: frame.keyLight) { k in
                    ChipContent(label: k.rawValue, icon: k.icon, tint: Theme.accent)
                } onSelect: { vm.setKeyLight($0) }
            }
        }
    }

    // MARK: Camera

    private var cameraSection: some View {
        PanelCard(title: "Camera", icon: "camera.fill", tint: Theme.violet) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shot Type")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                WrappedChips(items: CameraShotType.allCases, selected: frame.shotType) { s in
                    Text(s.shortLabel)
                        .font(.system(size: 10, weight: .bold))
                } onSelect: { vm.setShot($0) }
                Text(frame.shotType.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: Composition Guides

    private var guidesSection: some View {
        PanelCard(title: "Composition Guides", icon: "grid", tint: Theme.lime) {
            VStack(spacing: 6) {
                ForEach(CompositionGuide.allCases) { guide in
                    let isOn = frame.activeGuides.contains(guide)
                    Button(action: { vm.toggleGuide(guide) }) {
                        HStack(spacing: 8) {
                            Image(systemName: guide.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(isOn ? Theme.lime : Theme.textTertiary)
                                .frame(width: 18)
                            Text(guide.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            ZStack(alignment: isOn ? .trailing : .leading) {
                                Capsule()
                                    .fill(isOn ? Theme.lime.opacity(0.4) : Color.white.opacity(0.1))
                                    .frame(width: 30, height: 16)
                                Circle()
                                    .fill(isOn ? Theme.lime : Theme.textTertiary)
                                    .frame(width: 12, height: 12)
                                    .padding(2)
                            }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(isOn ? Theme.lime.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plainSolid)
                }
            }
        }
    }
}

// MARK: - Panel Card

struct PanelCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.5)
                Spacer()
            }
            content
        }
        .padding(12)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Chip Helpers

struct ChipContent {
    let label: String
    let icon: String?
    let tint: Color
}

struct ChipRow<T: Hashable & Identifiable>: View {
    let items: [T]
    let selected: T
    let label: (T) -> ChipContent
    let onSelect: (T) -> Void

    init(items: [T], selected: T,
         label: @escaping (T) -> ChipContent,
         onSelect: @escaping (T) -> Void) {
        self.items = items
        self.selected = selected
        self.label = label
        self.onSelect = onSelect
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items) { item in
                    let isSel = item == selected
                    let info = label(item)
                    Button(action: { onSelect(item) }) {
                        HStack(spacing: 4) {
                            if let icon = info.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            Text(info.label)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(isSel ? .black : Theme.textPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(isSel ? info.tint : Color.white.opacity(0.06))
                        .overlay(
                            Capsule().stroke(isSel ? Color.clear : Theme.stroke, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plainSolid)
                }
            }
        }
    }
}

struct WrappedChips<T: Hashable & Identifiable, Content: View>: View {
    let items: [T]
    let selected: T
    @ViewBuilder let content: (T) -> Content
    let onSelect: (T) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 50, maximum: 80), spacing: 6)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(items) { item in
                let isSel = item == selected
                Button(action: { onSelect(item) }) {
                    content(item)
                        .foregroundStyle(isSel ? .black : Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isSel ? Theme.violet : Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isSel ? Color.clear : Theme.stroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plainSolid)
            }
        }
    }
}

// MARK: - Draggable Lab Character Chip

struct LabCharacterDragChip: View {
    let lab: LabCharacter
    let isInScene: Bool
    let onQuickAdd: () -> Void

    private var accent: Color { lab.finalVariation?.accentColor ?? Theme.teal }
    private var gradient: [Color] { lab.finalVariation?.gradientColors ?? [Theme.card, Theme.teal] }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(lab.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.lime)
                    Text(lab.role)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if isInScene {
                Text("IN SCENE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.lime)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Theme.lime.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Button(action: onQuickAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(5)
                        .background(accent.opacity(0.18))
                        .clipShape(Circle())
                }
                .buttonStyle(.plainSolid)
                .help("Add to scene")
            }
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .draggable(DraggableCharacter(id: lab.id, name: lab.name)) {
            // Drag preview
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(String(lab.name.prefix(1)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
                Text(lab.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.black.opacity(0.7))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Pickers (sheets)

struct BackgroundPickerSheet: View {
    @ObservedObject var vm: FrameBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Choose Background")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plainSolid)
            }
            .padding(20)
            Divider().background(Theme.stroke)
            ScrollView {
                let cols = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)]
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(FrameBuilderSamples.backgrounds) { bg in
                        Button(action: {
                            vm.setBackground(bg); dismiss()
                        }) {
                            VStack(spacing: 0) {
                                ZStack {
                                    LinearGradient(colors: bg.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    Image(systemName: bg.symbol)
                                        .font(.system(size: 36))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .frame(height: 100)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bg.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(bg.tag)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Theme.card)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Theme.stroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plainSolid)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 560, minHeight: 520)
        .background(Theme.bg)
    }
}

struct PropPickerSheet: View {
    @ObservedObject var vm: FrameBuilderViewModel
    @EnvironmentObject var project: MovieBlazeProject
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Prop")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plainSolid)
            }
            .padding(20)
            Divider().background(Theme.stroke)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !project.setPieces.isEmpty {
                        setPiecesSection
                        Divider().background(Theme.stroke)
                    }
                    presetSection
                }
                .padding(20)
            }
        }
        .frame(minWidth: 520, minHeight: 520)
        .background(Theme.bg)
    }

    private var setPiecesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Set Pieces",
                subtitle: "From this project's Set Design",
                icon: AppModule.setDesign.icon,
                tint: Theme.coral
            )
            let cols = [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 10)]
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(project.setPieces) { piece in
                    let prop = piece.asSceneProp()
                    let isAdded = vm.activeFrame?.props.contains(where: {
                        $0.sourceSetPieceID == piece.id
                    }) ?? false
                    Button(action: {
                        if isAdded {
                            if let existing = vm.activeFrame?.props.first(where: { $0.sourceSetPieceID == piece.id }) {
                                vm.removeProp(existing)
                            }
                        } else {
                            vm.addProp(prop)
                        }
                    }) {
                        SetPieceTile(piece: piece, isAdded: isAdded)
                    }
                    .buttonStyle(.plainSolid)
                }
            }
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Prop Library",
                subtitle: "Built-in presets",
                icon: "shippingbox.fill",
                tint: Theme.accent
            )
            let cols = [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 10)]
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(FrameBuilderSamples.props) { prop in
                    let isAdded = vm.activeFrame?.props.contains(prop) ?? false
                    Button(action: {
                        if isAdded { vm.removeProp(prop) } else { vm.addProp(prop) }
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(prop.tint.opacity(0.15))
                                    .frame(height: 64)
                                Image(systemName: prop.symbol)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(prop.tint)
                            }
                            Text(prop.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(prop.category)
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(10)
                        .background(Theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isAdded ? prop.tint : Theme.stroke, lineWidth: isAdded ? 2 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plainSolid)
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textSecondary)
            Text("·")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
        }
    }
}

// MARK: - Set Piece Tile

private struct SetPieceTile: View {
    let piece: SetPiece
    let isAdded: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: piece.primaryColors.isEmpty
                                ? [piece.category.tint.opacity(0.25), piece.category.tint.opacity(0.10)]
                                : piece.primaryColors.map { $0.opacity(0.35) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 64)
                if let data = piece.generatedImageData,
                   let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Image(systemName: piece.category.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(piece.category.tint)
                }
            }
            Text(piece.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Text(piece.category.title)
                .font(.system(size: 9))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(10)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isAdded ? piece.category.tint : Theme.stroke, lineWidth: isAdded ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - SetPiece → SceneProp bridge

extension SetPiece {
    func asSceneProp() -> SceneProp {
        SceneProp(
            name: name,
            category: category.title,
            tint: primaryColors.first ?? category.tint,
            symbol: category.icon,
            sourceSetPieceID: id
        )
    }
}
