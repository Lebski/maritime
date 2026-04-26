import SwiftUI

struct ExportsView: View {
    @StateObject private var vm: ExportsViewModel

    init(project: MovieBlazeProject) {
        _vm = StateObject(wrappedValue: ExportsViewModel(project: project))
    }

    private let columns = [GridItem(.adaptive(minimum: 260, maximum: 340), spacing: 14)]

    var body: some View {
        HStack(spacing: 0) {
            workspace
            Divider().background(Theme.stroke)
            CollapsiblePane(
                isCollapsed: $vm.historyCollapsed,
                edge: .trailing,
                expandedWidth: 320,
                tint: AppModule.exports.tint,
                icon: "clock.arrow.circlepath",
                label: "History",
                shortcut: "]"
            ) {
                ExportHistoryList(vm: vm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }

    private var workspace: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    projectPicker
                    targetGrid
                    premiereSettingsStrip
                    summaryBar
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppModule.exports.tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: AppModule.exports.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppModule.exports.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Exports")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Deliver to Premiere, Photoshop & more")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.bgElevated)
        .overlay(Divider().background(Theme.stroke), alignment: .bottom)
    }

    private var projectPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Project", icon: "film.fill")
            ProjectChip(project: vm.currentProject, isActive: true, onTap: {})
        }
    }

    private var targetGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Export Targets", icon: "square.and.arrow.up.on.square.fill")
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(ExportFormat.allCases) { format in
                    ExportTargetCard(
                        format: format,
                        isSelected: vm.isSelected(format),
                        onToggle: { vm.toggle(format) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var premiereSettingsStrip: some View {
        if vm.selectedFormats.contains(.premiereXML) {
            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: ExportFormat.premiereXML.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ExportFormat.premiereXML.tint)
                    Text("PREMIERE PRO")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Picker("Frame rate", selection: $vm.premiereSettings.frameRate) {
                    ForEach(PremiereFrameRate.allCases) { fps in
                        Text(fps.label).tag(fps)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 120)

                Picker("Resolution", selection: $vm.premiereSettings.resolution) {
                    ForEach(PremiereResolution.allCases) { res in
                        Text(res.label).tag(res)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 180)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var summaryBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(vm.selectedFormats.count) formats selected")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("from \(vm.selectedProject.title)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button(action: { vm.generate() }) {
                Label("Generate Exports", systemImage: "wand.and.stars")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(vm.selectedFormats.isEmpty ? Theme.card : AppModule.exports.tint)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plainSolid)
            .disabled(vm.selectedFormats.isEmpty)
        }
        .padding(16)
        .background(Theme.bgElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppModule.exports.tint)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
    }
}

private struct ProjectChip: View {
    let project: MovieProject
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    LinearGradient(colors: project.posterColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(String(project.title.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(project.scenes) frames · \(project.durationMinutes)m")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(isActive ? AppModule.exports.tint.opacity(0.12) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? AppModule.exports.tint : Theme.stroke,
                            lineWidth: isActive ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }
}
