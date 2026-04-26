import SwiftUI

struct FrameBuilderView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var navigator: AppNavigator
    @StateObject private var vm: FrameBuilderViewModel
    @State private var showHelper = true
    @State private var showInnerSidebar = true
    @State private var showRenderSheet = false

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: FrameBuilderViewModel(project: project))
    }

    var body: some View {
        HStack(spacing: 0) {
            if showInnerSidebar {
                frameList
                    .frame(width: 260)
                    .background(Theme.bgElevated)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                Divider().background(Theme.stroke)
            }
            if let frame = vm.activeFrame {
                mainWorkspace(frame: frame)
                if showHelper {
                    Divider().background(Theme.stroke)
                    FrameInspectorPanel(frame: frame, vm: vm)
                        .frame(width: 320)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            } else {
                emptyState
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showHelper)
        .animation(.easeInOut(duration: 0.22), value: showInnerSidebar)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .sheet(isPresented: $vm.showBackgroundPicker) {
            BackgroundPickerSheet(vm: vm)
        }
        .sheet(isPresented: $vm.showPropPicker) {
            PropPickerSheet(vm: vm)
        }
        .sheet(isPresented: $showRenderSheet) {
            if let frame = vm.activeFrame {
                PrepareRenderSheet(frame: frame, vm: vm)
                    .environmentObject(project)
            }
        }
        .onAppear { consumePendingFrameID() }
        .onChange(of: navigator.pendingFrameID) { _, _ in consumePendingFrameID() }
    }

    private func consumePendingFrameID() {
        guard let id = navigator.pendingFrameID else { return }
        if project.frames.contains(where: { $0.id == id }) {
            vm.activeFrameID = id
        }
        navigator.pendingFrameID = nil
    }

    private var sidebarToggle: some View {
        Button(action: { showInnerSidebar.toggle() }) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(showInnerSidebar ? Theme.accent : Theme.textTertiary)
                .frame(width: 30, height: 30)
                .background(showInnerSidebar ? Theme.accent.opacity(0.14) : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
        .help(showInnerSidebar ? "Hide sidebar" : "Show sidebar")
    }

    private var helperToggle: some View {
        Button(action: { showHelper.toggle() }) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(showHelper ? Theme.accent : Theme.textTertiary)
                .frame(width: 30, height: 30)
                .background(showHelper ? Theme.accent.opacity(0.14) : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
        .help(showHelper ? "Hide setup panel" : "Show setup panel")
    }

    // MARK: Frame List Sidebar (scene → panel → frame tree)

    private var frameList: some View {
        VStack(spacing: 0) {
            listHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(sceneTreeGroups) { group in
                        SceneTreeNode(
                            group: group,
                            activeFrameID: vm.activeFrameID,
                            onSelectFrame: { frame in vm.setActive(frame) },
                            onAddKeyframe: { panelID in vm.addKeyframe(toPanel: panelID) }
                        )
                    }
                    if !orphanFrames.isEmpty {
                        OrphanFramesNode(
                            frames: orphanFrames,
                            activeFrameID: vm.activeFrameID,
                            onSelectFrame: { frame in vm.setActive(frame) }
                        )
                    }
                }
                .padding(10)
            }
            Divider().background(Theme.stroke)
            Button(action: { vm.addKeyframeToActivePanel() }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.accent)
                    Text("Add Keyframe")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plainSolid)
            .disabled(vm.activeFrame == nil)
        }
    }

    // MARK: Tree grouping

    struct SceneTreeGroup: Identifiable {
        let scene: SceneBreakdown
        let panels: [StoryboardPanel]
        var id: UUID { scene.id }
    }

    private var sceneTreeGroups: [SceneTreeGroup] {
        let panelsBySceneID = Dictionary(grouping: project.storyboardPanels.filter { $0.sceneBreakdownID != nil },
                                         by: { $0.sceneBreakdownID! })
        return project.bible.sceneBreakdowns
            .sorted(by: { $0.number < $1.number })
            .compactMap { scene in
                let panels = (panelsBySceneID[scene.id] ?? []).sorted { $0.number < $1.number }
                guard !panels.isEmpty else { return nil }
                return SceneTreeGroup(scene: scene, panels: panels)
            }
    }

    private var orphanFrames: [Frame] {
        let knownPanelIDs = Set(project.storyboardPanels.map(\.id))
        return project.frames.filter { !knownPanelIDs.contains($0.panelID) }
    }

    private var listHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accent.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Frame Builder")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Compose cinematic frames")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            Divider().background(Theme.stroke)
        }
    }

    // MARK: Main Workspace

    private func mainWorkspace(frame: Frame) -> some View {
        VStack(spacing: 0) {
            workspaceHeader(frame: frame)
            ScrollView {
                VStack(spacing: 20) {
                    FrameCanvasView(frame: frame, vm: vm)
                    frameMetaRow(frame: frame)
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func workspaceHeader(frame: Frame) -> some View {
        HStack(spacing: 14) {
            sidebarToggle
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                Text("\(frame.ordinal + 1)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                breadcrumbRow(frame: frame)
                Text(frame.locationLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(0.5)
            }
            Spacer()
            clipApprovalSummary(frame: frame)
            helperToggle
            Button(action: { showRenderSheet = true }) {
                Label("Send to Renderer", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(frame.frameApproved ? .black : Theme.textTertiary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(frame.frameApproved ? Theme.lime : Theme.card)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            .disabled(!frame.frameApproved)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    @ViewBuilder
    private func breadcrumbRow(frame: Frame) -> some View {
        let panel = project.storyboardPanels.first(where: { $0.id == frame.panelID })
        let scene = panel?.sceneBreakdownID.flatMap { sid in
            project.bible.sceneBreakdowns.first(where: { $0.id == sid })
        }
        HStack(spacing: 6) {
            if let scene {
                breadcrumbCrumb(
                    title: "Scene \(scene.number)",
                    subtitle: scene.title,
                    tint: Theme.violet
                )
                breadcrumbSeparator
            }
            if let panel {
                breadcrumbCrumb(
                    title: "Shot \(panel.number)",
                    subtitle: panel.shotType.shortLabel,
                    tint: Theme.teal
                )
                breadcrumbSeparator
            }
            breadcrumbCrumb(
                title: "Frame \(frame.ordinal + 1)",
                subtitle: frame.role.rawValue,
                tint: Theme.accent,
                strong: true
            )
        }
    }

    private func breadcrumbCrumb(title: String, subtitle: String, tint: Color, strong: Bool = false) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: strong ? 16 : 13, weight: .bold))
                .foregroundStyle(strong ? Theme.textPrimary : Theme.textSecondary)
            Text(subtitle)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(tint)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(tint.opacity(0.16))
                .clipShape(Capsule())
        }
    }

    private var breadcrumbSeparator: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Theme.textTertiary)
    }

    @ViewBuilder
    private func clipApprovalSummary(frame: Frame) -> some View {
        let panel = project.storyboardPanels.first(where: { $0.id == frame.panelID })
        if let panel {
            let siblings = project.frames(forPanel: panel.id)
            let approvedCount = siblings.filter(\.frameApproved).count
            let total = siblings.count
            HStack(spacing: 6) {
                Image(systemName: panel.clipApproved ? "checkmark.seal.fill" : "seal")
                    .font(.system(size: 11))
                    .foregroundStyle(panel.clipApproved ? Theme.lime : Theme.textTertiary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(panel.clipApproved ? "Clip approved" : "Clip pending")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(panel.clipApproved ? Theme.lime : Theme.textSecondary)
                    Text("\(approvedCount)/\(total) frames")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(panel.clipApproved ? Theme.lime.opacity(0.4) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func frameMetaRow(frame: Frame) -> some View {
        HStack(spacing: 10) {
            metaStat(icon: frame.timeOfDay.icon, label: "Time", value: frame.timeOfDay.rawValue, tint: frame.timeOfDay.tint)
            metaStat(icon: "paintpalette.fill", label: "Mood", value: frame.lightingMood.rawValue, tint: frame.lightingMood.tint)
            metaStat(icon: "camera.fill", label: "Shot", value: frame.shotType.shortLabel, tint: Theme.violet)
            metaStat(icon: "person.2.fill", label: "Cast", value: "\(frame.characters.count)", tint: Theme.magenta)
            metaStat(icon: "shippingbox.fill", label: "Props", value: "\(frame.props.count)", tint: Theme.accent)
        }
    }

    private func metaStat(icon: String, label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(tint)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(0.5)
            }
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
            Text("Pick or create a frame")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tree Sidebar Nodes

struct SceneTreeNode: View {
    let group: FrameBuilderView.SceneTreeGroup
    let activeFrameID: UUID?
    let onSelectFrame: (Frame) -> Void
    let onAddKeyframe: (UUID) -> Void
    @EnvironmentObject var project: MovieBlazeProject
    @State private var expanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            DisclosureGroup(isExpanded: $expanded) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(group.panels) { panel in
                        PanelTreeNode(
                            panel: panel,
                            activeFrameID: activeFrameID,
                            onSelectFrame: onSelectFrame,
                            onAddKeyframe: onAddKeyframe
                        )
                    }
                }
                .padding(.leading, 4)
            } label: {
                HStack(spacing: 6) {
                    Text("SCENE \(group.scene.number)")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                    Text(group.scene.title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(group.panels.count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
            }
            .disclosureGroupStyle(SidebarDisclosureStyle())
        }
    }
}

struct PanelTreeNode: View {
    let panel: StoryboardPanel
    let activeFrameID: UUID?
    let onSelectFrame: (Frame) -> Void
    let onAddKeyframe: (UUID) -> Void
    @EnvironmentObject var project: MovieBlazeProject
    @State private var expanded: Bool = true

    private var frames: [Frame] {
        project.frames(forPanel: panel.id).sorted(by: { $0.ordinal < $1.ordinal })
    }

    private var sketchImage: NSImage? {
        guard let assetID = panel.pencilSketchAssetID,
              let data = project.assetImageData(for: assetID) else { return nil }
        return NSImage(data: data)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(frames) { frame in
                    FrameTreeLeaf(
                        frame: frame,
                        isActive: activeFrameID == frame.id,
                        onTap: { onSelectFrame(frame) }
                    )
                }
                Button(action: { onAddKeyframe(panel.id) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Add Keyframe")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Theme.accent.opacity(0.85))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                .padding(.leading, 28)
                .padding(.top, 2)
            }
            .padding(.leading, 4)
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    if let sketch = sketchImage {
                        Image(nsImage: sketch)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        LinearGradient(colors: panel.thumbnailColors,
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                .frame(width: 36, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 0.5)
                )
                VStack(alignment: .leading, spacing: 1) {
                    Text("Shot \(panel.number) · \(panel.shotType.shortLabel)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text("\(frames.count) keyframe\(frames.count == 1 ? "" : "s")")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                if panel.clipApproved {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.lime)
                }
            }
        }
        .disclosureGroupStyle(SidebarDisclosureStyle())
    }
}

struct FrameTreeLeaf: View {
    let frame: Frame
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(roleTint.opacity(0.18))
                        .frame(width: 22, height: 22)
                    Text("\(frame.ordinal + 1)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(roleTint)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(frame.role.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(frame.location)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                if frame.frameApproved {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.lime)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .padding(.leading, 16)
            .background(isActive ? Theme.accent.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isActive ? Theme.accent.opacity(0.35) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var roleTint: Color {
        switch frame.role {
        case .keyStart:     return Theme.teal
        case .keyEnd:       return Theme.magenta
        case .hold:         return Theme.violet
        case .intermediate: return Theme.accent
        }
    }
}

struct OrphanFramesNode: View {
    let frames: [Frame]
    let activeFrameID: UUID?
    let onSelectFrame: (Frame) -> Void
    @State private var expanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(frames) { frame in
                    FrameTreeLeaf(
                        frame: frame,
                        isActive: activeFrameID == frame.id,
                        onTap: { onSelectFrame(frame) }
                    )
                }
            }
            .padding(.leading, 4)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.folder")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                Text("ORPHANED FRAMES")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(frames.count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .disclosureGroupStyle(SidebarDisclosureStyle())
    }
}

private struct SidebarDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    configuration.isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 12)
                    configuration.label
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 8).padding(.vertical, 5)
            }
            .buttonStyle(.plainSolid)
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}

// MARK: - Prepare Render Sheet
//
// Assembles a `RenderPackage` from the current Frame + project character roster
// and hands it to the Frame Builder view model for rendering. Four numbered
// sections mirror what Nano Banana 2 will receive: composition snapshot,
// prompt, character references (from Character Lab), style refs.

struct PrepareRenderSheet: View {
    let frame: Frame
    @ObservedObject var vm: FrameBuilderViewModel
    @EnvironmentObject var project: MovieBlazeProject
    @Environment(\.dismiss) private var dismiss

    @State private var prompt: String
    @State private var characterRefs: [CharacterReference]
    @State private var aspectRatio: AspectRatio
    @State private var model: ImageModel
    @State private var errorMessage: String?

    init(frame: Frame, vm: FrameBuilderViewModel) {
        self.frame = frame
        self.vm = vm
        let existing = frame.renderPackage
        _prompt         = State(initialValue: existing?.prompt ?? "")
        _characterRefs  = State(initialValue: existing?.characterReferences ?? [])
        _aspectRatio    = State(initialValue: existing?.aspectRatio ?? .widescreen16x9)
        _model          = State(initialValue: existing?.model ?? .nanoBanana2)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Theme.stroke)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionCompositionPreview
                    sectionPrompt
                    sectionCharacterReferences
                    sectionStyleReferences
                }
                .padding(24)
            }
            Divider().background(Theme.stroke)
            footer
        }
        .frame(minWidth: 720, idealWidth: 840, minHeight: 640, idealHeight: 760)
        .background(Theme.bg)
        .onAppear { seedPromptIfEmpty() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.lime.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.lime)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Prepare Render — \(frame.title)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Assemble prompt + up to \(model.maxReferenceImages) reference images for \(model.rawValue).")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plainSolid)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.bgElevated)
    }

    // MARK: Section 1 — Composition preview

    private var sectionCompositionPreview: some View {
        sectionContainer(number: 1, title: "Frame Composition",
                         subtitle: "\(frame.locationLabel) · \(frame.shotType.shortLabel)") {
            HStack(alignment: .top, spacing: 16) {
                compositionThumbnail
                    .frame(width: 260)
                VStack(alignment: .leading, spacing: 6) {
                    compositionFact("Cast", "\(frame.characters.count) character\(frame.characters.count == 1 ? "" : "s")")
                    compositionFact("Props", "\(frame.props.count)")
                    compositionFact("Guides", frame.activeGuides.isEmpty
                                    ? "—"
                                    : frame.activeGuides.map { $0.rawValue }.sorted().joined(separator: ", "))
                    compositionFact("Lighting", "\(frame.lightingMood.rawValue) · \(frame.keyLight.rawValue)")
                }
                Spacer()
            }
        }
    }

    private var compositionThumbnail: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                if let bg = frame.background {
                    LinearGradient(colors: bg.gradientColors,
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                } else {
                    Theme.bgElevated
                }
                RadialGradient(colors: [Color.clear, Color.black.opacity(0.5)],
                               center: .center,
                               startRadius: min(w, h) * 0.3,
                               endRadius: max(w, h) * 0.7)
                ForEach(frame.characters) { ch in
                    Circle()
                        .fill(ch.tint.opacity(0.6))
                        .frame(width: 14 * ch.depthLayer.scale, height: 14 * ch.depthLayer.scale)
                        .position(x: ch.xRatio * w, y: ch.yRatio * h)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
        }
        .aspectRatio(16.0/9.0, contentMode: .fit)
    }

    private func compositionFact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: Section 2 — Prompt

    private var sectionPrompt: some View {
        sectionContainer(number: 2, title: "Prompt",
                         subtitle: "Edit freely. Re-seed to regenerate from frame parameters.") {
            VStack(alignment: .trailing, spacing: 10) {
                TextEditor(text: $prompt)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 120)
                    .background(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Button(action: reseedPrompt) {
                    Label("Re-seed from frame", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
            }
        }
    }

    // MARK: Section 3 — Character references

    private var sectionCharacterReferences: some View {
        sectionContainer(number: 3, title: "Character References",
                         subtitle: "Lock character likeness using sheets from Character Lab.") {
            if frame.characters.isEmpty {
                emptyNote("No characters placed on the canvas yet.")
            } else {
                VStack(spacing: 10) {
                    ForEach(frame.characters) { ref in
                        CharacterReferenceRow(
                            sceneRef: ref,
                            lab: project.characters.first(where: { $0.name == ref.name }),
                            selectedSheet: selectedSheet(for: ref),
                            onSelect: { sheet in selectSheet(for: ref, sheet: sheet) }
                        )
                    }
                }
            }
        }
    }

    private func selectedSheet(for ref: SceneCharacterRef) -> ReferenceSheetType? {
        guard let lab = project.characters.first(where: { $0.name == ref.name }) else { return nil }
        return characterRefs.first(where: { $0.characterID == lab.id })?.selectedSheetType
    }

    private func selectSheet(for ref: SceneCharacterRef, sheet: ReferenceSheetType) {
        guard let lab = project.characters.first(where: { $0.name == ref.name }) else { return }
        if let idx = characterRefs.firstIndex(where: { $0.characterID == lab.id }) {
            characterRefs[idx].selectedSheetType = sheet
        } else {
            characterRefs.append(CharacterReference(characterID: lab.id, selectedSheetType: sheet))
        }
    }

    // MARK: Section 4 — Style references

    private var sectionStyleReferences: some View {
        sectionContainer(number: 4, title: "Style References",
                         subtitle: "Optional — drop mood-board images to lock tone.") {
            VStack(spacing: 12) {
                styleDropZone
                HStack {
                    Text("Slots remaining: \(remainingSlots)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                }
            }
        }
    }

    private var styleDropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 26))
                .foregroundStyle(Theme.violet.opacity(0.7))
            Text("Drop mood-board images here")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Drag from Finder · coming in the next pass")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Theme.card.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    Theme.violet.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var remainingSlots: Int {
        max(0, model.maxReferenceImages - (1 + characterRefs.count))
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Picker("Model", selection: $model) {
                ForEach(ImageModel.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 180)

            Picker("Ratio", selection: $aspectRatio) {
                ForEach(AspectRatio.allCases) { r in
                    Text(r.label).tag(r)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 120)

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.magenta)
                    .lineLimit(2)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            Button(action: renderTapped) {
                HStack(spacing: 6) {
                    if vm.isGenerating {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                    }
                    Text(vm.isGenerating ? "Rendering…" : "Render with \(model.rawValue)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Theme.lime)
                .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            .disabled(vm.isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.bgElevated)
    }

    // MARK: Actions

    private func seedPromptIfEmpty() {
        if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reseedPrompt()
        }
    }

    private func reseedPrompt() {
        prompt = PromptBuilder.buildPrompt(frame: frame, characters: project.characters)
    }

    private func renderTapped() {
        errorMessage = nil
        let package = RenderPackage(
            id: frame.renderPackage?.id ?? UUID(),
            frameID: frame.id,
            prompt: prompt,
            sceneCompositionImage: frame.renderPackage?.sceneCompositionImage,
            characterReferences: characterRefs,
            styleReferences: frame.renderPackage?.styleReferences ?? [],
            model: model,
            aspectRatio: aspectRatio,
            lastRenderedAt: frame.renderPackage?.lastRenderedAt
        )
        Task {
            let success = await vm.render(package: package)
            if success { dismiss() }
            else { errorMessage = vm.renderErrorMessage }
        }
    }

    // MARK: Helpers

    private func sectionContainer<Content: View>(number: Int,
                                                 title: String,
                                                 subtitle: String,
                                                 @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.18))
                        .frame(width: 22, height: 22)
                    Text("\(number)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            content()
                .padding(14)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func emptyNote(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Character Reference Row

struct CharacterReferenceRow: View {
    let sceneRef: SceneCharacterRef
    let lab: LabCharacter?
    let selectedSheet: ReferenceSheetType?
    let onSelect: (ReferenceSheetType) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(sceneRef.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(sceneRef.role.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.textTertiary)
                }
                if let lab {
                    if lab.generatedSheets.isEmpty {
                        Text("No reference sheets generated yet. Open Character Lab to create them.")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    } else {
                        sheetChips(availableSheets: Array(lab.generatedSheets).sorted(by: { $0.rawValue < $1.rawValue }))
                    }
                } else {
                    Text("Not linked to a Character Lab entry — add from the Lab to enable references.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer()
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(sceneRef.tint.opacity(0.25))
                .frame(width: 36, height: 36)
            Circle()
                .stroke(sceneRef.tint, lineWidth: 1.5)
                .frame(width: 36, height: 36)
            Text(String(sceneRef.name.prefix(1)))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(sceneRef.tint)
        }
    }

    private func sheetChips(availableSheets: [ReferenceSheetType]) -> some View {
        HStack(spacing: 6) {
            ForEach(availableSheets) { sheet in
                Button(action: { onSelect(sheet) }) {
                    HStack(spacing: 5) {
                        Image(systemName: sheet.icon)
                            .font(.system(size: 9, weight: .semibold))
                        Text(sheet.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selectedSheet == sheet ? .black : Theme.textSecondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(selectedSheet == sheet ? Theme.lime : Color.white.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(selectedSheet == sheet ? Color.clear : Theme.stroke, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
            }
        }
    }
}
