import SwiftUI
import Combine

@MainActor
final class StoryForgeViewModel: ObservableObject {
    @Published var template: StructureTemplate = .saveTheCat {
        didSet {
            if oldValue != template {
                beats = template.seedBeats
                selectedBeatID = beats.first?.id
            }
        }
    }
    @Published var beats: [Beat] = StructureTemplate.saveTheCat.seedBeats
    @Published var selectedBeatID: UUID?
    @Published var wantNeed: [WantNeedEntry] = StoryForgeSamples.wantNeed
    @Published var motifs: [Motif] = StoryForgeSamples.motifs
    @Published var themeLines: [String] = StoryForgeSamples.themeLines
    @Published var logline: String = "A cybernetic detective chases a ghost through a city that never sleeps."
    @Published var projectTitle: String = "Neon Requiem"

    @Published var leftCollapsed = false
    @Published var rightCollapsed = false

    init() {
        selectedBeatID = beats.first?.id
    }

    var selectedBeat: Beat? {
        beats.first(where: { $0.id == selectedBeatID })
    }

    func setActive(_ beat: Beat) { selectedBeatID = beat.id }

    func updateSelectedNotes(_ text: String) {
        guard let id = selectedBeatID,
              let idx = beats.firstIndex(where: { $0.id == id }) else { return }
        beats[idx].notes = text
    }

    func toggleDone(_ beat: Beat) {
        guard let idx = beats.firstIndex(where: { $0.id == beat.id }) else { return }
        beats[idx].isDone.toggle()
    }

    func addMotif(_ label: String) {
        guard !label.isEmpty else { return }
        let palette: [Color] = [Theme.teal, Theme.magenta, Theme.violet, Theme.accent, Theme.lime]
        let tint = palette[motifs.count % palette.count]
        motifs.append(Motif(label: label, tint: tint))
    }

    func removeMotif(_ motif: Motif) {
        motifs.removeAll { $0.id == motif.id }
    }

    func addThemeLine(_ line: String) {
        guard !line.isEmpty else { return }
        themeLines.append(line)
    }

    func updateWantNeed(_ entry: WantNeedEntry, want: String? = nil, need: String? = nil) {
        guard let idx = wantNeed.firstIndex(where: { $0.id == entry.id }) else { return }
        if let want { wantNeed[idx].want = want }
        if let need { wantNeed[idx].need = need }
    }

    func addWantNeed() {
        wantNeed.append(WantNeedEntry(character: "New Character", want: "", need: ""))
    }

    var completion: Double {
        guard !beats.isEmpty else { return 0 }
        return Double(beats.filter(\.isDone).count) / Double(beats.count)
    }
}
