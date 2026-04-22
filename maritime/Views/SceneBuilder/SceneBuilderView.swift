import SwiftUI

struct SceneBuilderView: View {
    @StateObject private var vm = SceneBuilderViewModel()

    var body: some View {
        HStack(spacing: 0) {
            sceneList
                .frame(width: 260)
                .background(Theme.bgElevated)
            Divider().background(Theme.stroke)
            if let scene = vm.activeScene {
                mainWorkspace(scene: scene)
                Divider().background(Theme.stroke)
                SceneSetupPanel(scene: scene, vm: vm)
                    .frame(width: 320)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .sheet(isPresented: $vm.showBackgroundPicker) {
            BackgroundPickerSheet(vm: vm)
        }
        .sheet(isPresented: $vm.showPropPicker) {
            PropPickerSheet(vm: vm)
        }
    }

    // MARK: Scene List Sidebar

    private var sceneList: some View {
        VStack(spacing: 0) {
            listHeader
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(vm.scenes) { scene in
                        SceneListRow(
                            scene: scene,
                            isActive: vm.activeSceneID == scene.id
                        ) {
                            vm.setActive(scene)
                        }
                    }
                }
                .padding(10)
            }
            Divider().background(Theme.stroke)
            Button(action: { vm.createNewScene() }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.accent)
                    Text("New Scene")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
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
                    Text("Scene Builder")
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

    private func mainWorkspace(scene: FilmScene) -> some View {
        VStack(spacing: 0) {
            workspaceHeader(scene: scene)
            ScrollView {
                VStack(spacing: 20) {
                    SceneCanvasView(scene: scene, vm: vm)
                    sceneMetaRow(scene: scene)
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func workspaceHeader(scene: FilmScene) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                Text("\(scene.number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(scene.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(scene.projectTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
                Text(scene.locationLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(0.5)
            }
            Spacer()
            Button(action: {}) {
                Label("Send to Renderer", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(scene.frameApproved ? .black : Theme.textTertiary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(scene.frameApproved ? Theme.lime : Theme.card)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!scene.frameApproved)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    private func sceneMetaRow(scene: FilmScene) -> some View {
        HStack(spacing: 10) {
            metaStat(icon: scene.timeOfDay.icon, label: "Time", value: scene.timeOfDay.rawValue, tint: scene.timeOfDay.tint)
            metaStat(icon: "paintpalette.fill", label: "Mood", value: scene.lightingMood.rawValue, tint: scene.lightingMood.tint)
            metaStat(icon: "camera.fill", label: "Shot", value: scene.shotType.shortLabel, tint: Theme.violet)
            metaStat(icon: "person.2.fill", label: "Cast", value: "\(scene.characters.count)", tint: Theme.magenta)
            metaStat(icon: "shippingbox.fill", label: "Props", value: "\(scene.props.count)", tint: Theme.accent)
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
            Text("Pick or create a scene")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Scene List Row

struct SceneListRow: View {
    let scene: FilmScene
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    if let bg = scene.background {
                        LinearGradient(colors: bg.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Theme.card
                    }
                    Text("\(scene.number)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: scene.timeOfDay.icon)
                            .font(.system(size: 8))
                            .foregroundStyle(scene.timeOfDay.tint)
                        Text(scene.location)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if scene.frameApproved {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.lime)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? Theme.accent.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? Theme.accent.opacity(0.35) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
