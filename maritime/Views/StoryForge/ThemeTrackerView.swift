import SwiftUI

struct ThemeTrackerView: View {
    @ObservedObject var vm: StoryForgeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                themeStatementCard
                motifsCard
                paletteCard
            }
            .padding(24)
        }
        .sheet(isPresented: $vm.showAddMotifSheet) {
            AddMotifSheet(vm: vm)
        }
    }

    // MARK: Theme Statement

    private var themeStatementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            StoryForgeSectionHeader(
                title: "Theme Statement",
                subtitle: "Write it as one declarative sentence. Short. Visible in the final cut.",
                tint: Theme.magenta
            )
            StyledTextField(
                placeholder: "e.g. Memory is the only thing you can lose twice.",
                text: Binding(
                    get: { vm.bible.theme.themeStatement },
                    set: { vm.updateThemeStatement($0) }
                ),
                isMultiLine: true
            )
        }
        .padding(18)
        .cardStyle()
    }

    // MARK: Motifs

    private var motifsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Visual Motifs")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Recurring imagery. The audience shouldn't notice — they should feel it.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Button(action: { vm.showAddMotifSheet = true }) {
                    Label("Add Motif", systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.magenta)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if !vm.bible.theme.motifs.isEmpty {
                FlowLayout(spacing: 8, runSpacing: 8) {
                    ForEach(vm.bible.theme.motifs) { motif in
                        MotifChip(motif: motif, onRemove: { vm.removeMotif(motif.id) })
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.magenta)
                    Text("No motifs yet. Add 3–5 recurring images that carry the theme.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(18)
        .cardStyle()
    }

    // MARK: Palette

    private var paletteCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Color Palette")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Assign colors to story roles and acts. Consistency beats novelty.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Button(action: addSuggestedSwatch) {
                    Label("Suggest", systemImage: "wand.and.sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.magenta)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.magenta.opacity(0.12))
                        .overlay(Capsule().stroke(Theme.magenta.opacity(0.35), lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if !vm.bible.theme.palette.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(vm.bible.theme.palette) { swatch in
                            PaletteSwatchView(swatch: swatch, onRemove: { vm.removePaletteSwatch(swatch.id) })
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.magenta.opacity(0.6))
                    Text("No palette yet. Suggest colors based on your structure's emotional arc.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(22)
                .background(Theme.card.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(18)
        .cardStyle()
    }

    // Adds a suggested palette swatch cycling through a curated set.
    private func addSuggestedSwatch() {
        let suggestions: [(String, Color, String)] = [
            ("#F3B249", Color(red: 0.95, green: 0.70, blue: 0.29), "Act 1"),
            ("#D94F7B", Color(red: 0.85, green: 0.31, blue: 0.48), "Protagonist"),
            ("#2F8E8A", Color(red: 0.18, green: 0.56, blue: 0.54), "Act 2"),
            ("#481656", Color(red: 0.28, green: 0.09, blue: 0.34), "Antagonist"),
            ("#EAE4CF", Color(red: 0.92, green: 0.89, blue: 0.81), "Resolution"),
            ("#0C1324", Color(red: 0.05, green: 0.07, blue: 0.14), "World")
        ]
        let count = vm.bible.theme.palette.count
        let pick = suggestions[count % suggestions.count]
        vm.addPaletteSwatch(hex: pick.0, color: pick.1, role: pick.2)
    }
}

// MARK: - Flow Layout (motif chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Add Motif Sheet

struct AddMotifSheet: View {
    @ObservedObject var vm: StoryForgeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var selectedSymbol: String = "sparkles"
    @State private var selectedTint: Color = Theme.magenta

    private let symbols: [String] = [
        "sparkles", "moon.fill", "sun.max.fill", "flame.fill", "drop.fill",
        "cloud.rain.fill", "wind", "leaf.fill", "eye.fill", "hand.raised.fill",
        "envelope.fill", "book.closed.fill", "key.fill", "lock.fill", "staroflife.fill",
        "heart.fill", "bolt.fill", "crown.fill", "bird.fill", "water.waves"
    ]

    private let tints: [(String, Color)] = [
        ("Magenta", Theme.magenta),
        ("Teal", Theme.teal),
        ("Amber", Theme.accent),
        ("Violet", Theme.violet),
        ("Lime", Theme.lime)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("LABEL").font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(Theme.textTertiary)
                        StyledTextField(placeholder: "e.g. Rain & Reflection", text: $label)
                        Text("SYMBOL").font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(Theme.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 8), spacing: 8) {
                            ForEach(symbols, id: \.self) { sym in
                                Button(action: { selectedSymbol = sym }) {
                                    Image(systemName: sym)
                                        .font(.system(size: 14))
                                        .foregroundStyle(selectedSymbol == sym ? .black : Theme.textSecondary)
                                        .frame(width: 36, height: 36)
                                        .background(selectedSymbol == sym ? selectedTint : Color.white.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text("TINT").font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(Theme.textTertiary)
                        HStack(spacing: 8) {
                            ForEach(tints, id: \.0) { tint in
                                Button(action: { selectedTint = tint.1 }) {
                                    Circle()
                                        .fill(tint.1)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: selectedTint == tint.1 ? 2 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Visual Motif")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        vm.addMotif(label: label, symbol: selectedSymbol, tint: selectedTint)
                        dismiss()
                    }
                    .foregroundStyle(label.isEmpty ? Theme.textTertiary : Theme.magenta)
                    .disabled(label.isEmpty)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 420)
    }
}
