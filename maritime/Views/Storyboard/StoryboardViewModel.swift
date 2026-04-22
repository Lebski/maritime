import SwiftUI
import Combine

@MainActor
final class StoryboardViewModel: ObservableObject {
    @Published var panels: [StoryboardPanel] = StoryboardSamples.panels
    @Published var selectedPanelID: UUID?
    @Published var libraryCollapsed = false
    @Published var projectTitle: String = "Neon Requiem"
    @Published var sequenceName: String = "Opening — Act I"

    init() {
        selectedPanelID = panels.first?.id
    }

    var selectedPanel: StoryboardPanel? {
        panels.first(where: { $0.id == selectedPanelID })
    }

    var totalDuration: Double {
        panels.reduce(0) { $0 + $1.duration }
    }

    var averagePace: Double {
        guard !panels.isEmpty else { return 0 }
        return totalDuration / Double(panels.count)
    }

    func setActive(_ panel: StoryboardPanel) {
        selectedPanelID = panel.id
    }

    func addPanel(for shot: ShotSize) {
        let next = (panels.map { $0.number }.max() ?? 0) + 1
        let panel = StoryboardPanel(
            number: next,
            shot: shot,
            title: "Shot \(next)",
            description: shot.description,
            duration: 2.5,
            gradientSeed: panels.count,
            isKey: false
        )
        panels.append(panel)
        selectedPanelID = panel.id
    }

    func removePanel(_ panel: StoryboardPanel) {
        panels.removeAll { $0.id == panel.id }
        renumber()
    }

    func movePanel(from source: IndexSet, to destination: Int) {
        panels.move(fromOffsets: source, toOffset: destination)
        renumber()
    }

    func toggleKey(_ panel: StoryboardPanel) {
        guard let idx = panels.firstIndex(where: { $0.id == panel.id }) else { return }
        panels[idx].isKey.toggle()
    }

    func updateDuration(_ panel: StoryboardPanel, seconds: Double) {
        guard let idx = panels.firstIndex(where: { $0.id == panel.id }) else { return }
        panels[idx].duration = max(0.2, seconds)
    }

    func updateTitle(_ panel: StoryboardPanel, title: String) {
        guard let idx = panels.firstIndex(where: { $0.id == panel.id }) else { return }
        panels[idx].title = title
    }

    func updateDescription(_ panel: StoryboardPanel, description: String) {
        guard let idx = panels.firstIndex(where: { $0.id == panel.id }) else { return }
        panels[idx].description = description
    }

    private func renumber() {
        for i in panels.indices { panels[i].number = i + 1 }
    }
}
