import SwiftUI

// MARK: - Storyboard Composer View
//
// Outer shell for the Storyboard module. Hosts a segmented picker that
// switches between the two sub-steps: Moodboard (visual identity canvas)
// and Details (the panel grid / pacing / shot reference that used to be
// the entire module). The underlying document state is shared — switching
// steps doesn't unload either view-model's observation.

enum StoryboardStep: String, CaseIterable, Identifiable {
    case moodboard, details
    var id: String { rawValue }
    var title: String {
        switch self {
        case .moodboard: return "Moodboard"
        case .details:   return "Details"
        }
    }
    var icon: String {
        switch self {
        case .moodboard: return "paintpalette.fill"
        case .details:   return "square.grid.3x2.fill"
        }
    }
    var subtitle: String {
        switch self {
        case .moodboard: return "Lock in the film's visual identity"
        case .details:   return "Shot-by-shot panel grid & pacing"
        }
    }
}

struct StoryboardComposerView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @State private var step: StoryboardStep = .details

    init(project: MovieBlazeProject) {
        // Intentionally unused — kept for symmetry with sibling modules so
        // RootView's dispatch table doesn't have to special-case Storyboard.
        _ = project
    }

    var body: some View {
        VStack(spacing: 0) {
            stepPicker
            Divider().background(Theme.stroke)
            Group {
                switch step {
                case .moodboard: MoodboardView(project: project)
                case .details:   StoryboardDetailsView(project: project)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.bg)
    }

    private var stepPicker: some View {
        HStack(spacing: 10) {
            ForEach(StoryboardStep.allCases) { s in
                stepButton(s)
            }
            Spacer()
            Text(step.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Theme.bgElevated)
    }

    private func stepButton(_ s: StoryboardStep) -> some View {
        let selected = step == s
        return Button(action: { step = s }) {
            HStack(spacing: 6) {
                Image(systemName: s.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(s.title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(selected ? .black : Theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected ? Theme.violet : Color.white.opacity(0.05))
            .overlay(
                Capsule().stroke(selected ? Color.clear : Theme.stroke, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StoryboardComposerView(project: MovieBlazeProject())
        .environmentObject(MovieBlazeProject())
        .frame(width: 1280, height: 800)
}

// MARK: - New Panel Sheet
//
// Shared by StoryboardDetailsView. Lives here so it can be used from the
// sheet presentation triggered by the details view's view model without an
// extra file.

struct NewStoryboardPanelSheet: View {
    @ObservedObject var vm: StoryboardComposerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedShotType: CameraShotType = .wide

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("SHOT TYPE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(Theme.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                            ForEach(CameraShotType.allCases) { type in
                                shotTypeOption(type)
                            }
                        }
                        Text("Details like action, dialogue, duration, and priority are set after the panel is added.")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(22)
                }
            }
            .navigationTitle("New Panel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Panel") {
                        vm.addPanel(shotType: selectedShotType)
                        dismiss()
                    }
                    .foregroundStyle(Theme.violet)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 420)
    }

    private func shotTypeOption(_ type: CameraShotType) -> some View {
        let selected = selectedShotType == type
        return Button(action: { selectedShotType = type }) {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(selected ? Theme.violet : Theme.textSecondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.shortLabel)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(selected ? Theme.violet : Theme.textTertiary)
                    Text(type.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.violet)
                }
            }
            .padding(12)
            .background(selected ? Theme.violet.opacity(0.10) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? Theme.violet.opacity(0.5) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
