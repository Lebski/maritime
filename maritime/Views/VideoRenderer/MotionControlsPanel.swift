import SwiftUI

struct MotionControlsPanel: View {
    @ObservedObject var vm: VideoRendererViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let clip = vm.selectedClip {
                clipInfo(clip: clip)
                intensityControl(clip: clip)
            } else {
                Text("Select a clip to edit motion.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(14)
        .cardStyle()
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppModule.videoRenderer.tint)
            Text("MOTION CONTROLS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
    }

    private func clipInfo(clip: VideoClip) -> some View {
        HStack(spacing: 10) {
            ZStack {
                LinearGradient(colors: clip.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Text("#\(clip.number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(clip.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("Scene \(clip.sceneNumber) · \(String(format: "%.1fs", clip.duration))")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
    }

    private func intensityControl(clip: VideoClip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intensity")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            VStack(spacing: 6) {
                ForEach(MotionIntensity.allCases) { motion in
                    let isOn = clip.motion == motion
                    Button(action: { vm.setMotion(motion, for: clip) }) {
                        HStack(spacing: 10) {
                            Image(systemName: motion.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(isOn ? AppModule.videoRenderer.tint : Theme.textTertiary)
                                .frame(width: 20)
                            Text(motion.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            // Progress bar
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(AppModule.videoRenderer.tint)
                                    .frame(width: 60 * motion.magnitude, height: 4)
                            }
                            .frame(width: 60)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(isOn ? AppModule.videoRenderer.tint.opacity(0.1) : Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isOn ? AppModule.videoRenderer.tint.opacity(0.4) : Theme.stroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plainSolid)
                }
            }

            Button(action: { vm.toggleApproval(clip) }) {
                HStack(spacing: 6) {
                    Image(systemName: clip.isApproved ? "checkmark.seal.fill" : "seal")
                        .font(.system(size: 11))
                    Text(clip.isApproved ? "Approved for render" : "Mark approved")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(clip.isApproved ? .black : Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(clip.isApproved ? Theme.lime : Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            .padding(.top, 4)
        }
    }
}
