import SwiftUI

struct CollapsiblePane<Content: View>: View {
    @Binding var isCollapsed: Bool
    let edge: HorizontalEdge
    let expandedWidth: CGFloat
    var collapsedWidth: CGFloat = 44
    let tint: Color
    let icon: String
    var label: String? = nil
    var shortcut: KeyEquivalent? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if isCollapsed {
                collapsedRail
            } else {
                content()
                    .overlay(alignment: toggleAlignment) {
                        toggleButton
                            .padding(10)
                    }
            }
        }
        .frame(width: isCollapsed ? collapsedWidth : expandedWidth)
        .animation(.easeInOut(duration: 0.22), value: isCollapsed)
    }

    private var toggleAlignment: Alignment {
        edge == .leading ? .topTrailing : .topLeading
    }

    private var chevronName: String {
        switch (edge, isCollapsed) {
        case (.leading, true):   return "chevron.right"
        case (.leading, false):  return "chevron.left"
        case (.trailing, true):  return "chevron.left"
        case (.trailing, false): return "chevron.right"
        }
    }

    private var collapsedRail: some View {
        VStack(spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { isCollapsed = false }
            } label: {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plainSolid)
            .help(label.map { "Expand \($0)" } ?? "Expand")
            .padding(.top, 14)

            if let label {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(height: 120)
                    .padding(.top, 6)
            }

            Spacer()

            toggleButton
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgElevated)
        .overlay(
            Rectangle()
                .fill(Theme.stroke)
                .frame(width: 1),
            alignment: edge == .leading ? .trailing : .leading
        )
    }

    @ViewBuilder
    private var toggleButton: some View {
        let btn = Button {
            withAnimation(.easeInOut(duration: 0.22)) { isCollapsed.toggle() }
        } label: {
            Image(systemName: chevronName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 22, height: 22)
                .background(Theme.card)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plainSolid)
        .help(isCollapsed ? "Expand" : "Collapse")

        if let shortcut {
            btn.keyboardShortcut(shortcut, modifiers: [.command, .option])
        } else {
            btn
        }
    }
}

// MARK: - Step Indicator
//
// Four-step production pipeline indicator that lives above the Storyboard
// workspace (and is reusable elsewhere). Past steps render as a lime check,
// the current step uses the module tint, future steps are muted.

struct StepIndicator: View {

    enum Step: Int, CaseIterable, Identifiable {
        case outline, storyboard, frame, render

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .outline:    return "Outline"
            case .storyboard: return "Storyboard"
            case .frame:      return "Frame"
            case .render:     return "Render"
            }
        }

        var module: AppModule {
            switch self {
            case .outline:    return .storyForge
            case .storyboard: return .storyboard
            case .frame:      return .frameBuilder
            case .render:     return .videoRenderer
            }
        }
    }

    let current: Step
    let onTap: (Step) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(Step.allCases.enumerated()), id: \.element.id) { idx, step in
                stepChip(step)
                if idx < Step.allCases.count - 1 {
                    Rectangle()
                        .fill(step.rawValue < current.rawValue ? Theme.lime.opacity(0.6) : Theme.stroke)
                        .frame(width: 18, height: 1)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.card)
        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func stepChip(_ step: Step) -> some View {
        let isCurrent = step == current
        let isPast = step.rawValue < current.rawValue
        Button(action: { onTap(step) }) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(circleFill(isCurrent: isCurrent, isPast: isPast, tint: step.module.tint))
                        .frame(width: 18, height: 18)
                    if isPast {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.black)
                    } else {
                        Text("\(step.rawValue + 1)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(isCurrent ? .black : Theme.textTertiary)
                    }
                }
                Text(step.title)
                    .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                    .foregroundStyle(isCurrent ? Theme.textPrimary : Theme.textSecondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plainSolid)
        .help(step.title)
    }

    private func circleFill(isCurrent: Bool, isPast: Bool, tint: Color) -> Color {
        if isCurrent { return tint }
        if isPast    { return Theme.lime.opacity(0.85) }
        return Color.white.opacity(0.08)
    }
}

// MARK: - Toast

struct ToastView: View {
    let toast: ToastContent
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.lime)
            Text(toast.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            if let label = toast.actionLabel, let action = toast.action {
                Button(action: {
                    action()
                    onDismiss()
                }) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.lime)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
            }
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plainSolid)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }
}
