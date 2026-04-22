import SwiftUI

struct ThemeMotifRail: View {
    @ObservedObject var vm: StoryForgeViewModel
    @State private var newMotif = ""
    @State private var newTheme = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                templateSelector
                themeSection
                motifsSection
            }
            .padding(14)
        }
        .background(Theme.bgElevated)
    }

    private var templateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Structure", icon: "square.stack.3d.up.fill")
            VStack(spacing: 6) {
                ForEach(StructureTemplate.allCases) { tpl in
                    Button(action: { vm.template = tpl }) {
                        HStack(spacing: 10) {
                            Image(systemName: tpl.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(vm.template == tpl ? AppModule.storyForge.tint : Theme.textTertiary)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(tpl.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(tpl.subtitle)
                                    .font(.system(size: 9))
                                    .foregroundStyle(Theme.textTertiary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if vm.template == tpl {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppModule.storyForge.tint)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(vm.template == tpl ? AppModule.storyForge.tint.opacity(0.1) : Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(vm.template == tpl ? AppModule.storyForge.tint.opacity(0.4) : Theme.stroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .cardStyle()
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Theme", icon: "sparkles")
            VStack(spacing: 6) {
                ForEach(vm.themeLines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 10))
                            .foregroundStyle(AppModule.storyForge.tint)
                        Text(line)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            HStack(spacing: 6) {
                TextField("New theme line", text: $newTheme)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onSubmit {
                        vm.addThemeLine(newTheme)
                        newTheme = ""
                    }
                Button(action: { vm.addThemeLine(newTheme); newTheme = "" }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 22, height: 22)
                        .background(AppModule.storyForge.tint)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(newTheme.isEmpty)
            }
        }
        .padding(12)
        .cardStyle()
    }

    private var motifsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Motifs", icon: "circle.hexagonpath.fill")
            FlowLayout(spacing: 6) {
                ForEach(vm.motifs) { motif in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(motif.tint)
                            .frame(width: 6, height: 6)
                        Text(motif.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Button(action: { vm.removeMotif(motif) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(motif.tint.opacity(0.15))
                    .overlay(
                        Capsule().stroke(motif.tint.opacity(0.4), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
            }
            HStack(spacing: 6) {
                TextField("Add motif", text: $newMotif)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onSubmit {
                        vm.addMotif(newMotif)
                        newMotif = ""
                    }
                Button(action: { vm.addMotif(newMotif); newMotif = "" }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 22, height: 22)
                        .background(AppModule.storyForge.tint)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(newMotif.isEmpty)
            }
        }
        .padding(12)
        .cardStyle()
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppModule.storyForge.tint)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
    }
}

// MARK: - Flow layout helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
