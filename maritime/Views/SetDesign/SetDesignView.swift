import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Set Design View
//
// 3-column layout: sidebar of set pieces (grouped by category), center
// canvas with large preview + reference drop zone, and a right-side prompt
// panel. Collapsible panes follow the same convention used in Character Lab
// and the Storyboard composer.

struct SetDesignView: View {
    @EnvironmentObject var project: MovieBlazeProject
    @EnvironmentObject var settings: AppSettings
    @StateObject private var vm: SetDesignViewModel

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: SetDesignViewModel(project: project))
    }

    var body: some View {
        HStack(spacing: 0) {
            CollapsiblePane(
                isCollapsed: $vm.sidebarCollapsed,
                edge: .leading,
                expandedWidth: 280,
                tint: AppModule.setDesign.tint,
                icon: AppModule.setDesign.icon,
                label: "Set Pieces",
                shortcut: "["
            ) {
                sidebar.background(Theme.bgElevated)
            }
            Divider().background(Theme.stroke)
            canvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider().background(Theme.stroke)
            CollapsiblePane(
                isCollapsed: $vm.promptPanelCollapsed,
                edge: .trailing,
                expandedWidth: 320,
                tint: AppModule.setDesign.tint,
                icon: "slider.horizontal.3",
                label: "Prompt",
                shortcut: "]"
            ) {
                promptPanel.background(Theme.bgElevated)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .sheet(isPresented: $vm.showWizard) {
            SetDesignWizardSheet(vm: vm)
                .environmentObject(project)
                .environmentObject(settings)
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            filterBar
            Divider().background(Theme.stroke)
            sidebarList
            sidebarFooter
        }
    }

    private var sidebarHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.coral.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: AppModule.setDesign.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.coral)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set Design")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(AppModule.setDesign.tagline)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Button(action: { vm.openWizard() }) {
                    Label("AI setup", systemImage: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.coral)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.coral.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Generate a set from a description")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            Divider().background(Theme.stroke)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip(nil, label: "All", icon: "square.grid.2x2")
                ForEach(SetPieceCategory.allCases) { cat in
                    filterChip(cat, label: cat.title, icon: cat.icon)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    private func filterChip(_ cat: SetPieceCategory?, label: String, icon: String) -> some View {
        let selected = vm.categoryFilter == cat
        let tint = cat?.tint ?? Theme.coral
        return Button(action: { vm.categoryFilter = cat }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(selected ? .black : Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selected ? tint : Color.white.opacity(0.04))
            .overlay(
                Capsule().stroke(selected ? Color.clear : Theme.stroke, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var sidebarList: some View {
        let pieces = vm.filteredPieces
        if pieces.isEmpty {
            sidebarEmpty
        } else {
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(SetPieceCategory.allCases) { cat in
                        let inCat = pieces.filter { $0.category == cat }
                        if !inCat.isEmpty {
                            SidebarSection(label: cat.title) {
                                ForEach(inCat) { piece in
                                    SetPieceCard(
                                        piece: piece,
                                        isActive: vm.selectedPieceID == piece.id,
                                        isGenerating: vm.isGenerating(piece.id),
                                        onTap: { vm.select(piece.id) }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(10)
            }
        }
    }

    private var sidebarEmpty: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 40)
            Image(systemName: "cube.transparent")
                .font(.system(size: 28))
                .foregroundStyle(Theme.coral.opacity(0.6))
            Text("No pieces yet")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Create your first set piece below.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.stroke)
            Button(action: { vm.createPiece() }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.coral)
                    Text("New Set Piece")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.coral)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Canvas

    @ViewBuilder
    private var canvas: some View {
        if let piece = vm.selectedPiece {
            SetPieceCanvas(vm: vm, piece: piece)
        } else {
            emptyCanvas
        }
    }

    private var emptyCanvas: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.coral.opacity(0.10))
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(Theme.coral.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: 150, height: 150)
                Image(systemName: AppModule.setDesign.icon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Theme.coral)
            }
            Text("Build Your Set Vocabulary")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Describe the set in a sentence and let Claude\npropose a starter list of pieces — or add\nthem one at a time.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button(action: { vm.openWizard() }) {
                    Label("Start with AI", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.coral)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Button(action: { vm.createPiece() }) {
                    Label("Add a blank piece", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.card)
                        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Prompt Panel

    @ViewBuilder
    private var promptPanel: some View {
        if let piece = vm.selectedPiece {
            SetPiecePromptPanel(vm: vm, piece: piece)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.textTertiary)
                Text("No piece selected")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bgElevated)
        }
    }
}

// MARK: - Canvas

private struct SetPieceCanvas: View {
    @ObservedObject var vm: SetDesignViewModel
    let piece: SetPiece

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Theme.stroke)
            preview
        }
        .background(Theme.bg)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: piece.category.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(piece.category.tint)
                    Text(piece.category.title.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(piece.category.tint)
                }
                Text(piece.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            if !piece.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(piece.tags.prefix(5), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.card)
                            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                            .clipShape(Capsule())
                    }
                }
            }
            Button(action: vm.deleteSelected) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Delete this set piece")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var preview: some View {
        let busy = vm.isGenerating(piece.id)
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: piece.primaryColors.isEmpty
                            ? [piece.category.tint.opacity(0.35), piece.category.tint.opacity(0.10)]
                            : piece.primaryColors.map { $0.opacity(0.35) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )

            if let data = piece.generatedImageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(12)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: piece.category.icon)
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundStyle(piece.category.tint)
                    Text(busy ? "Generating…" : piece.promptSeed.isEmpty ? "Add a prompt seed to generate" : "Press Generate to produce an image")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    if busy {
                        ProgressView().controlSize(.small).tint(Theme.coral)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
