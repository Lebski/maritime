import SwiftUI

struct VideoRendererView: View {
    @StateObject private var vm: VideoRendererViewModel

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: VideoRendererViewModel(project: project))
    }

    var body: some View {
        HStack(spacing: 0) {
            workspace
            Divider().background(Theme.stroke)
            CollapsiblePane(
                isCollapsed: $vm.inspectorCollapsed,
                edge: .trailing,
                expandedWidth: 340,
                tint: AppModule.videoRenderer.tint,
                icon: "slider.horizontal.3",
                label: "Inspector",
                shortcut: "]"
            ) {
                inspector
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }

    private var workspace: some View {
        VStack(spacing: 0) {
            header
            preview
            TimelineView(vm: vm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppModule.videoRenderer.tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: AppModule.videoRenderer.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppModule.videoRenderer.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.projectTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(vm.clips.count) clips · \(String(format: "%.1fs", vm.totalDuration)) · \(Int(vm.approvalPercent * 100))% approved")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            if vm.isRendering {
                HStack(spacing: 6) {
                    ProgressView(value: vm.renderProgress)
                        .tint(AppModule.videoRenderer.tint)
                        .frame(width: 100)
                    Text("\(Int(vm.renderProgress * 100))%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Button(action: { vm.render() }) {
                Label(vm.isRendering ? "Rendering…" : "Render",
                      systemImage: vm.isRendering ? "hourglass" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(AppModule.videoRenderer.tint)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            .disabled(vm.isRendering)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    private var preview: some View {
        ZStack {
            if let clip = vm.selectedClip {
                LinearGradient(colors: clip.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(spacing: 6) {
                    Image(systemName: clip.motion.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(clip.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(clip.motion.rawValue + " motion · " + String(format: "%.1fs", clip.duration))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                }
                VStack {
                    HStack {
                        Spacer()
                        if clip.isApproved {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 10))
                                Text("Approved")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(Theme.lime)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.black.opacity(0.5))
                            .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .padding(14)
            } else {
                Theme.card
                Text("Select a clip")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxHeight: .infinity)
        .clipped()
    }

    private var inspector: some View {
        ScrollView {
            VStack(spacing: 14) {
                MotionControlsPanel(vm: vm)
                CutSuggestionsList(vm: vm)
            }
            .padding(14)
        }
        .background(Theme.bgElevated)
    }
}
