import SwiftUI

// MARK: - Rhythm & Timing Planner
//
// Four stacked sections: metric cards, pacing curve, shot-type distribution,
// editing-priority mix.

struct RhythmPlannerView: View {
    @ObservedObject var vm: StoryboardComposerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let panels = vm.panels
                if !panels.isEmpty {
                    header(panels)
                    metricCards(panels)
                    pacingCurve(panels)
                    shotDistribution(panels)
                    priorityMix(panels)
                    murchQuote
                } else {
                    emptyRhythm
                }
            }
            .padding(24)
        }
    }

    // MARK: Header

    private func header(_ panels: [StoryboardPanel]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RHYTHM & TIMING")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            Text("The sequence's pulse, at a glance.")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Average shot length tells you how the scene breathes. Distribution tells you which shots you lean on. Priority mix tells you why you cut.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Metric cards

    private func metricCards(_ panels: [StoryboardPanel]) -> some View {
        HStack(spacing: 12) {
            metricCard(
                label: "Total Runtime",
                value: panels.runtimeLabel,
                subtitle: "M:SS across \(panels.count) panels",
                tint: Theme.violet
            )
            metricCard(
                label: "Panel Count",
                value: "\(panels.count)",
                subtitle: "\(panels.unpromotedCount) unpromoted",
                tint: Theme.teal
            )
            metricCard(
                label: "Avg Shot Length",
                value: String(format: "%.1fs", panels.averageShotLength),
                subtitle: aslSubtitle(panels.averageShotLength),
                tint: Theme.accent
            )
            metricCard(
                label: "Promoted",
                value: "\(panels.promotedCount)/\(panels.count)",
                subtitle: "→ Scene Builder",
                tint: Theme.magenta
            )
        }
    }

    private func aslSubtitle(_ asl: Double) -> String {
        switch asl {
        case ..<1.8: return "Action pacing"
        case 1.8..<3.5: return "Modern drama pace"
        case 3.5..<6.0: return "Classical pace"
        default: return "Slow cinema"
        }
    }

    private func metricCard(label: String, value: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Pacing curve

    private func pacingCurve(_ panels: [StoryboardPanel]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PACING CURVE")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            Text("Panel duration across cumulative runtime. Peaks = sustained shots; valleys = staccato.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            pacingChart(panels)
                .frame(height: 120)
                .padding(12)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func pacingChart(_ panels: [StoryboardPanel]) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxDuration = (panels.map(\.duration).max() ?? 1)
            let totalRuntime = max(panels.totalRuntime, 0.1)
            let points: [(CGFloat, CGFloat, StoryboardPanel)] = {
                var cumulative: Double = 0
                return panels.map { panel in
                    let midpoint = cumulative + panel.duration / 2.0
                    cumulative += panel.duration
                    let x = w * CGFloat(midpoint / totalRuntime)
                    let y = h * CGFloat(1.0 - (panel.duration / maxDuration))
                    return (x, y, panel)
                }
            }()
            ZStack {
                // Baseline
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h))
                    p.addLine(to: CGPoint(x: w, y: h))
                }
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                // Fill under
                Path { p in
                    guard let first = points.first, let last = points.last else { return }
                    p.move(to: CGPoint(x: first.0, y: h))
                    for pt in points { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
                    p.addLine(to: CGPoint(x: last.0, y: h))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Theme.violet.opacity(0.35), Theme.violet.opacity(0.0)],
                                     startPoint: .top, endPoint: .bottom))
                // Curve line
                Path { p in
                    for (i, pt) in points.enumerated() {
                        if i == 0 { p.move(to: CGPoint(x: pt.0, y: pt.1)) }
                        else { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
                    }
                }
                .stroke(Theme.violet, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                // Dots
                ForEach(points.indices, id: \.self) { i in
                    let (x, y, panel) = points[i]
                    let isSelected = vm.selectedPanelID == panel.id
                    Circle()
                        .fill(isSelected ? Theme.accent : Theme.violet)
                        .frame(width: isSelected ? 10 : 6, height: isSelected ? 10 : 6)
                        .overlay(
                            Circle().stroke(Theme.bg, lineWidth: isSelected ? 2 : 1)
                        )
                        .position(x: x, y: y)
                }
            }
        }
    }

    // MARK: Shot distribution

    private func shotDistribution(_ panels: [StoryboardPanel]) -> some View {
        let histogram = panels.shotTypeHistogram
        let total = max(1, panels.count)
        return VStack(alignment: .leading, spacing: 10) {
            Text("SHOT TYPE DISTRIBUTION")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(histogram, id: \.0) { (type, count) in
                        Rectangle()
                            .fill(tint(for: type))
                            .frame(width: max(2, geo.size.width * CGFloat(Double(count) / Double(total)) - 2))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .frame(height: 14)
            // Legend
            FlowLayout(spacing: 10) {
                ForEach(histogram, id: \.0) { (type, count) in
                    legendChip(type: type, count: count, total: total)
                }
            }
        }
        .padding(14)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func legendChip(type: CameraShotType, count: Int, total: Int) -> some View {
        let pct = Int((Double(count) / Double(total) * 100).rounded())
        return HStack(spacing: 6) {
            Rectangle()
                .fill(tint(for: type))
                .frame(width: 10, height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            Text(type.shortLabel)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Theme.textSecondary)
            Text("\(count) · \(pct)%")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func tint(for type: CameraShotType) -> Color {
        switch type {
        case .wide, .pov:              return Theme.teal
        case .medium:                  return Theme.violet
        case .closeUp:                 return Theme.magenta
        case .extremeCloseUp:          return Theme.accent
        case .overTheShoulder:         return Theme.lime
        case .full:                    return Theme.teal.opacity(0.7)
        case .dutchAngle:              return Theme.violet.opacity(0.7)
        case .lowAngle:                return Theme.violet.opacity(0.85)
        case .highAngle:               return Theme.violet.opacity(0.5)
        }
    }

    // MARK: Priority mix

    private func priorityMix(_ panels: [StoryboardPanel]) -> some View {
        let histogram = panels.priorityHistogram
        let total = max(1, panels.count)
        return VStack(alignment: .leading, spacing: 10) {
            Text("EDITING PRIORITY MIX")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            HStack(spacing: 24) {
                ForEach(histogram, id: \.0) { (priority, count) in
                    priorityRing(priority: priority, count: count, total: total)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func priorityRing(priority: EditingPriority, count: Int, total: Int) -> some View {
        let value = Double(count) / Double(total)
        return VStack(spacing: 8) {
            ZStack {
                CompletionRing(value: value, size: 56, color: priority.tint, showLabel: false)
                VStack(spacing: 0) {
                    Text("\(count)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(Int((value * 100).rounded()))%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            HStack(spacing: 4) {
                Image(systemName: priority.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(priority.tint)
                Text(priority.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: Murch quote

    private var murchQuote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 18))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 6) {
                Text("Emotion first. Cut on feeling before story, rhythm, or eyeline.")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.textPrimary)
                Text("— Walter Murch, In the Blink of an Eye")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Empty state

    private var emptyRhythm: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path")
                .font(.system(size: 30))
                .foregroundStyle(Theme.violet.opacity(0.6))
            Text("No rhythm to measure yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Add panels to see pacing, shot distribution, and priority mix.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(32)
    }
}
