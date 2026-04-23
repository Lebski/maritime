import SwiftUI
import Combine

// MARK: - Exports view model
//
// Bound to the single open MovieBlazeProject (one document per window means
// the "project picker" collapses into a single derived chip — no more
// hardcoded "Neon Requiem"). Export history lives on the view model for now;
// persisting jobs across launches can come later when real exporters land.

@MainActor
final class ExportsViewModel: ObservableObject {
    @Published var selectedFormats: Set<ExportFormat> = [.premiereXML, .cutCSV]
    @Published var history: [ExportJob] = []
    @Published var historyCollapsed: Bool = false

    private let project: MovieBlazeProject
    private var cancellables: Set<AnyCancellable> = []

    init(project: MovieBlazeProject) {
        self.project = project
        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: Derived state

    /// Synthesize a MovieProject summary from the open document so the existing
    /// chip + summary UI keeps working without a hardcoded sample list.
    var currentProject: MovieProject {
        let bible = project.bible
        let totalSeconds = project.scenes.reduce(0) { $0 + $1.clipDuration }
        let approved = project.scenes.filter(\.frameApproved).count
        let progress = project.scenes.isEmpty
            ? 0
            : Double(approved) / Double(project.scenes.count)
        return MovieProject(
            title: bible.projectTitle,
            genre: bible.theme.themeStatement.isEmpty ? "Untitled" : bible.theme.themeStatement,
            logline: bible.logline,
            progress: progress,
            scenes: project.scenes.count,
            characters: project.characters.count,
            durationMinutes: max(1, Int((totalSeconds / 60).rounded(.up))),
            updatedLabel: bibleUpdatedLabel(bible.lastUpdated),
            posterColors: bible.posterColors.isEmpty
                ? [Theme.violet, Theme.magenta]
                : bible.posterColors,
            status: .shooting
        )
    }

    var projects: [MovieProject] { [currentProject] }

    var selectedProject: MovieProject { currentProject }

    // MARK: Mutations

    func toggle(_ format: ExportFormat) {
        if selectedFormats.contains(format) {
            selectedFormats.remove(format)
        } else {
            selectedFormats.insert(format)
        }
    }

    func isSelected(_ format: ExportFormat) -> Bool {
        selectedFormats.contains(format)
    }

    func generate() {
        let summary = currentProject
        for format in selectedFormats {
            let job = ExportJob(format: format, projectTitle: summary.title, status: .running(progress: 0))
            history.insert(job, at: 0)
            animateJob(jobID: job.id)
        }
    }

    func deleteJob(_ job: ExportJob) {
        history.removeAll { $0.id == job.id }
    }

    private func animateJob(jobID: UUID) {
        Task {
            for i in 1...20 {
                try? await Task.sleep(nanoseconds: 70_000_000)
                if let idx = history.firstIndex(where: { $0.id == jobID }) {
                    history[idx].status = .running(progress: Double(i) / 20.0)
                }
            }
            if let idx = history.firstIndex(where: { $0.id == jobID }) {
                history[idx].status = .done(timestamp: "Just now")
            }
        }
    }

    private func bibleUpdatedLabel(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86_400 { return "\(Int(interval / 3600))h ago" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
