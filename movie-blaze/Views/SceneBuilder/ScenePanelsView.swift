import SwiftUI

// MARK: - Scene Setup Panel (right column)

struct SceneSetupPanel: View {
    let scene: FilmScene
    @ObservedObject var vm: SceneBuilderViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                backgroundSection
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
            if let bg = scene.background {
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
                    Text(scene.background == nil ? "Choose Background" : "Change Background")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.teal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.teal.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Props

    private var propsSection: some View {
        PanelCard(title: "Props", icon: "shippingbox.fill", tint: Theme.accent) {
            if scene.props.isEmpty {
                Text("No props added yet")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 6) {
                    ForEach(scene.props) { prop in
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
            .buttonStyle(.plain)
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
            .buttonStyle(.plain)
        }
    }

    // MARK: Characters

    private var charactersSection: some View {
        PanelCard(title: "Characters", icon: "person.2.fill", tint: Theme.magenta) {
            if scene.characters.isEmpty {
                Text("Drag from Character Lab to add")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                VStack(spacing: 6) {
                    ForEach(scene.characters) { ch in
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
                ChipRow(items: TimeOfDay.allCases, selected: scene.timeOfDay) { t in
                    ChipContent(label: t.rawValue, icon: t.icon, tint: t.tint)
                } onSelect: { vm.setTimeOfDay($0) }

                Text("Mood")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                ChipRow(items: LightingMood.allCases, selected: scene.lightingMood) { m in
                    ChipContent(label: m.rawValue, icon: nil, tint: m.tint)
                } onSelect: { vm.setMood($0) }

                Text("Key Light Direction")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                ChipRow(items: KeyLightDirection.allCases, selected: scene.keyLight) { k in
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
                WrappedChips(items: CameraShotType.allCases, selected: scene.shotType) { s in
                    Text(s.shortLabel)
                        .font(.system(size: 10, weight: .bold))
                } onSelect: { vm.setShot($0) }
                Text(scene.shotType.rawValue)
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
                    let isOn = scene.activeGuides.contains(guide)
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
                    .buttonStyle(.plain)
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
                    .buttonStyle(.plain)
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
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Pickers (sheets)

struct BackgroundPickerSheet: View {
    @ObservedObject var vm: SceneBuilderViewModel
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
                .buttonStyle(.plain)
            }
            .padding(20)
            Divider().background(Theme.stroke)
            ScrollView {
                let cols = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)]
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(SceneBuilderSamples.backgrounds) { bg in
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
                        .buttonStyle(.plain)
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
    @ObservedObject var vm: SceneBuilderViewModel
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
                .buttonStyle(.plain)
            }
            .padding(20)
            Divider().background(Theme.stroke)
            ScrollView {
                let cols = [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 10)]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(SceneBuilderSamples.props) { prop in
                        let isAdded = vm.activeScene?.props.contains(prop) ?? false
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 520, minHeight: 520)
        .background(Theme.bg)
    }
}
