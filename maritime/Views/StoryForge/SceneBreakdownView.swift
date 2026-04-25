import SwiftUI

struct SceneBreakdownView: View {
    @ObservedObject var vm: StoryForgeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerRow
                if !vm.bible.sceneBreakdowns.isEmpty {
                    ForEach(vm.bible.sceneBreakdowns) { scene in
                        sceneRow(scene)
                    }
                } else {
                    emptyHint
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $vm.showNewSceneSheet) {
            NewSceneBreakdownSheet(vm: vm)
        }
        .confirmationDialog(
            deleteSceneTitle,
            isPresented: Binding(
                get: { vm.pendingSceneDeletionID != nil },
                set: { if !$0 { vm.pendingSceneDeletionID = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { vm.confirmPendingSceneDeletion() }
            Button("Cancel", role: .cancel) { vm.pendingSceneDeletionID = nil }
        } message: {
            if let id = vm.pendingSceneDeletionID, vm.sceneHasFilmSceneLink(id) {
                Text("The Scene Builder scene will be kept but unlinked.")
            } else {
                Text("This action cannot be undone.")
            }
        }
    }

    private var deleteSceneTitle: String {
        guard let id = vm.pendingSceneDeletionID,
              let scene = vm.bible.sceneBreakdowns.first(where: { $0.id == id }) else {
            return "Delete scene?"
        }
        let label = scene.title.isEmpty ? "Scene \(scene.number)" : scene.title
        return "Delete \(label)?"
    }

    private var headerRow: some View {
        HStack {
            StoryForgeSectionHeader(
                title: "Scene Breakdown",
                subtitle: "One row per scene. Capture goal, conflict, and visual intent.",
                tint: Theme.magenta
            )
            Button(action: { vm.showNewSceneSheet = true }) {
                Label("New Scene", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.magenta)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 36))
                .foregroundStyle(Theme.magenta.opacity(0.6))
            Text("Plan your scenes")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Break the story into scenes. Each one becomes a shot sequence in Storyboard and a frame in Scene Builder.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: Scene Row

    private func sceneRow(_ scene: SceneBreakdown) -> some View {
        let isExpanded = vm.expandedSceneID == scene.id
        return VStack(alignment: .leading, spacing: 0) {
            collapsedRow(scene: scene, isExpanded: isExpanded)
            if isExpanded {
                Divider().background(Theme.stroke)
                expandedEditor(scene: scene)
                    .padding(16)
            }
        }
        .background(isExpanded ? Theme.card : Theme.card.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isExpanded ? Theme.magenta.opacity(0.4) : Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
    }

    private func collapsedRow(scene: SceneBreakdown, isExpanded: Bool) -> some View {
        Button(action: { vm.expandScene(scene.id) }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.magenta.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Text("\(scene.number)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.magenta)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(scene.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 8) {
                        Text(scene.locationLabel)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.textTertiary)
                        timeOfDayChip(scene.timeOfDay)
                        if !scene.conflict.isEmpty {
                            Text("· \(scene.conflict)")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                CompletionRing(value: scene.completion, size: 18, color: Theme.magenta)
                if vm.hasStoryboard(scene: scene) {
                    storyboardedBadge
                } else {
                    Button(action: { vm.storyboardScene(scene) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.3x2.fill")
                                .font(.system(size: 10))
                            Text("Storyboard")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.violet)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plainSolid)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(14)
        }
        .buttonStyle(.plainSolid)
    }

    private func timeOfDayChip(_ time: TimeOfDay) -> some View {
        HStack(spacing: 4) {
            Image(systemName: time.icon)
                .font(.system(size: 9))
            Text(time.rawValue)
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundStyle(time.tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(time.tint.opacity(0.12))
        .clipShape(Capsule())
    }

    private var storyboardedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "square.grid.3x2.fill")
                .font(.system(size: 10))
            Text("Storyboarded")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(Theme.violet)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Theme.violet.opacity(0.14))
        .clipShape(Capsule())
    }

    // MARK: Expanded Editor

    private func expandedEditor(scene: SceneBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                titleField(scene: scene)
                locationField(scene: scene)
            }
            HStack(spacing: 12) {
                interiorToggle(scene: scene)
                timeOfDayPicker(scene: scene)
            }
            charactersPicker(scene: scene)
            fieldEditor("Scene Goal", key: .goal, value: scene.sceneGoal, scene: scene)
            fieldEditor("Conflict / Obstacle", key: .conflict, value: scene.conflict, scene: scene)
            fieldEditor("Emotional Beat", key: .emotionalBeat, value: scene.emotionalBeat, scene: scene)
            fieldEditor("Visual Metaphor", key: .visualMetaphor, value: scene.visualMetaphor, scene: scene)
            fieldEditor("Transition Note", key: .transition, value: scene.transitionNote, scene: scene)
            HStack {
                Spacer()
                Button(role: .destructive, action: { vm.pendingSceneDeletionID = scene.id }) {
                    Label("Remove scene", systemImage: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.92, green: 0.45, blue: 0.45))
                }
                .buttonStyle(.plainSolid)
            }
        }
    }

    private func titleField(scene: SceneBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TITLE").font(.system(size: 9, weight: .bold)).tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            StyledTextField(
                placeholder: "Scene title",
                text: Binding(
                    get: { scene.title },
                    set: { var s = scene; s.title = $0; vm.updateScene(s) }
                )
            )
        }
    }

