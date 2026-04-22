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
            .buttonStyle(.plain)
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
        .buttonStyle(.plain)
        .help(isCollapsed ? "Expand" : "Collapse")

        if let shortcut {
            btn.keyboardShortcut(shortcut, modifiers: [.command, .option])
        } else {
            btn
        }
    }
}
