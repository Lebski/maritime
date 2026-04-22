import SwiftUI

// MARK: - Panel Detail Editor
//
// Inline editor for the selected StoryboardPanel. Lives under the grid on
// the Panels tab. Handles action / dialogue / duration / shot type / camera
// movement / editing priority / character assignment + delete + promote.

struct PanelDetailEditor: View {
    @ObservedObject var vm: StoryboardComposerViewModel
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        if let panel = vm.selectedPanel {
            VStack(alignment: .leading, spacing: 16) {
                header(panel)
                fieldGrid(panel)
                shotAndMovement(panel)
                priorityRow(panel)
                characterRow(panel)
                footer(panel)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            emptyHint
        }
    }

    // MARK: Header

    private func header(_ panel: StoryboardPanel) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.violet.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text("\(panel.number)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.violet)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("PANEL \(panel.number) · \(panel.shotType.shortLabel)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
                Text(panel.shotType.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            CompletionRing(value: panel.completion, size: 28, color: Theme.violet, showLabel: true)
        }
    }

    // MARK: Field grid (action + dialogue + duration + time)

    private func fieldGrid(_ panel: StoryboardPanel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            labeled("Action", subtitle: "What happens in frame. Tell it as a verb.") {
                StyledTextField(
                    placeholder: "e.g. Wren's hand closes over the lantern. Flame steadies.",
                    text: Binding(
                        get: { panel.actionNote },
                        set: { newValue in
                            var p = panel; p.actionNote = newValue; vm.updatePanel(p)
                        }),
                    isMultiLine: true
                )
                .onTapGesture { vm.focusedField = .action }
            }
            HStack(alignment: .top, spacing: 12) {
                labeled("Dialogue", subtitle: "Optional — what's spoken over this panel.") {
                    StyledTextField(
                        placeholder: "Optional dialogue or voiceover",
                        text: Binding(
                            get: { panel.dialogue },
                            set: { newValue in
                                var p = panel; p.dialogue = newValue; vm.updatePanel(p)
                            })
                    )
                    .onTapGesture { vm.focusedField = .dialogue }
                }
                durationControl(panel)
                    .frame(width: 180)
            }
            timeOfDayRow(panel)
        }
    }

    private func labeled<Content: View>(_ label: String, subtitle: String? = nil, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            content()
        }
    }

    private func durationControl(_ panel: StoryboardPanel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DURATION")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            HStack(spacing: 10) {
                Button(action: { adjustDuration(panel, by: -0.5) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                Text(panel.durationLabel)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(minWidth: 60)
                Button(action: { adjustDuration(panel, by: 0.5) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onTapGesture { vm.focusedField = .duration }
        }
    }

    private func adjustDuration(_ panel: StoryboardPanel, by delta: Double) {
        var p = panel
        p.duration = max(0.5, min(20.0, p.duration + delta))
        vm.updatePanel(p)
    }

    private func timeOfDayRow(_ panel: StoryboardPanel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TIME OF DAY")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            HStack(spacing: 8) {
                ForEach(TimeOfDay.allCases) { t in
                    Button(action: {
                        var p = panel; p.timeOfDay = t; vm.updatePanel(p)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: t.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(panel.timeOfDay == t ? .black : t.tint)
                            Text(t.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(panel.timeOfDay == t ? .black : Theme.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(panel.timeOfDay == t ? t.tint : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Shot + movement

    private func shotAndMovement(_ panel: StoryboardPanel) -> some View {
        HStack(alignment: .top, spacing: 14) {
            labeled("Shot Type") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CameraShotType.allCases) { type in
                            shotTypeChip(panel, type: type)
                        }
                    }
                }
            }
            .onTapGesture { vm.focusedField = .shotType }
            labeled("Camera Movement") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CameraMovement.allCases) { move in
                            movementChip(panel, movement: move)
                        }
                    }
                }
            }
            .onTapGesture { vm.focusedField = .movement }
        }
    }

    private func shotTypeChip(_ panel: StoryboardPanel, type: CameraShotType) -> some View {
        let selected = panel.shotType == type
        return Button(action: {
            var p = panel; p.shotType = type; vm.updatePanel(p)
        }) {
            Text(type.shortLabel)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(selected ? .black : Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Theme.violet : Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func movementChip(_ panel: StoryboardPanel, movement: CameraMovement) -> some View {
        let selected = panel.cameraMovement == movement
        return Button(action: {
            var p = panel; p.cameraMovement = movement; vm.updatePanel(p)
        }) {
            HStack(spacing: 5) {
                Image(systemName: movement.icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(movement.shortLabel)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(selected ? .black : Theme.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(selected ? Theme.teal : Color.white.opacity(0.06))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Priority

    private func priorityRow(_ panel: StoryboardPanel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EDITING PRIORITY — THE MURCH CUT")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            HStack(spacing: 10) {
                ForEach(EditingPriority.allCases) { priority in
                    priorityChip(panel, priority: priority)
                }
            }
        }
        .onTapGesture { vm.focusedField = .priority }
    }

    private func priorityChip(_ panel: StoryboardPanel, priority: EditingPriority) -> some View {
        let selected = panel.editingPriority == priority
        return Button(action: {
            var p = panel; p.editingPriority = priority; vm.updatePanel(p)
        }) {
            HStack(spacing: 8) {
                Image(systemName: priority.icon)
                    .font(.system(size: 12))
                Text(priority.rawValue)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(selected ? .black : priority.tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? priority.tint : priority.tint.opacity(0.12))
            .overlay(
                Capsule().stroke(selected ? Color.clear : priority.tint.opacity(0.4), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Characters

    private func characterRow(_ panel: StoryboardPanel) -> some View {
        let drafts = project.activeBible?.characterDrafts ?? []
        return VStack(alignment: .leading, spacing: 8) {
            Text("CHARACTERS IN FRAME")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            if drafts.isEmpty {
                Text("No character drafts in the active Story Bible. Add drafts in Story Forge to assign them here.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(drafts) { draft in
                        characterChip(panel, draft: draft)
                    }
                }
            }
        }
        .onTapGesture { vm.focusedField = .characters }
    }

    private func characterChip(_ panel: StoryboardPanel, draft: StoryCharacterDraft) -> some View {
        let selected = panel.characterDraftIDs.contains(draft.id)
        return Button(action: {
            var p = panel
            if let i = p.characterDraftIDs.firstIndex(of: draft.id) {
                p.characterDraftIDs.remove(at: i)
            } else {
                p.characterDraftIDs.append(draft.id)
            }
            vm.updatePanel(p)
        }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(selected ? Theme.teal : Theme.textTertiary.opacity(0.5))
                    .frame(width: 7, height: 7)
                Text(draft.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? Theme.teal.opacity(0.15) : Color.white.opacity(0.05))
            .overlay(
                Capsule().stroke(selected ? Theme.teal.opacity(0.5) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Footer (promote + delete)

    private func footer(_ panel: StoryboardPanel) -> some View {
        HStack(spacing: 10) {
            if panel.isPromoted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text("Sent to Scene Builder")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Theme.teal)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.teal.opacity(0.15))
                .clipShape(Capsule())
            } else {
                Button(action: { promoteAndToast() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Send Panel to Scene Builder")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.teal)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Button(action: { vm.removeSelectedPanel() }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                    Text("Delete Panel")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Promotion helper

    private func promoteAndToast() {
        guard let result = vm.promoteSelectedPanelToSceneBuilder() else { return }
        let filmSceneID = result.filmScene.id
        let nav = navigator
        navigator.showToast(ToastContent(
            message: "Sent panel #\(result.panel.number) to Scene Builder",
            actionLabel: "View in Scene Builder",
            action: { nav.openSceneBuilder(sceneID: filmSceneID) }
        ))
    }

    // MARK: Empty state

    private var emptyHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 24))
                .foregroundStyle(Theme.violet.opacity(0.6))
            Text("Select a panel")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Click a thumbnail above to edit its shot type, duration, action, and priority.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Theme.card.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
                .foregroundStyle(.clear)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