    private func locationField(scene: SceneBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LOCATION").font(.system(size: 9, weight: .bold)).tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            StyledTextField(
                placeholder: "e.g. Harrow Cove",
                text: Binding(
                    get: { scene.location },
                    set: { var s = scene; s.location = $0; vm.updateScene(s) }
                )
            )
        }
    }

    private func interiorToggle(scene: SceneBreakdown) -> some View {
        HStack(spacing: 6) {
            Text("INT").font(.system(size: 9, weight: .bold)).tracking(0.8)
                .foregroundStyle(scene.isInterior ? .black : Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(scene.isInterior ? Theme.magenta : Color.white.opacity(0.07))
                .clipShape(Capsule())
                .onTapGesture { var s = scene; s.isInterior = true; vm.updateScene(s) }
            Text("EXT").font(.system(size: 9, weight: .bold)).tracking(0.8)
                .foregroundStyle(!scene.isInterior ? .black : Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(!scene.isInterior ? Theme.magenta : Color.white.opacity(0.07))
                .clipShape(Capsule())
                .onTapGesture { var s = scene; s.isInterior = false; vm.updateScene(s) }
        }
    }

    private func timeOfDayPicker(scene: SceneBreakdown) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TimeOfDay.allCases) { tod in
                    Button(action: { var s = scene; s.timeOfDay = tod; vm.updateScene(s) }) {
                        HStack(spacing: 5) {
                            Image(systemName: tod.icon).font(.system(size: 9))
                            Text(tod.rawValue).font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(scene.timeOfDay == tod ? .black : tod.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(scene.timeOfDay == tod ? tod.tint : tod.tint.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plainSolid)
                }
            }
        }
    }

    private func charactersPicker(scene: SceneBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHARACTERS PRESENT").font(.system(size: 9, weight: .bold)).tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(vm.bible.characterDrafts) { draft in
                        let isIn = scene.characterDraftIDs.contains(draft.id)
                        Button(action: { toggleCharacter(draft.id, in: scene) }) {
                            HStack(spacing: 5) {
                                Image(systemName: isIn ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 10))
                                Text(draft.name).font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(isIn ? Color.black : Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isIn ? Theme.magenta : Color.white.opacity(0.07))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plainSolid)
                    }
                    if vm.bible.characterDrafts.isEmpty {
                        Text("No characters yet. Add them in the Characters tab.")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
    }

    private func toggleCharacter(_ id: UUID, in scene: SceneBreakdown) {
        var s = scene
        if s.characterDraftIDs.contains(id) {
            s.characterDraftIDs.removeAll(where: { $0 == id })
        } else {
            s.characterDraftIDs.append(id)
        }
        vm.updateScene(s)
    }

    private func fieldEditor(_ title: String,
                             key: StoryForgeViewModel.SceneField,
                             value: String,
                             scene: SceneBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(vm.focusedSceneField == key ? Theme.magenta : Theme.textTertiary)
            StyledTextField(
                placeholder: placeholder(for: key),
                text: binding(key: key, scene: scene),
                isMultiLine: key != .transition
            )
            .onTapGesture { vm.focusedSceneField = key }
        }
    }

    private func binding(key: StoryForgeViewModel.SceneField, scene: SceneBreakdown) -> Binding<String> {
        Binding(
            get: {
                switch key {
                case .goal:            return scene.sceneGoal
                case .conflict:        return scene.conflict
                case .emotionalBeat:   return scene.emotionalBeat
                case .visualMetaphor:  return scene.visualMetaphor
                case .transition:      return scene.transitionNote
                }
            },
            set: { newValue in
                var s = scene
                switch key {
                case .goal:            s.sceneGoal = newValue
                case .conflict:        s.conflict = newValue
                case .emotionalBeat:   s.emotionalBeat = newValue
                case .visualMetaphor:  s.visualMetaphor = newValue
                case .transition:      s.transitionNote = newValue
                }
                vm.updateScene(s)
            }
        )
    }

    private func placeholder(for key: StoryForgeViewModel.SceneField) -> String {
        switch key {
        case .goal:            return "What has to happen for the story to progress?"
        case .conflict:        return "What's the obstacle? Who or what pushes back?"
        case .emotionalBeat:   return "What should the audience feel?"
        case .visualMetaphor:  return "Optional — a symbolic image that carries the subtext."
        case .transition:      return "How does this scene hand off to the next?"
        }
    }
}

// MARK: - New Scene Sheet

struct NewSceneBreakdownSheet: View {
    @ObservedObject var vm: StoryForgeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var location = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("Title").font(.system(size: 10, weight: .bold)).tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                    StyledTextField(placeholder: "e.g. The Confrontation", text: $title)
                    Text("Location").font(.system(size: 10, weight: .bold)).tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                    StyledTextField(placeholder: "e.g. Harrow Cove", text: $location)
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Scene Breakdown")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        vm.addScene(title: title, location: location)
                        dismiss()
                    }
                    .foregroundStyle(title.isEmpty ? Theme.textTertiary : Theme.magenta)
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 280)
    }
}
