import SwiftUI

struct RhythmTimingBar: View {
    @ObservedObject var vm: StoryboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "metronome")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppModule.storyboard.tint)
                    Text("RHYTHM & TIMING")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                timingStat(label: "Total", value: String(format: "%.1fs", vm.totalDuration))
                timingStat(label: "Avg Shot", value: String(format: "%.1fs", vm.averagePace))
                timingStat(label: "Panels", value: "\(vm.panels.count)")
            }

            bar

            if !vm.panels.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                    Text(rhythmAdvice)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .top)
    }

    private var bar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(vm.panels) { panel in
                    let width = max(12, geo.size.width * (panel.duration / max(0.1, vm.totalDuration)))
                    ZStack {
                        LinearGradient(colors: panel.gradientColors, startPoint: .leading, endPoint: .trailing)
                        Text("\(panel.number)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: width, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(vm.selectedPanelID == panel.id ? .white : Color.clear, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onTapGesture { vm.setActive(panel) }
                }
            }
        }
        .frame(height: 20)
    }

    private var rhythmAdvice: String {
        let avg = vm.averagePace
        if vm.panels.isEmpty { return "Add panels to see pacing." }
        if avg < 1.5 { return "Fast cuts — high energy. Watch for viewer fatigue." }
        if avg < 3.0 { return "Conversational pace. Room for performance to breathe." }
        if avg < 5.0 { return "Measured pace. Good for suspense and mood." }
        return "Slow burn — each cut carries weight. Make them count."
    }

    private func timingStat(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.white.opacity(0.04))
        .clipShape(Capsule())
    }
}
