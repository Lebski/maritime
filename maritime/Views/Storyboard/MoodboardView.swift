import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Moodboard View
//
// Free-form canvas for the project's single moodboard. Left rail shows
// sources (set pieces / characters / colors / notes) to drop onto the
// canvas; right side is the canvas itself with grid-snap toggle.

struct MoodboardView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @StateObject private var vm: MoodboardViewModel

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: MoodboardViewModel(project: project))
    }

    var body: some View {
        HStack(spacing: 0) {
            if !vm.railCollapsed {
                rail
                    .frame(width: 240)
                    .background(Theme.bgElevated)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                Divider().background(Theme.stroke)
            }
            canvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: 0.22), value: vm.railCollapsed)
    }

    // MARK: Rail

    private var rail: some View {
        VStack(spacing: 0) {
            railHeader
            railSelector
            Divider().background(Theme.stroke)
            railBody
        }
    }

    private var railHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.violet)
            Text("SOURCES")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Button(action: { vm.railCollapsed = true }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plain)
            .help("Hide sources rail")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var railSelector: some View {
        HStack(spacing: 4) {
            ForEach(MoodboardViewModel.RailSection.allCases) { section in
                Button(action: { vm.activeRail = section }) {
                    VStack(spacing: 3) {
                        Image(systemName: section.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(section.title)
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(vm.activeRail == section ? .black : Theme.textSecondary)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(vm.activeRail == section ? Theme.violet : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var railBody: some View {
        ScrollView {
            switch vm.activeRail {
            case .setPieces: setPiecesRail
            case .characters: charactersRail
            case .colors: colorsRail
            case .notes: notesRail
            }
        }
    }

    private var setPiecesRail: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(project.setPieces) { piece in
                Button(action: { vm.addSetPieceRef(piece) }) {
                    railRow(
                        icon: piece.category.icon,
                        tint: piece.category.tint,
                        title: piece.name,
                        subtitle: piece.category.title
                    )
                }
                .buttonStyle(.plain)
            }
            if project.setPieces.isEmpty {
                emptyState("No set pieces", subtitle: "Create them in Set Design first.")
            }
        }
        .padding(10)
    }

    private var charactersRail: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(project.characters) { character in
                Button(action: { vm.addCharacterRef(character) }) {
                    railRow(
                        icon: "person.crop.artframe",
                        tint: character.finalVariation?.accentColor ?? Theme.teal,
                        title: character.name,
                        subtitle: character.role
                    )
                }
                .buttonStyle(.plain)
            }
            if project.characters.isEmpty {
                emptyState("No characters", subtitle: "Finalize characters in Character Lab.")
            }
        }
        .padding(10)
    }

    private var colorsRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROJECT PALETTE")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(project.moodboard.colorPalette.indices, id: \.self) { idx in
                    let c = project.moodboard.colorPalette[idx]
                    Button(action: { vm.addColorSwatch(c) }) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(c)
                            .frame(height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Divider().background(Theme.stroke)
            Text("QUICK COLORS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(quickColors, id: \.self) { c in
                    Button(action: { vm.addColorSwatch(c) }) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(c)
                            .frame(height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
    }

    private var quickColors: [Color] {
        [Theme.accent, Theme.magenta, Theme.teal, Theme.violet, Theme.lime, Theme.coral,
         Color.black, Color.white]
    }

    private var notesRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: { vm.addNote() }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                    Text("Add Note")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                }
                .padding(10)
                .background(Theme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            Text("Notes are editable directly on the canvas.")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(10)
    }

    // MARK: Rail helpers

    private func railRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "plus")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func emptyState(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: Canvas

    private var canvas: some View {
        VStack(spacing: 0) {
            canvasToolbar
            Divider().background(Theme.stroke)
            canvasArea
        }
    }

    private var canvasToolbar: some View {
        HStack(spacing: 12) {
            if vm.railCollapsed {
                Button(action: { vm.railCollapsed = false }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.violet)
                        .frame(width: 30, height: 30)
                        .background(Theme.violet.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Show sources rail")
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("MOODBOARD")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
                Text(project.moodboard.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Button(action: { vm.setSnap(!vm.snapOn) }) {
                HStack(spacing: 5) {
                    Image(systemName: vm.snapOn ? "square.grid.3x3.fill" : "square.grid.3x3")
                        .font(.system(size: 11, weight: .semibold))
                    Text(vm.snapOn ? "Snap · 8px" : "Snap off")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(vm.snapOn ? .black : Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(vm.snapOn ? Theme.violet : Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Toggle 8px grid snap")
            Text("\(project.moodboard.items.count) items")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var canvasArea: some View {
        GeometryReader { proxy in
            ZStack {
                Theme.bg
                if vm.snapOn {
                    GridBackdrop(step: vm.gridStep, size: proxy.size)
                        .opacity(0.12)
                }
                ForEach(vm.items) { item in
                    DraggableMoodboardItem(
                        item: item,
                        canvasSize: proxy.size,
                        project: project,
                        vm: vm
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .onTapGesture { vm.select(nil) }
        }
        .background(Theme.bg)
    }
}

// MARK: - Grid backdrop

private struct GridBackdrop: View {
    let step: Double
    let size: CGSize

    var body: some View {
        Canvas { ctx, canvasSize in
            let cols = Int(1.0 / step)
            let rows = Int(1.0 / step)
            for c in 0...cols {
                let x = Double(c) * step * canvasSize.width
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                ctx.stroke(path, with: .color(.white), lineWidth: 0.5)
            }
            for r in 0...rows {
                let y = Double(r) * step * canvasSize.height
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                ctx.stroke(path, with: .color(.white), lineWidth: 0.5)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Draggable item wrapper

private struct DraggableMoodboardItem: View {
    let item: MoodboardItem
    let canvasSize: CGSize
    let project: MovieBlazeProject
    @ObservedObject var vm: MoodboardViewModel

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        let anchor = CGPoint(
            x: CGFloat(item.xRatio) * canvasSize.width,
            y: CGFloat(item.yRatio) * canvasSize.height
        )
        MoodboardCanvasItem(
            item: item,
            project: project,
            isSelected: vm.selectedItemID == item.id,
            onTap: { vm.select(item.id) },
            onNoteEdit: { vm.updateNoteText(id: item.id, text: $0) },
            onDelete: { vm.delete(id: item.id) }
        )
        .position(
            x: anchor.x + dragOffset.width,
            y: anchor.y + dragOffset.height
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    vm.select(item.id)
                }
                .onEnded { value in
                    let newX = anchor.x + value.translation.width
                    let newY = anchor.y + value.translation.height
                    vm.move(id: item.id, to: CGPoint(x: newX, y: newY), canvas: canvasSize)
                    dragOffset = .zero
                }
        )
    }
}
